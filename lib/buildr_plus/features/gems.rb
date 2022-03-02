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

BuildrPlus::FeatureManager.feature(:gems) do |f|
  f.enhance(:Config) do
    class GemDefinition
      def initialize(name, version, options)
        @name, @version, @options = name, version, options
      end

      attr_reader :name
      attr_reader :version
      attr_reader :options

      def <=>(other)
        name <=> other.name
      end

      def to_s
        version_spec = version.nil? ? '' : ", '= #{version}'"
        options_spec = options.nil? ? '' : ", #{options.collect { |k, v| "#{k.inspect} => #{v.inspect.gsub('"',"'")}" }.join(', ')}"
        "gem '#{name}'#{version_spec}#{options_spec}"
      end
    end

    attr_writer :gemfile_needs_update

    def gemfile_needs_update?
      @gemfile_needs_update.nil? ? false : !!@gemfile_needs_update
    end

    attr_writer :manage_gemfile

    def manage_gemfile?
      @manage_gemfile.nil? ? true : !!@manage_gemfile
    end

    def gem(gems, name, version = nil, options = nil)
      gems[name.to_s] = GemDefinition.new(name, version, options)
    end

    def additional_gem(name, version = nil, options = nil)
      additional_gems[name.to_s] = GemDefinition.new(name, version, options)
    end

    def additional_gems
      @additional_gems ||= {}
    end

    def generate_gemfile_content

      gems = {}

      gem(gems, 'realityforge-buildr', nil, :path => 'vendor/tools/buildr')
      gem(gems, 'braid', '1.1.5')

      gem(gems, 'buildr_plus', nil, :path => 'vendor/tools/buildr_plus')

      if BuildrPlus::FeatureManager.activated?(:dbt)
        gem(gems, 'dbt', nil, :path => 'vendor/tools/dbt')
        gem(gems, 'maruku')
      end
      if BuildrPlus::FeatureManager.activated?(:domgen)
        gem(gems, 'domgen', nil, :path => 'vendor/tools/domgen')
      end
      if BuildrPlus::FeatureManager.activated?(:rptman)
        gem(gems, 'rptman', nil, :path => 'vendor/tools/rptman')
      end
      if BuildrPlus::FeatureManager.activated?(:redfish)
        gem(gems, 'redfish', nil, :path => 'vendor/tools/redfish')
      end
      if BuildrPlus::FeatureManager.activated?(:db) && BuildrPlus::Db.tiny_tds_defined?
        gem(gems, 'tiny_tds', '2.1.3')
      end
      if BuildrPlus::FeatureManager.activated?(:db) && BuildrPlus::Db.pg_defined?
        gem(gems, 'pg', '0.19.0')
      end
      if BuildrPlus::FeatureManager.activated?(:resgen)
        gem(gems, 'resgen', nil, :path => 'vendor/tools/resgen')
        gem(gems, 'nokogiri', '1.7.2')
      end
      if BuildrPlus::FeatureManager.activated?(:sass)
        gem(gems, 'sass', '3.4.24')
      end

      gems.merge!(additional_gems)

      header = <<CONTENT
# DO NOT EDIT: File is auto-generated
source 'https://rubygems.org'
CONTENT
      header + gems.values.sort.join("\n") + "\n"
    end

    def process_gemfile(apply_fix)
      return unless manage_gemfile?
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/Gemfile"
      lock_filename = "#{filename}.lock"
      if File.exist?(filename)
        original_content = IO.read(filename)

        content = self.generate_gemfile_content

        if content != original_content
          BuildrPlus::Gems.gemfile_needs_update = true
          if apply_fix
            puts 'Fixing: Gemfile'
            File.open(filename, 'wb') do |out|
              out.write content
            end
            FileUtils.rm_rf lock_filename
            sh "bundler install --gemfile=#{filename}"
          else
            puts 'Non-normalized Gemfile'
          end
        end

        if File.exist?(lock_filename)
          platform_output = `cd #{base_directory} && bundle platform`
          if !platform_output.include?('* ruby') || !platform_output.include?('* x86_64-darwin-18') || !platform_output.include?('* x86_64-darwin-19') || !platform_output.include?('* x86_64-darwin-20')
            BuildrPlus::Gems.gemfile_needs_update = true
            if apply_fix
              puts 'Fixing: Gemfile'
              sh "bundle lock --gemfile=#{filename} --add-platform ruby"
              # macOS Mojave 10.14
              sh "bundle lock --gemfile=#{filename} --add-platform x86_64-darwin-18"
              # macOS Catalina 10.15
              sh "bundle lock --gemfile=#{filename} --add-platform x86_64-darwin-19"
              # macOS Big Sur 11
              sh "bundle lock --gemfile=#{filename} --add-platform x86_64-darwin-20"
            else
              puts 'Non-normalized Gemfile.lock'
            end
          end
          else
            BuildrPlus::Gems.gemfile_needs_update = true
            puts 'Gemfile.lock not present'
          end
        end
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check gems match expectations.'
    task 'gems:check' do
      BuildrPlus::Gems.process_gemfile(false)
      if BuildrPlus::Gems.gemfile_needs_update?
        raise 'Gemfile has not been normalized. Please run "buildr gems:fix" and commit changes.'
      end
      buildr_script = "#{File.dirname(Buildr.application.buildfile.to_s)}/buildr"
      if !File.exist?(buildr_script) || !File.lstat('buildr').symlink?
        raise 'Symlink of buildr script not present. Please run "buildr gems:fix" and commit changes.'
      end
    end

    desc 'Normalize Gemfile.'
    task 'gems:fix' do
      BuildrPlus::Gems.process_gemfile(true)

      buildr_script = "#{File.dirname(Buildr.application.buildfile.to_s)}/buildr"
      target = "#{File.dirname(Buildr.application.buildfile.to_s)}/vendor/tools/buildr/bin/buildr"
      if !File.exist?(buildr_script) || !File.lstat('buildr').symlink?
        sh "cd #{File.dirname(Buildr.application.buildfile.to_s)} && ln -s vendor/tools/buildr/bin/buildr buildr && git add buildr"
      end
    end
  end
end
