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
BuildrPlus::FeatureManager.feature(:gitignore) do |f|
  f.enhance(:Config) do
    def additional_gitignores
      @additional_gitignores ||= []
    end

    attr_writer :gitignore_needs_update

    def gitignore_needs_update?
      @gitignore_needs_update.nil? ? false : !!@gitignore_needs_update
    end

    def process_gitignore_file(apply_fix)
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.gitignore"
      if File.exist?(filename)
        original_content = IO.read(filename)

        content = "# DO NOT EDIT: File is auto-generated\n" + gitignores.sort.uniq.collect { |v| "#{v}" }.join("\n") + "\n"

        if content != original_content
          BuildrPlus::Gitignore.gitignore_needs_update = true
          if apply_fix
            puts 'Fixing: .gitignore'
            File.open(filename, 'wb') do |out|
              out.write content
            end
          else
            puts 'Non-normalized .gitignore'
          end
        end
      end
    end

    private

    def gitignores
      gitignores = additional_gitignores.dup

      base_directory = File.expand_path(File.dirname(Buildr.application.buildfile.to_s))

      # All projects have IDEA configured
      gitignores << '*.iml'
      gitignores << '/*.ipr'
      gitignores << '/*.iws'
      gitignores << '/*.ids' if BuildrPlus::FeatureManager.activated?(:dbt)

      gitignores << '/config/database.yml' if BuildrPlus::FeatureManager.activated?(:dbt)

      gitignores << '/downloads' if BuildrPlus::FeatureManager.activated?(:role_selenium_tests)

      gitignores << '/volumes' if BuildrPlus::FeatureManager.activated?(:redfish)

      gitignores << '/config/application.yml' if BuildrPlus::FeatureManager.activated?(:dbt) ||
        BuildrPlus::FeatureManager.activated?(:rptman) ||
        BuildrPlus::FeatureManager.activated?(:jms) ||
        BuildrPlus::FeatureManager.activated?(:redfish)

      if BuildrPlus::FeatureManager.activated?(:rptman)
        gitignores << '/' + ::Buildr::Util.relative_path(File.expand_path(SSRS::Config.projects_dir), base_directory)
        gitignores << "/#{::Buildr::Util.relative_path(File.expand_path(SSRS::Config.reports_dir), base_directory)}/**/*.rdl.data"
      end

      if BuildrPlus::Artifacts.war?
        gitignores << '/artifacts'
      end

      gitignores << '/reports'
      gitignores << '/target'
      gitignores << '/tmp'

      if BuildrPlus::FeatureManager.activated?(:rails)
        gitignores << '/config/config.properties' if File.exist?("#{base_directory}/config/config.example.properties")
        gitignores << '/.rakeTasks'
        gitignores << '/.generators'
        gitignores << '/log'
        gitignores << '/vendor/jars'
      end

      if BuildrPlus::FeatureManager.activated?(:domgen) || BuildrPlus::FeatureManager.activated?(:checkstyle)
        gitignores << '**/generated'
      end

      if BuildrPlus::FeatureManager.activated?(:calendar_date_select)
        gitignores << '/public/blank_iframe.html'
        gitignores << '/public/images/calendar_date_select'
        gitignores << '/public/javascripts/calendar_date_select'
        gitignores << '/public/stylesheets/calendar_date_select'
      end

      if BuildrPlus::FeatureManager.activated?(:sass)
        gitignores << '/.sass-cache'
        Buildr.projects.each do |project|
          BuildrPlus::Sass.target_css_files(project).each do |css_file|
            css_file = ::Buildr::Util.relative_path(File.expand_path(css_file), base_directory)
            gitignores << '/' + css_file unless css_file =~ /^generated\//
          end
        end
      end

      gitignores
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check .gitignore has been normalized.'
    task 'gitignore:check' do
      BuildrPlus::Gitignore.process_gitignore_file(false)
      if BuildrPlus::Gitignore.gitignore_needs_update?
        raise '.gitignore has not been normalized. Please run "buildr gitignore:fix" and commit changes.'
      end
    end

    desc 'Normalize .gitignore.'
    task 'gitignore:fix' do
      BuildrPlus::Gitignore.process_gitignore_file(true)
    end
  end
end
