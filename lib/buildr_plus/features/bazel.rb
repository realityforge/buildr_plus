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

        content = "# DO NOT EDIT: File is auto-generated\n" + bazelignores.sort.uniq.collect {|v| "#{v}"}.join("\n") + "\n"

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
    desc 'Check bazel files are valid.'
    task 'bazel:check' => %w(bazelignore:check bazelw:check bazelversion:check bazel_standard_files:check)

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

    desc 'Normalize bazel files.'
    task 'bazel:fix' => %w(bazelignore:fix bazelw:fix bazel_version:fix)

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
  end
end

