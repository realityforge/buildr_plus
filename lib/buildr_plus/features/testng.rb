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

      if BuildrPlus::Roles.project_with_role?(:integration_tests) && project_descriptor && project_descriptor.in_any_role?([:integration_tests])
        server_project = project.project(BuildrPlus::Roles.project_with_role(:server).name)
        war_package = server_project.package(:war)
        war_dir = File.dirname(war_package.to_s)

        default_testng_args << "-Dembedded.glassfish.artifacts=#{BuildrPlus::Guiceyloops.glassfish_spec_list}"
        default_testng_args << "-Dwar.dir=#{war_dir}"
        BuildrPlus::Integration.additional_applications_to_deploy.each do |key, artifact|
          default_testng_args << "-D#{key}.war.filename=#{Buildr.artifact(artifact).to_s}"
        end
        default_testng_args.concat(BuildrPlus::Glassfish.addtional_default_testng_args)
      end

      if BuildrPlus::FeatureManager.activated?(:db) && project_descriptor && project_descriptor.in_any_role?([:server, :sync_model, :model, :model_qa, :integration_tests])
        default_testng_args << "-javaagent:#{Buildr.artifact(BuildrPlus::Libs.eclipselink).to_s}" unless project_descriptor.in_any_role?([:integration_tests])

        if BuildrPlus::FeatureManager.activated?(:dbt)
          BuildrPlus::Config.load_application_config! if BuildrPlus::FeatureManager.activated?(:config)
          Dbt.repository.load_configuration_data

          Dbt.database_keys.each do |database_key|
            next if BuildrPlus::Dbt.manual_testing_only_database?(database_key)

            prefix = Dbt::Config.default_database?(database_key) ? '' : "#{database_key}."
            database = Dbt.configuration_for_key(database_key, :test)
            default_testng_args << "-D#{prefix}test.db.url=#{database.build_jdbc_url(:credentials_inline => true)}"
            default_testng_args << "-D#{prefix}test.db.name=#{database.catalog_name}"
          end
        end
      end

      if BuildrPlus::FeatureManager.activated?(:keycloak) && project_descriptor && project_descriptor.in_any_role?([:server, :integration_tests])
        environment = BuildrPlus::Config.application_config.environment_by_key(:test)
        default_testng_args << "-Dkeycloak.server-url=#{environment.keycloak.base_url}"
        default_testng_args << "-Dkeycloak.public-key=#{environment.keycloak.public_key}"
        default_testng_args << "-Dkeycloak.realm=#{environment.keycloak.realm}"
        default_testng_args << "-Dkeycloak.service_username=#{environment.keycloak.service_username}"
        default_testng_args << "-Dkeycloak.service_password=#{environment.keycloak.service_password}"
        BuildrPlus::Keycloak.clients.each do |client|
          default_testng_args << "-D#{client.client_type}.keycloak.client=#{client.auth_client.name('test')}"
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
    Buildr.settings.build['testng'] = BuildrPlus::Libs.testng_version
    before_define do |project|
      project.test.using :testng
      project.test.compile.dependencies.clear
      project.test.with BuildrPlus::Libs.testng
    end
  end
end
