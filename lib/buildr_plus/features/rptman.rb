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

BuildrPlus::FeatureManager.feature(:rptman => [:db]) do |f|
  f.enhance(:ProjectExtension) do
    first_time do
      require 'rptman'

      ::SSRS::Build.define_basic_tasks

      base_directory = File.dirname(Buildr.application.buildfile.to_s)

      if ::File.exist?(File.expand_path("#{base_directory}/config/ci-report-database.yml"))
        desc 'Uploads reports to production environment'
        task 'rptman:upload_to_production_environment' do

          old_environment = SSRS::Config.environment
          old_filename = SSRS::Config.config_filename
          begin
            SSRS::Config.config_data = nil
            SSRS::Config.environment = 'production'
            SSRS::Config.config_filename = 'config/ci-report-database.yml'
            task('rptman:ssrs:upload_reports').invoke
          ensure
            SSRS::Config.config_data = nil
            SSRS::Config.environment = old_environment
            SSRS::Config.config_filename = old_filename
          end
        end
      end
    end

    after_define do |project|
      if project.ipr?
        if BuildrPlus::FeatureManager.activated?(:dbt)
          Dbt.database_keys.each do |database_key|
            database = Dbt.database_for_key(database_key)
            next unless database.enable_rake_integration? || database.packaged?
            next if BuildrPlus::Dbt.manual_testing_only_database?(database_key)

            if Dbt::Config.default_database?(database_key)
              ::SSRS::Config.define_datasource(Reality::Naming.uppercase_constantize(project.name.to_s))
            else
              ::SSRS::Config.define_datasource(Reality::Naming.uppercase_constantize(database_key.to_s), database_key.to_s)
            end
          end
        end
      end
    end
  end
end
