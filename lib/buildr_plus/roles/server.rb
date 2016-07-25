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

BuildrPlus::Roles.role(:server) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = [:ee_beans_xml]
    generators << [:ee_web_xml] if BuildrPlus::Artifacts.war?
    if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:jpa_dao_test]

      generators << [:jpa_test_orm_xml, :jpa_test_persistence_xml] unless BuildrPlus::Artifacts.is_model_standalone?

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

    generators << [:xml_public_xsd_webapp] if BuildrPlus::FeatureManager.activated?(:xml)
    generators << [:jws_server, :ejb_glassfish_config_assets] if BuildrPlus::FeatureManager.activated?(:soap)
    generators << [:jms] if BuildrPlus::FeatureManager.activated?(:jms)
    generators << [:jaxrs] if BuildrPlus::FeatureManager.activated?(:jaxrs)
    generators << [:appcache] if BuildrPlus::FeatureManager.activated?(:appcache)
    generators << [:mail_mail_queue, :mail_test_module] if BuildrPlus::FeatureManager.activated?(:mail)
    generators << [:syncrecord_abstract_service, :syncrecord_control_rest_service] if BuildrPlus::FeatureManager.activated?(:syncrecord)
    generators << [:keycloak_filter] if BuildrPlus::FeatureManager.activated?(:keycloak)
    generators << [:timerstatus_filter] if BuildrPlus::FeatureManager.activated?(:timerstatus)

    generators += project.additional_domgen_generators

    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project)
  end

  project.publish = true

  # Our soap services use annotation for validation that is metro specific
  compile.with BuildrPlus::Libs.glassfish_embedded if BuildrPlus::FeatureManager.activated?(:soap)

  compile.with artifacts(Object.const_get(:PACKAGED_DEPS)) if Object.const_defined?(:PACKAGED_DEPS)
  compile.with BuildrPlus::Deps.server_deps
  compile.with BuildrPlus::Libs.ee_provided unless BuildrPlus::FeatureManager.activated?(:model)

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :model)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :model_qa_support)

  test.with BuildrPlus::Libs.db_drivers
  test.with artifacts([BuildrPlus::Syncrecord.syncrecord_server_qa]) if BuildrPlus::FeatureManager.activated?(:syncrecord)

  package(:war).tap do |war|
    war.libs.clear
    war.libs << artifacts(Object.const_get(:PACKAGED_DEPS)) if Object.const_defined?(:PACKAGED_DEPS)
    war.libs << BuildrPlus::Deps.model_deps
    war.libs << BuildrPlus::Deps.server_deps
    BuildrPlus::Roles.buildr_projects_with_role(:shared).each do |dep|
      war.libs << dep.package(:jar)
    end
    BuildrPlus::Roles.buildr_projects_with_role(:model).each do |dep|
      war.libs << dep.package(:jar)
    end
    war.exclude project.less_path if BuildrPlus::FeatureManager.activated?(:less)
    if BuildrPlus::FeatureManager.activated?(:sass)
      project.sass_paths.each do |sass_path|
        war.exclude project._(sass_path)
      end
    end
    war.include assets.to_s, :as => '.' if BuildrPlus::FeatureManager.activated?(:gwt) || BuildrPlus::FeatureManager.activated?(:less) || BuildrPlus::FeatureManager.activated?(:sass)
  end

  check package(:war), 'should contain generated gwt artifacts' do
    it.should contain("#{project.root_project.name}/#{project.root_project.name}.nocache.js")
  end if BuildrPlus::FeatureManager.activated?(:gwt) && BuildrPlus::FeatureManager.activated?(:user_experience)
  check package(:war), 'should contain web.xml' do
    it.should contain('WEB-INF/web.xml')
  end
  check package(:war), 'should not contain less files' do
    it.should_not contain('**/*.less')
  end if BuildrPlus::FeatureManager.activated?(:less)
  check package(:war), 'should not contain sass files' do
    it.should_not contain('**/*.sass')
  end if BuildrPlus::FeatureManager.activated?(:sass)

  project.iml.add_ejb_facet if BuildrPlus::FeatureManager.activated?(:ejb)
  webroots = {}
  webroots[_(:source, :main, :webapp)] = '/'
  webroots[_(:source, :main, :webapp_local)] = '/' if BuildrPlus::FeatureManager.activated?(:gwt)
  webroots[_('..', :generated, 'gwt-export')] = '/' if BuildrPlus::FeatureManager.activated?(:gwt)

  project.assets.paths.each do |path|
    next if path.to_s =~ /generated\/gwt\// && BuildrPlus::FeatureManager.activated?(:gwt)
    next if path.to_s =~ /generated\/less\// && BuildrPlus::FeatureManager.activated?(:less)
    next if path.to_s =~ /generated\/sass\// && BuildrPlus::FeatureManager.activated?(:sass)
    webroots[path.to_s] = '/'
  end

  project.iml.add_web_facet(:webroots => webroots)
end
