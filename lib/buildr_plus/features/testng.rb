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
  f.enhance(:Config) do
    def default_testng_args(project = nil, project_descriptor = nil)
      default_testng_args = []
      default_testng_args << '-ea'
      default_testng_args << '-Xmx2024M'

      if BuildrPlus::FeatureManager.activated?(:db) && project_descriptor && project_descriptor.in_any_role?([:library, :server, :sync_model, :model, :model_qa])
        if BuildrPlus::FeatureManager.activated?(:dbt)
          default_testng_args << "-Dtest.db.property_file=#{project.root_project._('generated/buildr_plus/config/testng.properties')}"
        end
      end

      if BuildrPlus::FeatureManager.activated?(:keycloak) && project_descriptor && project_descriptor.in_any_role?([:server])
        environment = BuildrPlus::Config.application_config.environment_by_key(:test)
        default_testng_args << "-Dkeycloak.server-url=#{environment.keycloak.base_url}"
        default_testng_args << "-Dkeycloak.public-key=#{environment.keycloak.public_key}"
        default_testng_args << "-Dkeycloak.realm=#{environment.keycloak.realm}"
        default_testng_args << "-Dkeycloak.service_username=#{environment.keycloak.service_username}"
        default_testng_args << "-Dkeycloak.service_password=#{environment.keycloak.service_password}"
      end

      if BuildrPlus::FeatureManager.activated?(:gwt) && project_descriptor && project_descriptor.in_any_role?([:gwt, :gwt_qa, :user_experience])
        BuildrPlus::Gwt.gwt_test_options.each_pair do |k, v|
          default_testng_args << "-D#{k}=#{v}"
          end
      end

      if BuildrPlus::FeatureManager.activated?(:arez) && project_descriptor && project_descriptor.in_any_role?([:gwt, :gwt_qa, :user_experience])
        BuildrPlus::Arez.arez_test_options.each_pair do |k, v|
          default_testng_args << "-D#{k}=#{v}"
        end
        if BuildrPlus::FeatureManager.activated?(:replicant)
          BuildrPlus::Replicant.replicant_test_options.each_pair do |k, v|
            default_testng_args << "-D#{k}=#{v}"
          end
        end
      end

      default_testng_args
    end
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|

      if project.ipr?
        project.task(':generate:all' => ['config:emit_test_properties']) if BuildrPlus::FeatureManager.activated?(:generate)

        desc 'Generate properties files used in the testing process'
        project.task(':config:emit_test_properties') do

          filename = project._('generated/buildr_plus/config/testng.properties')

          if BuildrPlus::FeatureManager.activated?(:db)
            if BuildrPlus::FeatureManager.activated?(:dbt)
              BuildrPlus::Config.load_application_config! if BuildrPlus::FeatureManager.activated?(:config)
              Dbt.repository.load_configuration_data

              trace("Generating testng properties in #{filename}")
              File.open(filename, 'wb') do |file|
                file.write "# DO NOT EDIT: File is auto-generated\n"

                Dbt.database_keys.each do |database_key|
                  next if BuildrPlus::Dbt.manual_testing_only_database?(database_key)

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

    attr_writer :idea_testng_configuration_created

    def idea_testng_configuration_created?
      @idea_testng_configuration_created.nil? ? false : !!@idea_testng_configuration_created
    end

    Buildr.settings.build['testng'] = BuildrPlus::Libs.testng_version
    before_define do |project|
      project.test.using :testng
      project.test.compile.dependencies.clear
      project.test.with BuildrPlus::Libs.testng
    end
  end
end
