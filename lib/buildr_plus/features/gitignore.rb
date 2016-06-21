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
    attr_writer :gitignore_needs_update

    def gitignore_needs_update?
      @gitignore_needs_update.nil? ? false : !!@gitignore_needs_update
    end

    def global_ignores
      %w(*~ .DS_Store .DS_Store? ._* .Spotlight-V100 .Trashes ehthumbs.db Thumbs.db)
    end

    def invalid_ignores
      invalid = [
        '/_reports',
        '/config/local.sh', # No longer needed post redfish
        '/Gemfile.lock', 'Gemfile.lock', # We require lock files due to periodic instability of rubygems
        '/.idea', '.idea/', '.idea', # IDEA in directory format
        '/attlassian-ide-plugin.xml', # Old IDEA plugin config
        '/.project', '/.classpath', # Eclipse project files
        /^.*\.rdl\.data$/, # Report ignores will be re-added
        /^.*\.bat$/, # No windows development so remove ignores for local bat scripts
        /^#.*$/, # Remove Comments as they will be less relevant when file is resorted
        /^\n/ # Remove blank lines
      ]

      unless BuildrPlus::FeatureManager.activated?(:dbt)
        invalid << '/*.ids'
      end

      unless BuildrPlus::FeatureManager.activated?(:rails)
        invalid << '/.generators'
        invalid << '.generators'
      end

      invalid
    end

    def normalizing_transforms
      {
        /^(.*[\/])?generated[\/]?$/ => '**/generated',
        /^(.*[\/])?generated[\/].*$/ => '**/generated',
        /^\/?tmp([\/].*)?$/ => '/tmp',
        /^.*\*.iml/ => '*.iml',
        /^.*\*.ipr/ => '/*.ipr',
        /^.*\*.iws/ => '/*.iws',
        /^.*\*.ids/ => '/*.ids'
      }
    end

    def gitignores
      gitignores = []

      base_directory = File.expand_path(File.dirname(Buildr.application.buildfile.to_s))

      # All projects have IDEA configured
      gitignores << '*.iml'
      gitignores << '/*.ipr'
      gitignores << '/*.iws'
      gitignores << '/*.ids' if BuildrPlus::FeatureManager.activated?(:dbt)

      gitignores << '/config/database.yml' if BuildrPlus::FeatureManager.activated?(:dbt)

      gitignores << '/volumes' if BuildrPlus::FeatureManager.activated?(:redfish)

      gitignores << '/config/application.yml' if BuildrPlus::FeatureManager.activated?(:dbt) ||
        BuildrPlus::FeatureManager.activated?(:rptman) ||
        BuildrPlus::FeatureManager.activated?(:jms) ||
        BuildrPlus::FeatureManager.activated?(:redfish)

      if BuildrPlus::FeatureManager.activated?(:rptman)
        gitignores << '/' + ::Buildr::Util.relative_path(File.expand_path(SSRS::Config.projects_dir), base_directory)
        gitignores << "/#{::Buildr::Util.relative_path(File.expand_path(SSRS::Config.reports_dir), base_directory)}/**/*.rdl.data"
      end

      if BuildrPlus::FeatureManager.activated?(:redfish)
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

    def process_gitignore_file(apply_fix)
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.gitignore"
      if File.exist?(filename)
        content = IO.read(filename)

        original_content = content.dup

        # Remove ignores that should not be present
        (self.global_ignores + self.invalid_ignores).each do |v|
          content = content.gsub(v, '')
        end

        # Transform known bad patterns to good patterns
        self.normalizing_transforms.each_pair do |pattern, replacement|
          content = content.gsub(pattern, replacement)
        end

        # Ignores known to be required
        content += "\n" + self.gitignores.collect { |v| "#{v}" }.join("\n")

        # Normalize new lines, order libs and strip duplicates
        content = content.split("\n").collect { |f| f.strip }.select { |f| f.size > 0 }.sort.uniq.join("\n") + "\n"

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
