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

    def server_generators
      generators = [
        :ee_beans_xml,
        :ee_exception_util,
        :ee_messages,
        :ee_messages_qa,
        :ee_data_types,
        :ee_constants,
        :ee_test_qa,
        :ee_test_qa_aggregate,
        :sql_analysis_test_qa
      ]

      generators << [:ee_web_xml]
      if BuildrPlus::FeatureManager.activated?(:db)
        generators << [
          :jpa_application_orm_xml,
          :jpa_application_persistence_xml,
          :jpa_test_orm_xml,
          :jpa_test_persistence_xml,
          :jpa_model,
          :jpa_ejb_dao,
          :jpa_template_persistence_xml,
          :jpa_template_orm_xml,
          :jpa_model_persistence_xml,
          :jpa_model_orm_xml
        ]
        generators << [:jpa_ejb_dao] if BuildrPlus::FeatureManager.activated?(:ejb)
      end

      generators << [:robots]
      generators << [:imit_metadata] if BuildrPlus::FeatureManager.activated?(:replicant) && !BuildrPlus::FeatureManager.activated?(:role_shared)
      generators << [:imit_server_service, :imit_server_qa] if BuildrPlus::FeatureManager.activated?(:replicant)
      generators << [:action_server] if BuildrPlus::FeatureManager.activated?(:action)

      if BuildrPlus::FeatureManager.activated?(:keycloak)
        generators << [:keycloak_config_service, :keycloak_js_service] if BuildrPlus::FeatureManager.activated?(:gwt)
      end

      generators << [:ee_exceptions, :ejb_services, :ejb_test_qa, :ejb_test_service_test] if BuildrPlus::FeatureManager.activated?(:ejb)

      generators << [:ejb_glassfish_config_assets] if BuildrPlus::FeatureManager.activated?(:ejb)
      generators << [:jms_services, :jms_qa_support] if BuildrPlus::FeatureManager.activated?(:jms)
      generators << [:jaxrs] if BuildrPlus::FeatureManager.activated?(:jaxrs)
      generators << [:keycloak_filter, :keycloak_auth_service, :keycloak_auth_service_qa] if BuildrPlus::FeatureManager.activated?(:keycloak)

      generators << [:xml_public_xsd_webapp, :xml_xsd_resources] if BuildrPlus::FeatureManager.activated?(:xml)
      generators << [:jms_model] if BuildrPlus::FeatureManager.activated?(:jms)

      generators << [:jackson_date_util, :jackson_marshalling_tests] if BuildrPlus::FeatureManager.activated?(:jackson)

      generators << [:jpa_test_qa, :jpa_test_qa_external] if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:ejb_test_qa_external] if BuildrPlus::FeatureManager.activated?(:ejb)
      generators << [:imit_server_test_qa] if BuildrPlus::FeatureManager.activated?(:replicant)

      generators << [:jpa_dao_test, :jpa_application_orm_xml, :jpa_application_persistence_xml, :jpa_test_orm_xml, :jpa_test_persistence_xml] if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:jackson_marshalling_tests] if BuildrPlus::FeatureManager.activated?(:jackson)

      generators.flatten
    end

    def user_experience_generators
      generators = [:gwt_client_app, :gwt_client_gwt_modules]
      generators += [:ce_data_types, :gwt, :gwt_client_jso, :gwt_client_module, :gwt_client_gwt_model_module]
      generators += [:keycloak_gwt_jso] if BuildrPlus::FeatureManager.activated?(:keycloak)
      generators += [:arez_entity] if BuildrPlus::FeatureManager.activated?(:arez)
      if BuildrPlus::FeatureManager.activated?(:replicant)
        generators << [:imit_metadata] unless BuildrPlus::FeatureManager.activated?(:role_shared)
        generators += [:imit_client_entity, :ce_data_types, :imit_client_service]
        generators += [:imit_client_react4j_support] if BuildrPlus::FeatureManager.activated?(:react4j)
      end

      generators += [:gwt_client_test_jso_qa_support]
      generators += [:imit_client_test_qa_external] if BuildrPlus::FeatureManager.activated?(:replicant)
      generators += [:keycloak_gwt_test_qa] if BuildrPlus::FeatureManager.activated?(:keycloak)
      generators += [:arez_test_qa_external] if BuildrPlus::FeatureManager.activated?(:arez)
      generators.flatten
    end

    def server_provided_deps
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.ee_provided)

      # Our JPA beans are occasionally generated with eclipselink specific artifacts
      dependencies << Buildr.artifacts(BuildrPlus::Libs.eclipse_persistence_core) if BuildrPlus::FeatureManager.activated?(:db)

      dependencies << Buildr.artifacts(BuildrPlus::Libs.jakarta_xml_bind_api) if BuildrPlus::FeatureManager.activated?(:xml)

      dependencies << Buildr.artifacts([BuildrPlus::Libs.db_drivers]) if BuildrPlus::FeatureManager.activated?(:db)

      dependencies.flatten
    end

    def server_compile_deps
      dependencies = []

      dependencies << Buildr.artifacts([BuildrPlus::Libs.jackson_databind]) if BuildrPlus::FeatureManager.activated?(:jackson)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.timeservice) if BuildrPlus::FeatureManager.activated?(:timeservice)
      dependencies << Buildr.artifacts([BuildrPlus::Libs.gwt_cache_filter]) if BuildrPlus::FeatureManager.activated?(:gwt_cache_filter)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.replicant_server) if BuildrPlus::FeatureManager.activated?(:replicant)
      if BuildrPlus::FeatureManager.activated?(:keycloak)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.keycloak)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.simple_keycloak_service)
        if BuildrPlus::FeatureManager.activated?(:gwt)
          dependencies << Buildr.artifacts(BuildrPlus::Libs.proxy_servlet)
        end

        unless BuildrPlus::Keycloak.remote_clients.empty?
          # This will also include this library in server when remote clients only used in client
          # but this is a relatively rare scenario
          dependencies << BuildrPlus::Libs.keycloak_authfilter
        end
      end

      dependencies << Buildr.artifacts(Object.const_get(:PACKAGED_DEPS)) if Object.const_defined?(:PACKAGED_DEPS)
      dependencies << Buildr.artifacts(Object.const_get(:LIBRARY_DEPS)) if Object.const_defined?(:LIBRARY_DEPS)

      dependencies.flatten
    end

    def server_test_deps
      dependencies = []

      dependencies << Buildr.artifacts([BuildrPlus::Libs.guiceyloops])
      dependencies << Buildr.artifacts(BuildrPlus::Libs.awaitility)

      dependencies.flatten
    end

    def server_deps
      self.server_provided_deps + self.server_compile_deps
    end

    def user_experience_deps
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.jetbrains_annotations)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.javax_annotations)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.sting_core) if BuildrPlus::FeatureManager.activated?(:sting)

      dependencies << Buildr.artifacts(BuildrPlus::Libs.javaemul)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.gwt_user)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.braincheck)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.jsinterop_base) if BuildrPlus::FeatureManager.activated?(:gwt)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.keycloak_gwt) if BuildrPlus::FeatureManager.activated?(:keycloak)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.arez + BuildrPlus::Libs.arez_spytools) if BuildrPlus::FeatureManager.activated?(:arez)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.replicant_client) if BuildrPlus::FeatureManager.activated?(:replicant)
      if BuildrPlus::FeatureManager.activated?(:react4j)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.react4j)
      end
      dependencies << Buildr::GWT.dependencies(Buildr::GWT.version)
      dependencies << Buildr.artifacts([BuildrPlus::Libs.gwt_serviceworker, BuildrPlus::Libs.zemeckis_core]) if BuildrPlus::FeatureManager.activated?(:serviceworker)

      dependencies.flatten
    end

    def user_experience_processorpath
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.sting_processor) if BuildrPlus::FeatureManager.activated?(:sting)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.arez_processor) if BuildrPlus::FeatureManager.activated?(:arez)
      dependencies << BuildrPlus::Libs.react4j_processor if BuildrPlus::FeatureManager.activated?(:react4j)

      dependencies.flatten
    end

    def user_experience_test_deps
      dependencies = []

      dependencies << Buildr.artifacts(BuildrPlus::Libs.mockito)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.testng)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.arez_testng) if BuildrPlus::FeatureManager.activated?(:arez)

      dependencies.flatten
    end
  end
end
