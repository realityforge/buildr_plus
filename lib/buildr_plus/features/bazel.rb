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

module Buildr #:nodoc:
  module ActsAsArtifact
    def pom
      return self if type == :pom
      return nil if BuildrPlus::Bazel.artifacts_missing_pom_prefixes.any? { |prefix| group.start_with?(prefix) }
      Buildr.artifact(:group => group, :id => id, :version => version, :type => :pom)
    end
  end
end

BuildrPlus::FeatureManager.feature(:bazel) do |f|
  f.enhance(:Config) do
    def bazel_depgen
      'org.realityforge.bazel.depgen:bazel-depgen:jar:all:0.19'
    end

    attr_writer :tolerate_invalid_poms

    def tolerate_invalid_poms?
      @tolerate_invalid_poms.nil? ? false : !!@tolerate_invalid_poms
    end

    attr_writer :startup_options

    def startup_options
      @startup_options ||= ''
    end

    attr_writer :command_options

    def command_options
      @command_options ||= ''
    end

    attr_writer :tolerate_missing_poms

    def tolerate_missing_poms?
      @tolerate_missing_poms.nil? ? false : !!@tolerate_missing_poms
    end

    attr_writer :tolerate_missing_poms

    def artifacts_missing_pom_prefixes
      @artifacts_missing_pom_prefixes ||= %w()
    end

    def artifacts_missing_source_prefixes
      @artifacts_missing_source_prefixes ||= %w()
    end

    def additional_artifacts
      @additional_artifacts ||= []
    end

    def local_artifact_prefixes
      @local_artifact_prefixes ||= %w(iris. au.gov.vic.dse. mercury.)
    end

    def generate_dependencies_yml
      artifacts_map = {}
      packages = Buildr.projects.collect { |project| project.packages }.flatten.collect { |p| p.to_s }
      Buildr.projects.each do |project|
        (project.compile.dependencies +
          BuildrPlus::Bazel.additional_artifacts +
          project.test.compile.dependencies +
          (project.compile.options[:processor_path] || []) +
          (project.test.compile.options[:processor_path] || [])).
          flatten.
          each do |dep|
          dep = ::Buildr.artifact(dep) if dep.is_a?(String)
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
  nameStrategy: ArtifactId
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
  end

  f.enhance(:ProjectExtension) do

    desc 'Check bazel files are valid.'
    task 'bazel:check' => %w(bazel_dependencies:check buildifier:check)

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

    desc 'Run buildifier across build files'
    task 'buildifier:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      sh "cd #{base_directory} && ./bazelw #{BuildrPlus::Bazel.startup_options} run #{BuildrPlus::Bazel.command_options} //:buildifier_check"
    end

    desc 'Normalize bazel files.'
    task 'bazel:fix' => %w(bazel_dependencies:fix buildifier:fix)

    desc 'Normalize dependencies.yml'
    task 'bazel_dependencies:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/third_party/java/dependencies.yml"

      content = BuildrPlus::Bazel.generate_dependencies_yml

      actual_content = File.exist?(filename) ? IO.read(filename) : ''
      if content != actual_content
        IO.write(filename, content)
        puts 'Regenerated dependencies.yml'
        bazel_depgen = ::Buildr.artifact(BuildrPlus::Bazel.bazel_depgen)
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

    desc 'Run buildifier across build files'
    task 'buildifier:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      sh "cd #{base_directory} && ./bazelw #{BuildrPlus::Bazel.startup_options} run #{BuildrPlus::Bazel.command_options} //:buildifier"
    end
  end
end
