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

BuildrPlus::Roles.role(:integration_tests) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = [:ee_integration_test]
    generators << [:jpa_test_orm_xml, :jpa_test_persistence_xml] if BuildrPlus::FeatureManager.activated?(:db)
    generators << [:jms_integration_tests] if BuildrPlus::FeatureManager.activated?(:jms)
    generators << [:jws_service_integration_test] if BuildrPlus::FeatureManager.activated?(:soap)
    generators << [:appconfig_integration_test] if BuildrPlus::FeatureManager.activated?(:appconfig)
    generators << [:syncrecord_integration_test] if BuildrPlus::FeatureManager.activated?(:syncrecord)
    generators << [:timerstatus_integration_test] if BuildrPlus::FeatureManager.activated?(:timerstatus)
    generators += project.additional_domgen_generators

    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project) do |t|
      t.filter = project.domgen_filter
    end
  end

  server_project = BuildrPlus::Roles.buildr_project_with_role(:server)
  war_package = server_project.package(:war)

  project.publish = false
  test.enhance(artifacts(BuildrPlus::Libs.glassfish_embedded))
  test.enhance([war_package])

  test.with BuildrPlus::Deps.integration_deps

  BuildrPlus::Roles.merge_projects_with_role(project.test, :integration_qa_support)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :soap_client)

  properties = {
    'embedded.glassfish.artifacts' => BuildrPlus::Guiceyloops.glassfish_spec_list,
    'war.filename' => war_package.to_s,
  }
  BuildrPlus::Integration.additional_applications_to_deploy.each do |key, artifact|
    properties["#{key}.war.filename"] = Buildr.artifact(artifact).to_s
    test.enhance([Buildr.artifact(artifact)])
  end

  test.using :java_args => BuildrPlus::Guiceyloops.integration_test_java_args, :properties => properties

  package(:jar)
  package(:sources)
end
