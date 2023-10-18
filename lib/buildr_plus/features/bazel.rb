#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

BuildrPlus::FeatureManager.feature(:bazel) do |f|
  f.enhance(:Config) do
    def bazel_version
      @bazel_version ||= '6.3.2'
    end

    attr_writer :bazel_version

    attr_writer :tolerate_invalid_poms

    def tolerate_invalid_poms?
      @tolerate_invalid_poms.nil? ? false : !!@tolerate_invalid_poms
    end

    attr_writer :tolerate_missing_poms

    def tolerate_missing_poms?
      @tolerate_missing_poms.nil? ? false : !!@tolerate_missing_poms
    end

    attr_writer :tolerate_missing_poms

    def artifacts_missing_source_prefixes
      @artifacts_missing_source_prefixes ||= %w()
    end

    def local_artifact_prefixes
      @local_artifact_prefixes ||= %w(iris. au.gov.vic.dse. mercury.)
    end

    def additional_bazelignores
      @additional_bazelignores ||= []
    end

    attr_writer :bazelignore_needs_update

    def bazelignore_needs_update?
      @bazelignore_needs_update.nil? ? false : !!@bazelignore_needs_update
    end

    def process_bazelignore_file(apply_fix)
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.bazelignore"
      if File.exist?(filename)
        original_content = IO.read(filename)

        content = "# DO NOT EDIT: File is auto-generated\n" + bazelignores.sort.uniq.collect { |v| "#{v}" }.join("\n") + "\n"

        if content != original_content
          BuildrPlus::Bazel.bazelignore_needs_update = true
          if apply_fix
            puts 'Fixing: .bazelignore'
            File.open(filename, 'wb') do |out|
              out.write content
            end
          else
            puts 'Non-normalized .bazelignore'
          end
        end
      end
    end

    def generate_dependency_groups_bzl
      content = <<HEADER
# DO NOT EDIT: File is auto-generated

# This file contains the mappings from buildr projects to dependencies and is useful as a kickstarter for conversion

HEADER

      packages = Buildr.projects.collect { |project| project.packages }.flatten.collect { |p| p.to_s }
      Buildr.projects.select{|project| project.iml? && project.generate_bazel_dep_group?}.each do |project|
        prefix = Reality::Naming.uppercase_constantize(project.name.gsub(/^#{project.root_project.name}:/, '')).gsub(':', '_')
        compile_deps = []
        project.compile.dependencies.each do |dep|
          if dep.respond_to?(:to_spec_hash) && !packages.include?(dep.to_s)
            compile_deps << "//third_party/java:#{dep.to_spec_hash[:id].gsub(':', '_').gsub('.', '_').gsub('-', '_')}"
          end
        end
        unless compile_deps.empty?
          content += <<CONTENT
#{prefix}_COMPILE_DEPS = [
    #{compile_deps.collect{|s|"\"#{s}\","}.sort.join("\n    ")}
]
CONTENT
        end
        test_deps = []
        project.test.compile.dependencies.each do |dep|
          if dep.respond_to?(:to_spec_hash) && !packages.include?(dep.to_s)
            test_deps << "//third_party/java:#{dep.to_spec_hash[:id].gsub(':', '_').gsub('.', '_').gsub('-', '_')}"
          end
        end
        unless test_deps.empty?
          content += <<CONTENT
#{prefix}_TEST_DEPS = [
    #{test_deps.collect{|s|"\"#{s}\","}.sort.join("\n    ")}
]
CONTENT
        end
      end
      content
    end

    def generate_dependencies_yml

      artifacts_map = {}
      packages = Buildr.projects.collect { |project| project.packages }.flatten.collect { |p| p.to_s }
      Buildr.projects.each do |project|
        (project.compile.dependencies + project.test.compile.dependencies).each do |dep|
          if dep.respond_to?(:to_spec_hash) && !packages.include?(dep.to_s)
            hash = dep.to_spec_hash
            spec = "#{hash[:group]}:#{hash[:id]}:#{hash[:version]}"
            (artifacts_map[spec] ||= []) << project.name
          end
        end
      end

      repositories = Buildr.repositories.remote.select { |r| r != 'https://repo.maven.apache.org/maven2' }
      if repositories.size > 1
        raise "Bazel plugin does not currently support multiple local repositories. Current local repositories: #{repositories}"
      end

      content = <<HEADER
# DO NOT EDIT: File is auto-generated

repositories:
  - name: central
    url: https://repo.maven.apache.org/maven2
HEADER
      if repositories.size > 0
        repo = URI(repositories[0])
        repo.userinfo = ''
        content += <<HEADER
  - name: local
    url: #{repo}
    searchByDefault: false
HEADER
      end
      content += <<HEADER
options:
  workspaceDirectory: ../..
  aliasStrategy: ArtifactId
HEADER

      if BuildrPlus::Bazel.tolerate_missing_poms?
        content += <<HEADER
  failOnMissingPom: false
HEADER
      end
      if BuildrPlus::Bazel.tolerate_invalid_poms?
        content += <<HEADER
  failOnInvalidPom: false
HEADER
      end

      content += <<HEADER

artifacts:
HEADER

      artifacts_map.keys.sort.each do |spec|
        content += "  - coord: #{spec}\n"
        # Artifacts that we know have no source, either because the origin
        if BuildrPlus::Bazel.artifacts_missing_source_prefixes.any? { |prefix| spec.start_with?(prefix) }
          content += "    includeSource: false\n"
        end
        content += "    excludes:\n"
        content += "      - '*:*'\n"
        if BuildrPlus::Bazel.local_artifact_prefixes.any? { |prefix| spec.start_with?(prefix) }
          content += "    repositories:\n"
          content += "      - local\n"
        end
      end
      content
    end

    private

    def bazelignores
      bazelignores = additional_bazelignores.dup

      base_directory = File.expand_path(File.dirname(Buildr.application.buildfile.to_s))

      # All projects have IDEA configured
      bazelignores << '*.iml'
      bazelignores << '/*.ipr'
      bazelignores << '/*.iws'
      bazelignores << '/.shelf'
      if BuildrPlus::FeatureManager.activated?(:dbt)
        bazelignores << '/*.ids'
        bazelignores << '/.ideaDataSources'
        bazelignores << '/dataSources'
      end

      if BuildrPlus::FeatureManager.activated?(:node)
        bazelignores << '/node_modules'
      end

      bazelignores << '/config/secrets' if BuildrPlus::FeatureManager.activated?(:keycloak)

      bazelignores << '/config/database.yml' if BuildrPlus::FeatureManager.activated?(:dbt)

      bazelignores << '/volumes' if BuildrPlus::FeatureManager.activated?(:redfish)

      bazelignores << '/config/application.yml' if BuildrPlus::FeatureManager.activated?(:dbt) ||
        BuildrPlus::FeatureManager.activated?(:rptman) ||
        BuildrPlus::FeatureManager.activated?(:jms) ||
        BuildrPlus::FeatureManager.activated?(:redfish)

      if BuildrPlus::FeatureManager.activated?(:rptman)
        bazelignores << '/' + ::Buildr::Util.relative_path(File.expand_path(SSRS::Config.projects_dir), base_directory)
        bazelignores << "/#{::Buildr::Util.relative_path(File.expand_path(SSRS::Config.reports_dir), base_directory)}/**/*.rdl.data"
      end

      if BuildrPlus::Artifacts.war?
        bazelignores << '/artifacts'
      end

      bazelignores << '/reports'
      bazelignores << '/target'
      bazelignores << '/tmp'

      if BuildrPlus::FeatureManager.activated?(:domgen) || BuildrPlus::FeatureManager.activated?(:checkstyle) || BuildrPlus::FeatureManager.activated?(:config)
        bazelignores << '**/generated'
      end

      if BuildrPlus::FeatureManager.activated?(:sass)
        bazelignores << '/.sass-cache'
        Buildr.projects.each do |project|
          BuildrPlus::Sass.target_css_files(project).each do |css_file|
            css_file = ::Buildr::Util.relative_path(File.expand_path(css_file), base_directory)
            bazelignores << '/' + css_file unless css_file =~ /^generated\//
          end
        end
      end

      bazelignores
    end
  end

  f.enhance(:ProjectExtension) do

    attr_writer :generate_bazel_dep_group

    def generate_bazel_dep_group?
      @generate_bazel_dep_group.nil? ? true : !!@generate_bazel_dep_group
    end

    desc 'Check bazel files are valid.'
    task 'bazel:check' => %w(bazelignore:check bazelw:check bazelversion:check bazel_standard_files:check bazel_dependencies:check bazel_groups:check)

    desc 'Check .bazelignore has been normalized.'
    task 'bazelignore:check' do
      BuildrPlus::Bazel.process_bazelignore_file(false)
      if BuildrPlus::Bazel.bazelignore_needs_update?
        raise '.bazelignore has not been normalized. Please run "buildr bazelignore:fix" and commit changes.'
      end
    end

    desc 'Check bazelw has been normalized'
    task 'bazelw:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/bazelw"

      raise "Bazelw file '#{filename}' missing. Please run 'bazel bazelw:fix'." unless File.exist?(filename)
      actual_content = IO.read(filename)
      expected_content = IO.read("#{File.dirname(__FILE__)}/bazelw")
      if actual_content != expected_content || !File.executable?(filename)
        raise "Bazelw is not uptodate. Please run 'bazel bazelw:fix'."
      end
    end

    desc 'Check .bazelversion has been normalized'
    task 'bazelversion:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.bazelversion"

      raise ".bazelversion file '#{filename}' missing. Please run 'bazel bazelversion:fix'." unless File.exist?(filename)
      actual_content = IO.read(filename)
      if "#{BuildrPlus::Bazel.bazel_version}\n" != actual_content
        raise ".bazelversion is not uptodate. Please run 'bazel bazelversion:fix'."
      end
    end

    desc 'Check presence of standard bazel files'
    task 'bazel_standard_files:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      %W(#{base_directory}/.bazelrc #{base_directory}/WORKSPACE.bazel #{base_directory}/BUILD.bazel).each do |filename|
        raise "Bazel file '#{filename}' missing. Please fix." unless File.exist?(filename)
      end
    end

    desc 'Check dependencies.yml is up to date'
    task 'bazel_dependencies:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/third_party/java/dependencies.yml"

      content = BuildrPlus::Bazel.generate_dependencies_yml
      actual_content = File.exist?(filename) ? IO.read(filename) : ''
      if content != actual_content
        temp = Tempfile.new('dependencies.yml')
        temp_filename = temp.path
        temp.write(content)
        temp.close
        sh "diff #{filename} #{temp_filename}"
        raise "Bazel's dependencies.yml is not uptodate. Please run 'buildr bazel_dependencies:fix'."
      end
    end

    desc 'Check dependencies.yml is up to date'
    task 'bazel_groups:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/third_party/java/dep_groups.bzl"

      content = BuildrPlus::Bazel.generate_dependency_groups_bzl
      actual_content = File.exist?(filename) ? IO.read(filename) : ''
      if content != actual_content
        raise "Bazel's dep_groups.bzl is not uptodate. Please run 'bazel bazel_groups:fix'."
      end
    end

    desc 'Normalize bazel files.'
    task 'bazel:fix' => %w(bazelignore:fix bazelw:fix bazel_version:fix bazel_dependencies:fix bazel_groups:fix)

    desc 'Normalize .bazelignore.'
    task 'bazelignore:fix' do
      BuildrPlus::Bazel.process_bazelignore_file(true)
    end

    desc 'Normalize bazelw'
    task 'bazelw:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/bazelw"

      content = IO.read("#{File.dirname(__FILE__)}/bazelw")
      IO.write(filename, content)
      File.chmod(0755, filename)
    end

    desc 'Normalize .bazelversion'
    task 'bazel_version:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.bazelversion"

      IO.write(filename, "#{BuildrPlus::Bazel.bazel_version}\n")
    end

    desc 'Normalize dependencies.yml'
    task 'bazel_dependencies:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/third_party/java/dependencies.yml"

      content = BuildrPlus::Bazel.generate_dependencies_yml

      actual_content = File.exist?(filename) ? IO.read(filename) : ''
      if content != actual_content
        IO.write(filename, content)
        puts 'Regenerated dependencies.yml'
        bazel_depgen = ::Buildr.artifact(BuildrPlus::Libs.bazel_depgen)
        bazel_depgen.invoke

        args = []
        args << Java::Commands.path_to_bin('java')
        args << '-jar'
        args << bazel_depgen.to_s
        args << '--config-file'
        args << filename
        args << '--verbose'
        args << 'generate'

        begin
          sh args.join(' ')
        rescue Exception => e
          # Append to the end to ensure it get's rewritten next time
          IO.write(filename, content + "\n# File failed to be processed")
          raise e
        end
      end
    end

    desc 'Normalize dependencies.yml'
    task 'bazel_groups:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/third_party/java/dep_groups.bzl"
      content = BuildrPlus::Bazel.generate_dependency_groups_bzl

      actual_content = File.exist?(filename) ? IO.read(filename) : ''
      if content != actual_content
        IO.write(filename, content)
      end
    end
  end
end

