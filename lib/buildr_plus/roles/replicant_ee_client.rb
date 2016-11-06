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

BuildrPlus::Roles.role(:replicant_ee_client, :requires => [:role_replicant_shared, :soap]) do

  project.publish = BuildrPlus::Artifacts.replicant_client?

  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = []
    generators += [:imit_client_entity_ee]
    generators += [:ee_exceptions]
    generators += project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators, :buildr_project => project) do |t|
      t.filter = Proc.new do |artifact_type, artifact|
        artifact_type != :exception || (artifact == artifact.data_module.repository.exception_by_name(artifact.data_module.repository.imit.invalid_session_exception))
      end
    end
  end

  compile.with BuildrPlus::Libs.ee_provided
  compile.with BuildrPlus::Libs.gwt_webpoller
  compile.with BuildrPlus::Libs.glassfish_embedded

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :replicant_shared)
  BuildrPlus::Roles.merge_projects_with_role(project.compile, :soap_client)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :replicant_qa_support)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :soap_qa_support)

  test.with BuildrPlus::Libs.mockito

  package(:jar)
  package(:sources)

  p = project.root_project

  check package(:jar), 'should contain generated source files' do
    it.should contain("#{p.group_as_path}/client/net/Abstract#{p.name_as_class}EeDataLoaderServiceImpl.class")
  end if BuildrPlus::Domgen.enforce_package_name?
end
