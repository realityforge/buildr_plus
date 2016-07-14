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

BuildrPlus::Roles.role(:all_in_one_library) do
  project.publish = true

  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = [:ee_data_types, :ee_beans_xml]
    generators << [:ee_web_xml] if BuildrPlus::Artifacts.war?
    if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:jpa]
      generators << [:jpa_test_qa, :jpa_test_qa_external, :jpa_ejb_dao, :jpa_dao_test] if BuildrPlus::FeatureManager.activated?(:ejb)
      generators << [:jpa_test_orm_xml, :jpa_test_persistence_xml] unless BuildrPlus::Artifacts.is_model_standalone?
      generators << [:imit_server_entity_listener, :imit_server_entity_replication] if BuildrPlus::FeatureManager.activated?(:replicant)
    end

    generators << [:gwt_rpc_shared, :gwt_rpc_server] if BuildrPlus::FeatureManager.activated?(:gwt)
    generators << [:imit_shared, :imit_server_service, :imit_server_qa] if BuildrPlus::FeatureManager.activated?(:replicant)

    if BuildrPlus::FeatureManager.activated?(:sync)
      if BuildrPlus::Sync.standalone?
        generators << [:sync_ejb]
      else
        generators << [:sync_core_ejb]
      end
    end

    generators << [:ee_messages, :ee_exceptions, :ejb_service_facades, :ejb_test_qa_external, :ee_filter, :ejb_test_qa, :ejb_test_service_test] if BuildrPlus::FeatureManager.activated?(:ejb)

    generators << [:jackson_date_util, :jackson_marshalling_tests] if BuildrPlus::FeatureManager.activated?(:jackson)

    generators << [:jaxb_marshalling_tests, :xml_xsd_resources, :xml_public_xsd_webapp] if BuildrPlus::FeatureManager.activated?(:xml)
    generators << [:jws_server, :ejb_glassfish_config_assets] if BuildrPlus::FeatureManager.activated?(:soap)

    generators << [:jms] if BuildrPlus::FeatureManager.activated?(:jms)
    generators << [:jaxrs] if BuildrPlus::FeatureManager.activated?(:jaxrs)
    generators << [:mail_mail_queue, :mail_test_module] if BuildrPlus::FeatureManager.activated?(:mail)
    generators << [:appconfig_feature_flag_container] if BuildrPlus::FeatureManager.activated?(:appconfig)
    generators << [:syncrecord_datasources, :syncrecord_abstract_service, :syncrecord_control_rest_service] if BuildrPlus::FeatureManager.activated?(:syncrecord)

    generators += project.additional_domgen_generators

    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project)
  end

  compile.with BuildrPlus::Libs.ee_provided
  compile.with BuildrPlus::Libs.glassfish_embedded if BuildrPlus::FeatureManager.activated?(:soap) || BuildrPlus::FeatureManager.activated?(:db)

  compile.with artifacts(Object.const_get(:LIBRARY_DEPS)) if Object.const_defined?(:LIBRARY_DEPS)
  compile.with BuildrPlus::Deps.model_deps
  compile.with BuildrPlus::Deps.server_deps

  test.with BuildrPlus::Libs.guiceyloops,
            BuildrPlus::Libs.db_drivers
  test.with BuildrPlus::Deps.model_qa_support_deps

  package(:jar)
  package(:sources)

  iml.add_jpa_facet if BuildrPlus::FeatureManager.activated?(:db)
  iml.add_ejb_facet if BuildrPlus::FeatureManager.activated?(:ejb)

  default_testng_args = []
  default_testng_args << '-ea'
  default_testng_args << '-Xmx2024M'
  default_testng_args << '-XX:MaxPermSize=364M'

  if BuildrPlus::FeatureManager.activated?(:db)
    default_testng_args << "-javaagent:#{Buildr.artifact(BuildrPlus::Libs.eclipselink).to_s}"

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

  default_testng_args.concat(BuildrPlus::Glassfish.addtional_default_testng_args)

  ipr.add_default_testng_configuration(:jvm_args => default_testng_args.join(' '))
end
