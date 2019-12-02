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

BuildrPlus::FeatureManager.feature(:deps => [:libs]) do |f|
  f.enhance(:Config) do

    def shared_generators
      generators = []
      generators += [:appconfig_feature_flag_container] if BuildrPlus::FeatureManager.activated?(:appconfig)
      generators += [:syncrecord_datasources] if BuildrPlus::FeatureManager.activated?(:syncrecord)
      generators += [:keycloak_client_definitions] if BuildrPlus::FeatureManager.activated?(:keycloak)
      generators.flatten
    end

    def model_generators
      generators = [:ee_data_types]
      if BuildrPlus::FeatureManager.activated?(:db)
        generators << [:jpa_model, :jpa_ejb_dao, :jpa_template_persistence_xml, :jpa_template_orm_xml, :jpa_model_persistence_xml, :jpa_model_orm_xml]
        generators << [:jpa_ejb_dao] if BuildrPlus::FeatureManager.activated?(:ejb)
        generators << [:imit_server_entity_listener] if BuildrPlus::FeatureManager.activated?(:replicant)
      end

      generators << [:xml_xsd_resources] if BuildrPlus::FeatureManager.activated?(:xml)
      generators << [:jms_model] if BuildrPlus::FeatureManager.activated?(:jms)
      generators << [:jws_shared] if BuildrPlus::FeatureManager.activated?(:soap)

      generators << [:jackson_date_util] if BuildrPlus::FeatureManager.activated?(:jackson)

      generators += self.shared_generators unless BuildrPlus::FeatureManager.activated?(:role_shared)

      generators.flatten
    end

    def model_only_generators
      generators = []

      generators << [:ee_model_beans_xml]

      generators.flatten
    end

    def model_qa_support_main_generators
      generators = []
      generators << [:jpa_main_qa, :jpa_main_qa_external] if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:sql_analysis_main_qa] if BuildrPlus::FeatureManager.activated?(:sql_analysis)
      generators << [:ejb_main_qa_external] if BuildrPlus::FeatureManager.activated?(:ejb)
      generators << [:imit_server_main_qa] if BuildrPlus::FeatureManager.activated?(:replicant)

      generators.flatten
    end

    def model_qa_support_test_generators
      generators = []
      generators << [:jpa_test_qa, :jpa_test_qa_external] if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:ejb_test_qa_external] if BuildrPlus::FeatureManager.activated?(:ejb)
      generators << [:imit_server_test_qa] if BuildrPlus::FeatureManager.activated?(:replicant)

      generators.flatten
    end

    def model_qa_generators
      generators = []
      generators << [:ee_test_qa, :ee_test_qa_aggregate]
      generators << [:jpa_dao_test, :jpa_application_orm_xml, :jpa_application_persistence_xml, :jpa_test_orm_xml, :jpa_test_persistence_xml] if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:jaxb_marshalling_tests] if BuildrPlus::FeatureManager.activated?(:xml)
      generators << [:jackson_marshalling_tests] if BuildrPlus::FeatureManager.activated?(:jackson)

      generators.flatten
    end

    def server_generators
      generators = [:ee_beans_xml, :ee_messages, :ee_messages_qa]

      generators << [:ee_web_xml] if BuildrPlus::Artifacts.war?
      if BuildrPlus::FeatureManager.activated?(:db)
        generators << [:jpa_application_orm_xml, :jpa_application_persistence_xml, :jpa_test_orm_xml, :jpa_test_persistence_xml]
        generators << [:imit_server_entity_replication] if BuildrPlus::FeatureManager.activated?(:replicant)
      end

      generators << [:graphql_endpoint] if BuildrPlus::FeatureManager.activated?(:graphql)
      generators << [:giggle] if BuildrPlus::FeatureManager.activated?(:giggle)
      generators << [:robots] if BuildrPlus::Artifacts.war?
      generators << [:gwt_rpc_shared, :gwt_rpc_server] if BuildrPlus::FeatureManager.activated?(:gwt)
      generators << [:berk_service_impl, :berk_qa_support] if BuildrPlus::FeatureManager.activated?(:berk)
      generators << [:imit_shared, :imit_server_service, :imit_server_qa] if BuildrPlus::FeatureManager.activated?(:replicant)

      if BuildrPlus::FeatureManager.activated?(:keycloak)
        generators << [:keycloak_config_service, :keycloak_js_service] if BuildrPlus::FeatureManager.activated?(:gwt)
      end

      if BuildrPlus::FeatureManager.activated?(:sync)
        if BuildrPlus::Sync.standalone?
          generators << [:sync_ejb]
        else
          generators << [:sync_core_ejb]
        end
      end

      generators << [:ee_exceptions, :ejb_service_facades, :ee_filter, :ejb_test_qa, :ejb_test_service_test] if BuildrPlus::FeatureManager.activated?(:ejb)

      generators << [:xml_public_xsd_webapp] if BuildrPlus::FeatureManager.activated?(:xml)
      generators << [:jws_server, :ejb_glassfish_config_assets] if BuildrPlus::FeatureManager.activated?(:soap)
      generators << [:jms_services, :jms_qa_support] if BuildrPlus::FeatureManager.activated?(:jms)
      generators << [:jaxrs] if BuildrPlus::FeatureManager.activated?(:jaxrs)
      generators << [:appcache] if BuildrPlus::FeatureManager.activated?(:appcache)
      generators << [:mail_mail_queue, :mail_test_module] if BuildrPlus::FeatureManager.activated?(:mail)
      generators << [:syncrecord_abstract_service, :syncrecord_control_rest_service] if BuildrPlus::FeatureManager.activated?(:syncrecord)
      generators << [:keycloak_filter, :keycloak_auth_service, :keycloak_auth_service_qa] if BuildrPlus::FeatureManager.activated?(:keycloak)
      generators << [:iris_audit_server] if BuildrPlus::FeatureManager.activated?(:iris_audit)

      generators += self.model_generators unless BuildrPlus::FeatureManager.activated?(:role_model)
      generators += self.model_qa_support_test_generators unless BuildrPlus::FeatureManager.activated?(:role_model_qa_support)
      generators += self.model_qa_generators unless BuildrPlus::FeatureManager.activated?(:role_model_qa)

      generators.flatten
    end

    def library_generators
      generators = [:ee_messages, :ee_messages_qa]
      if BuildrPlus::FeatureManager.activated?(:db)
        generators << [:jpa_dao_test, :jpa_test_orm_xml, :jpa_test_persistence_xml]
        generators << [:imit_server_entity_replication] if BuildrPlus::FeatureManager.activated?(:replicant)
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

      generators << [:ee_messages, :ee_exceptions, :ejb_service_facades, :ee_filter, :ejb_test_qa, :ejb_test_service_test] if BuildrPlus::FeatureManager.activated?(:ejb)

      generators << [:jms_services] if BuildrPlus::FeatureManager.activated?(:jms)
      generators << [:jaxrs] if BuildrPlus::FeatureManager.activated?(:jaxrs)
      generators << [:syncrecord_abstract_service, :syncrecord_control_rest_service] if BuildrPlus::FeatureManager.activated?(:syncrecord)
      generators << [:keycloak_auth_service, :keycloak_auth_service_qa] if BuildrPlus::FeatureManager.activated?(:keycloak)

      generators += self.model_generators unless BuildrPlus::FeatureManager.activated?(:role_model)
      generators += self.model_qa_support_test_generators unless BuildrPlus::FeatureManager.activated?(:role_model_qa_support)

      generators.flatten
    end

    def library_qa_support_generators
      generators = []
      generators << [:jpa_test_orm_xml, :jpa_test_persistence_xml] if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:ee_messages_qa, :ejb_test_qa, :ejb_test_qa_external] if BuildrPlus::FeatureManager.activated?(:ejb)

      generators.flatten
    end

    def gwt_generators
      generators = [:ce_data_types, :gwt_client_config, :gwt, :gwt_rpc_shared, :gwt_rpc_client_service, :gwt_client_jso, :gwt_client_module, :gwt_client_gwt_model_module]
      generators += [:keycloak_gwt_jso] if BuildrPlus::FeatureManager.activated?(:keycloak)
      generators += [:arez_entity] if BuildrPlus::FeatureManager.activated?(:arez)
      generators += [:imit_shared, :imit_client_entity, :ce_data_types, :imit_client_entity_gwt, :imit_client_service] if BuildrPlus::FeatureManager.activated?(:replicant)
      generators += [:imit_client_dao, :imit_client_dao_gwt] if BuildrPlus::FeatureManager.activated?(:replicant) && BuildrPlus::Replicant.replicant5?

      generators += self.shared_generators unless BuildrPlus::FeatureManager.activated?(:role_shared)

      generators.flatten
    end

    def gwt_qa_generators
      generators = []

      generators += [:arez_main_qa_external] if BuildrPlus::FeatureManager.activated?(:arez)
      generators += [:imit_client_main_qa_external, :imit_client_main_gwt_qa_external] if BuildrPlus::FeatureManager.activated?(:replicant)
      generators += [:imit_client_dao_gwt] if BuildrPlus::FeatureManager.activated?(:replicant) && BuildrPlus::Replicant.replicant5?

      generators += [:gwt_rpc_module]
      generators += [:gwt_client_main_jso_qa_support]

      generators.flatten
    end

    def gwt_qa_test_generators
      generators = [:gwt_rpc_test_module]
      generators += [:gwt_client_test_jso_qa_support]
      generators += [:imit_client_test_qa_external, :imit_client_test_gwt_qa_external] if BuildrPlus::FeatureManager.activated?(:replicant)
      generators += [:arez_test_qa_external] if BuildrPlus::FeatureManager.activated?(:arez)

      generators.flatten
    end

    def user_experience_generators
      generators = [:gwt_client_app, :gwt_client_gwt_modules, :gwt_client_test_ux_qa_support]
      generators += [:imit_client_react4j_support] if BuildrPlus::FeatureManager.activated?(:replicant) && !BuildrPlus::Replicant.replicant5?
      generators += self.gwt_generators unless BuildrPlus::FeatureManager.activated?(:role_gwt)
      generators += self.gwt_qa_test_generators unless BuildrPlus::FeatureManager.activated?(:role_gwt_qa)

      generators.flatten
    end

    def integration_qa_shared_generators
      generators = [:ee_integration_provisioner]
      generators.flatten
    end

    def integration_qa_support_generators
      generators = [:ee_integration]
      generators << [:jpa_application_orm_xml, :jpa_application_persistence_xml] if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:keycloak_main_integration_qa] if BuildrPlus::FeatureManager.activated?(:keycloak)
      generators += self.model_generators unless BuildrPlus::FeatureManager.activated?(:role_model)
      generators += self.model_qa_support_main_generators unless BuildrPlus::FeatureManager.activated?(:role_model_qa_support)
      generators.flatten
    end

    def shared_deps
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.javax_annotations)

      dependencies.flatten
    end

    def shared_test_deps
      dependencies = []

      dependencies << Buildr.artifacts([BuildrPlus::Libs.guiceyloops_gwt])

      dependencies.flatten
    end

    def gwt_provided_deps
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.jetbrains_annotations)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.spotbugs_provided)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.dagger_gwt)

      dependencies.flatten
    end

    def gwt_processorpath
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.dagger_compiler)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.arez_processor)

      dependencies.flatten
    end

    def gwt_compile_deps
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.gwt_user)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.braincheck)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.keycloak_gwt) if BuildrPlus::FeatureManager.activated?(:keycloak)
      dependencies << Buildr.artifacts([:iris_audit_gwt]) if BuildrPlus::FeatureManager.activated?(:iris_audit)
      dependencies << Buildr.artifacts(:berk_gwt) if BuildrPlus::FeatureManager.activated?(:berk)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.arez + BuildrPlus::Libs.grim_annotations + BuildrPlus::Libs.jetbrains_annotations + BuildrPlus::Libs.arez_spytools) if BuildrPlus::FeatureManager.activated?(:arez)
      if BuildrPlus::FeatureManager.activated?(:replicant)
        if BuildrPlus::Replicant.replicant5?
          dependencies << Buildr.artifacts(BuildrPlus::Libs.replicant5_client)
        else
          dependencies << Buildr.artifacts(BuildrPlus::Libs.replicant_client)
        end
      end
      if BuildrPlus::FeatureManager.activated?(:react4j)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.react4j)
      end

      dependencies.flatten
    end

    def gwt_deps
      self.gwt_provided_deps + self.gwt_compile_deps
    end

    def gwt_qa_support_deps
      dependencies = []

      dependencies << gwt_deps
      dependencies << Buildr.artifacts(BuildrPlus::Libs.guiceyloops_gwt)
      dependencies << Buildr.artifacts([:iris_audit_gwt_qa_support]) if BuildrPlus::FeatureManager.activated?(:iris_audit)
      dependencies << Buildr.artifacts(:berk_gwt_qa_support) if BuildrPlus::FeatureManager.activated?(:berk)

      dependencies.flatten
    end

    def model_provided_deps
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.ee_provided)

      # Our JPA beans are occasionally generated with eclipselink specific artifacts
      dependencies << Buildr.artifacts(BuildrPlus::Libs.glassfish_embedded) if BuildrPlus::FeatureManager.activated?(:db) || BuildrPlus::FeatureManager.activated?(:jackson)

      dependencies.flatten
    end

    def model_compile_deps
      dependencies = []

      if BuildrPlus::FeatureManager.activated?(:geolatte)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geolatte_geom)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geolatte_support)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geotools_for_geolatte) if BuildrPlus::FeatureManager.activated?(:geotools)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geolatte_geom_jpa) if BuildrPlus::FeatureManager.activated?(:db)
      end
      dependencies << Buildr.artifacts([BuildrPlus::Libs.jackson_gwt_support]) if BuildrPlus::FeatureManager.activated?(:jackson)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.timeservice) if BuildrPlus::FeatureManager.activated?(:timeservice)

      dependencies.flatten
    end

    def model_deps
      model_provided_deps + model_compile_deps
    end

    def model_qa_support_deps
      dependencies = []

      dependencies << Buildr.artifacts([BuildrPlus::Libs.guiceyloops])
      dependencies << model_deps
      dependencies << Buildr.artifacts([BuildrPlus::Libs.db_drivers]) if BuildrPlus::FeatureManager.activated?(:db)
      dependencies << Buildr.artifacts([BuildrPlus::Mail.mail_server, BuildrPlus::Mail.mail_qa, BuildrPlus::Libs.mustache, BuildrPlus::Libs.greenmail]) if BuildrPlus::FeatureManager.activated?(:mail)
      dependencies << Buildr.artifacts([BuildrPlus::Appconfig.appconfig_server, BuildrPlus::Appconfig.appconfig_qa, BuildrPlus::Libs.field_filter]) if BuildrPlus::FeatureManager.activated?(:appconfig)
      dependencies << Buildr.artifacts([BuildrPlus::Syncrecord.syncrecord_server, BuildrPlus::Syncrecord.syncrecord_qa]) if BuildrPlus::FeatureManager.activated?(:syncrecord)

      dependencies.flatten
    end

    def integration_qa_shared_deps
      dependencies = []

      dependencies << model_qa_support_deps
      dependencies << Buildr.artifacts([BuildrPlus::Libs.glassfish_embedded])

      dependencies.flatten
    end

    def integration_qa_support_deps
      dependencies = []

      dependencies << model_qa_support_deps
      dependencies << Buildr.artifacts([BuildrPlus::Syncrecord.syncrecord_rest_client, BuildrPlus::Syncrecord.syncrecord_server_qa]) if BuildrPlus::FeatureManager.activated?(:syncrecord)
      dependencies << Buildr.artifacts([BuildrPlus::Libs.glassfish_embedded])
      dependencies << Buildr.artifacts(BuildrPlus::Libs.awaitility) if BuildrPlus::FeatureManager.activated?(:jms)
      if BuildrPlus::FeatureManager.activated?(:keycloak)
        dependencies << Buildr.artifacts([BuildrPlus::Libs.keycloak_authfilter])
      end
      dependencies.flatten
    end

    def integration_deps
      dependencies = []

      dependencies << self.integration_qa_support_deps

      dependencies.flatten
    end

    def server_provided_deps
      dependencies = []

      dependencies << self.model_provided_deps
      dependencies << Buildr.artifacts(BuildrPlus::Libs.glassfish_embedded) if BuildrPlus::FeatureManager.activated?(:soap)

      dependencies.flatten
    end

    def server_compile_deps
      dependencies = []

      dependencies << model_compile_deps
      dependencies << Buildr.artifacts([BuildrPlus::Libs.gwt_cache_filter]) if BuildrPlus::FeatureManager.activated?(:gwt_cache_filter)
      dependencies << Buildr.artifacts([BuildrPlus::Mail.mail_server, BuildrPlus::Libs.mustache]) if BuildrPlus::FeatureManager.activated?(:mail)
      dependencies << Buildr.artifacts([BuildrPlus::Appconfig.appconfig_server, BuildrPlus::Libs.field_filter]) if BuildrPlus::FeatureManager.activated?(:appconfig)
      dependencies << Buildr.artifacts([BuildrPlus::Syncrecord.syncrecord_server, BuildrPlus::Syncrecord.syncrecord_rest_client]) if BuildrPlus::FeatureManager.activated?(:syncrecord)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.gwt_rpc) if BuildrPlus::FeatureManager.activated?(:gwt)
      if BuildrPlus::FeatureManager.activated?(:replicant)
        if BuildrPlus::Replicant.replicant5?
          dependencies << Buildr.artifacts(BuildrPlus::Libs.replicant5_server)
        else
          dependencies << Buildr.artifacts(BuildrPlus::Libs.replicant_server)
        end
      end
      dependencies << Buildr.artifacts(BuildrPlus::Libs.gwt_appcache_server) if BuildrPlus::FeatureManager.activated?(:appcache)
      if BuildrPlus::FeatureManager.activated?(:graphql)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.graphql_java_servlet)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.graphql_java_scalars)
      end
      if BuildrPlus::FeatureManager.activated?(:keycloak)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.keycloak)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.simple_keycloak_service)
        if BuildrPlus::FeatureManager.activated?(:gwt)
          dependencies << Buildr.artifacts(BuildrPlus::Libs.proxy_servlet)
        end
      end
      dependencies << Buildr.artifacts(:iris_audit_server) if BuildrPlus::FeatureManager.activated?(:iris_audit)
      dependencies << Buildr.artifacts([:berk_model, :berk_server]) if BuildrPlus::FeatureManager.activated?(:berk)

      dependencies << Buildr.artifacts(Object.const_get(:PACKAGED_DEPS)) if Object.const_defined?(:PACKAGED_DEPS)
      dependencies << Buildr.artifacts(Object.const_get(:LIBRARY_DEPS)) if Object.const_defined?(:LIBRARY_DEPS)

      dependencies.flatten
    end

    def server_test_deps
      dependencies = []

      dependencies << self.model_qa_support_deps
      dependencies << Buildr.artifacts(BuildrPlus::Syncrecord.syncrecord_server_qa) if BuildrPlus::FeatureManager.activated?(:syncrecord)
      dependencies << Buildr.artifacts([:berk_model_qa_support]) if BuildrPlus::FeatureManager.activated?(:berk)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.awaitility)

      dependencies.flatten
    end

    def server_deps
      self.server_provided_deps + self.server_compile_deps
    end

    def user_experience_deps
      dependencies = []

      dependencies << self.gwt_deps
      dependencies << Buildr.artifacts([BuildrPlus::Libs.gwt_appcache_linker, BuildrPlus::Libs.gwt_appcache_server]) if BuildrPlus::FeatureManager.activated?(:appcache)

      dependencies.flatten
    end

    def user_experience_processorpath
      dependencies = []

      dependencies << self.gwt_processorpath
      dependencies << BuildrPlus::Libs.react4j_processor if BuildrPlus::FeatureManager.activated?(:react4j)

      dependencies.flatten
    end

    def user_experience_test_deps
      dependencies = []

      dependencies << self.gwt_qa_support_deps

      dependencies.flatten
    end
  end
end
