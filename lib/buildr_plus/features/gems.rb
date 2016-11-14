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
    attr_writer :gemfile_needs_update

    def gemfile_needs_update?
      @gemfile_needs_update.nil? ? false : !!@gemfile_needs_update
    end

    attr_writer :manage_gemfile

    def manage_gemfile?
      @manage_gemfile.nil? ? !BuildrPlus::FeatureManager.activated?(:rails) : !!@manage_gemfile
    end

    def generate_gemfile_content
      content = <<CONTENT
# DO NOT EDIT: File is auto-generated
source 'https://rubygems.org'

gem 'buildr', '= 1.5.0'
gem 'braid', '= 1.0.3'

# Rspec required for buildr
gem 'rspec-expectations',   '= 2.14.3'
gem 'rspec-mocks',          '= 2.14.3'
gem 'rspec-core',           '= 2.14.5'
gem 'rspec',                '= 2.14.1'

gem 'buildr_plus', '= 1.0.0', :path => 'vendor/tools/buildr_plus'
CONTENT
      if BuildrPlus::FeatureManager.activated?(:dbt)
        content += "gem 'dbt', '= 0.10.0.dev', :path => 'vendor/tools/dbt'\n"
        content += "gem 'maruku'\n"
      end
      if BuildrPlus::FeatureManager.activated?(:domgen)
        content += "gem 'domgen', '= 0.19.0.dev', :path => 'vendor/tools/domgen'\n"
      end
      if BuildrPlus::FeatureManager.activated?(:rptman)
        content += "gem 'rptman', '= 0.5', :path => 'vendor/tools/rptman'\n"
      end
      if BuildrPlus::FeatureManager.activated?(:redfish)
        content += "gem 'redfish', '= 0.2.2.dev', :path => 'vendor/tools/redfish'\n"
      end
      if BuildrPlus::FeatureManager.activated?(:db) && BuildrPlus::Db.tiny_tds_defined?
        content += "gem 'tiny_tds', '= 1.0.5'\n"
      end
      if BuildrPlus::FeatureManager.activated?(:db) && BuildrPlus::Db.pg_defined?
        content += "gem 'pg', '= 0.15.1'\n"
      end

      content
    end

    def process_gemfile(apply_fix)
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/Gemfile"
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
            FileUtils.rm_rf "#{filename}.lock"
            puts "bundler install --gemfile=#{filename}"
            sh "bundler install --gemfile=#{filename}"
          else
            puts 'Non-normalized Gemfile'
          end
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
    end

    desc 'Normalize Gemfile.'
    task 'gems:fix' do
      BuildrPlus::Gems.process_gemfile(true)
    end
  end
end
