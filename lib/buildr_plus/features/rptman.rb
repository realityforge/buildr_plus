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

begin
  require 'rptman'
rescue LoadError
  # Ignored
end

if Object.const_defined?('SSRS')
  module BuildrPlus
    module RptmanExtension
      module ProjectExtension
        include Extension
        BuildrPlus::ExtensionRegistry.register(self)

        first_time do
          SSRS::Build.define_basic_tasks
        end

        after_define do |project|
          if project.ipr?
            if Object.const_defined?('Dbt')
              Dbt.database_keys.each do |database_key|
                database = Dbt.database_for_key(database_key)
                next unless database.enable_rake_integration? || database.packaged?
                next if BuildrPlus::DbtConfig.manual_testing_only_database?(database_key)

                if Dbt::Config.default_database?(database_key)
                  SSRS::Config.define_datasource(Domgen::Naming.uppercase_constantize(project.name.to_s))
                else
                  SSRS::Config.define_datasource(Domgen::Naming.uppercase_constantize(database_key.to_s),
                                                 database_key.to_s)
                end
              end
            end
          end
        end
      end
    end
  end
end
