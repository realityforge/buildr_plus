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

BuildrPlus::Roles.role(:gwt, :requires => [:gwt]) do

  project.publish = BuildrPlus::Artifacts.gwt?

  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = [:gwt, :gwt_rpc_shared, :gwt_rpc_client_service, :gwt_client_jso, :auto_bean, :gwt_client_module, :gwt_client_gwt_model_module]
    generators += [:keycloak_gwt_jso] if BuildrPlus::FeatureManager.activated?(:keycloak)
    generators += [:imit_client_entity_gwt, :imit_client_service] if BuildrPlus::FeatureManager.activated?(:replicant)
    generators += project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators, :buildr_project => project) do |t|
      t.filter = Proc.new do |artifact_type, artifact|
        artifact_type != :message || !artifact.any_non_standard_types?
      end if BuildrPlus::FeatureManager.activated?(:role_user_experience)
    end
  end

  compile.with BuildrPlus::Libs.findbugs_provided, BuildrPlus::Libs.gwt_gin
  compile.with BuildrPlus::Libs.gwt_datatypes
  compile.with BuildrPlus::Libs.keycloak_gwt if BuildrPlus::FeatureManager.activated?(:keycloak)

  compile.with BuildrPlus::Libs.replicant_gwt_client if BuildrPlus::FeatureManager.activated?(:replicant)

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :shared)
  BuildrPlus::Roles.merge_projects_with_role(project.compile, :replicant_shared)

  test.with BuildrPlus::Libs.mockito
  test.with BuildrPlus::Libs.replicant_client_qa_support if BuildrPlus::FeatureManager.activated?(:replicant)

  package(:jar)
  package(:sources)

  BuildrPlus::Gwt.add_source_to_jar(project)

  p = project.root_project

  # This compile exists to verify that module is independently compilable
  BuildrPlus::Gwt.define_gwt_task(project, ".#{p.name_as_class}") if BuildrPlus::Artifacts.library?

  BuildrPlus::Gwt.define_gwt_idea_facet(project)

  check package(:jar), 'should contain generated source files' do
    it.should contain("#{p.group_as_path}/client/ioc/#{p.name_as_class}GwtRpcServicesModule.class")
  end if BuildrPlus::Domgen.enforce_package_name? && BuildrPlus::FeatureManager.activated?(:domgen)
end
