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

BuildrPlus::Roles.role(:user_experience, :requires => [:role_gwt, :gwt]) do

  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = [:gwt_client_event, :gwt_client_app, :gwt_client_gwt_modules]
    generators += [:keycloak_gwt_app] if BuildrPlus::FeatureManager.activated?(:keycloak)
    generators += project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators, :buildr_project => project) do |t|
      t.filter = Proc.new do |artifact_type, artifact|
        artifact_type != :message || artifact.any_non_standard_types?
      end
    end
  end

  if BuildrPlus::FeatureManager.activated?(:resgen)
    generators = [:gwt_client_bundle]
    generators += project.additional_resgen_generators
    Resgen::Build.define_generate_task(generators, :buildr_project => project) do |t|
      t.filter = Resgen::Filters.include_catalog(:UserExperience)
    end
  end

  project.publish = false

  compile.with BuildrPlus::Deps.user_experience_deps

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :gwt)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :gwt_qa_support)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :replicant_qa_support)

  package(:jar)
  package(:sources)

  BuildrPlus::Gwt.add_source_to_jar(project)

  BuildrPlus::Gwt.define_gwt_idea_facet(project)
end
