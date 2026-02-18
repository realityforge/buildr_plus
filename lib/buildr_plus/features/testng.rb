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

BuildrPlus::FeatureManager.feature(:testng) do |f|
  f.enhance(:ProjectExtension) do
    after_define do |project|
      if project.ipr?
        project.task(':generate:all' => ['config:emit_test_properties']) if BuildrPlus::FeatureManager.activated?(:generate)

        desc 'Generate properties files used in the testing process'
        project.task(':config:emit_test_properties') do

          filename = project._('generated/buildr_plus/config/testng.properties')
          if BuildrPlus::FeatureManager.activated?(:dbt)
            BuildrPlus::Config.load_application_config! if BuildrPlus::FeatureManager.activated?(:config)
            Dbt.repository.load_configuration_data

            FileUtils.mkdir_p File.dirname(filename)

            trace("Generating testng properties in #{filename}")
            File.open(filename, 'wb') do |file|
              file.write "# DO NOT EDIT: File is auto-generated\n"

              Dbt.database_keys.each do |database_key|
                database = Dbt.configuration_for_key(database_key, :test)
                jdbc_url = database.build_jdbc_url(:credentials_inline => true)

                prefix = database_key
                if Dbt::Config.default_database?(database_key)
                  file.write "test.db.url=#{jdbc_url}\n"
                  file.write "test.db.name=#{database.catalog_name}\n"
                  prefix = project.root_project.name.to_s
                end

                file.write "#{prefix}.test.db.url=#{jdbc_url}\n"
                file.write "#{prefix}.test.db.name=#{database.catalog_name}\n"
              end
            end
          end
        end
      end
    end
  end
end
