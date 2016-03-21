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

BuildrPlus::Roles.role(:container) do

  project.publish = false

  default_testng_args = []
  default_testng_args << '-ea'
  default_testng_args << '-Xmx2024M'
  default_testng_args << '-XX:MaxPermSize=364M'

  if BuildrPlus::Roles.project_with_role?(:integration_tests)
    server_project = project(BuildrPlus::Roles.project_with_role(:server).name)
    war_package = server_project.package(:war)
    war_dir = File.dirname(war_package.to_s)

    default_testng_args << "-Dembedded.glassfish.artifacts=#{BuildrPlus::Guiceyloops.glassfish_spec_list}"
    default_testng_args << "-Dwar.dir=#{war_dir}"
  end

  if BuildrPlus::FeatureManager.activated?(:db)
    default_testng_args << "-javaagent:#{BuildrPlus::Libs.eclipselink.to_s}"

    if BuildrPlus::FeatureManager.activated?(:dbt)
      old_environment = Dbt::Config.environment
      begin
        Dbt.repository.load_configuration_data

        Dbt.database_keys.each do |database_key|
          database = Dbt.database_for_key(database_key)
          next unless database.enable_rake_integration? || database.packaged? || !database.managed?
          next if BuildrPlus::Dbt.manual_testing_only_database?(database_key)

          prefix = Dbt::Config.default_database?(database_key) ? '' : "#{database_key}."
          jdbc_url = Dbt.configuration_for_key(database_key).build_jdbc_url(:credentials_inline => true)
          catalog_name = Dbt.configuration_for_key(database_key).catalog_name
          default_testng_args << "-D#{prefix}test.db.url=#{jdbc_url}"
          default_testng_args << "-D#{prefix}test.db.name=#{catalog_name}"
        end
      ensure
        Dbt::Config.environment = old_environment
      end
    end
  end

  ipr.add_default_testng_configuration(:jvm_args => default_testng_args.join(' '))

  # Need to use definitions as projects have yet to be when resolving
  # container project which is typically the root project
  if BuildrPlus::Roles.project_with_role?(:server)
    server_project = project(BuildrPlus::Roles.project_with_role(:server).name)
    model_project =
      BuildrPlus::Roles.project_with_role?(:model) ?
        project(BuildrPlus::Roles.project_with_role(:model).name) :
        nil
    shared_project =
      BuildrPlus::Roles.project_with_role?(:shared) ?
        project(BuildrPlus::Roles.project_with_role(:shared).name) :
        nil

    dependencies = [server_project, model_project, shared_project].compact
    dependencies << Object.const_get(:PACKAGED_DEPS) if Object.const_defined?(:PACKAGED_DEPS)

    war_module_names = [server_project.iml.name]
    jpa_module_names = []
    jpa_module_names << model_project.iml.name if model_project

    ejb_module_names = [server_project.iml.name]
    ejb_module_names << model_project.iml.name if model_project

    ipr.add_exploded_war_artifact(project,
                                  :dependencies => dependencies,
                                  :war_module_names => war_module_names,
                                  :jpa_module_names => jpa_module_names,
                                  :ejb_module_names => ejb_module_names)

    remote_packaged_apps = BuildrPlus::Glassfish.non_remote_only_packaged_apps.dup.merge(BuildrPlus::Glassfish.packaged_apps)
    local_packaged_apps = BuildrPlus::Glassfish.remote_only_packaged_apps.dup.merge(BuildrPlus::Glassfish.packaged_apps)

    ipr.add_glassfish_remote_configuration(project,
                                           :server_name => 'Payara 4.1.1.154',
                                           :exploded => [project.name],
                                           :packaged => remote_packaged_apps)
    ipr.add_glassfish_configuration(project,
                                    :server_name => 'Payara 4.1.1.154',
                                    :exploded => [project.name],
                                    :packaged => local_packaged_apps)
  end
end
