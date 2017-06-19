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

BuildrPlus::Roles.role(:replicant_shared, :requires => [:replicant]) do

  project.publish = BuildrPlus::Artifacts.replicant_client?

  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = BuildrPlus::Deps.replicant_shared_generators + project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators, :buildr_project => project)
  end

  compile.with BuildrPlus::Deps.replicant_shared_deps

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :shared)

  test.with BuildrPlus::Libs.mockito

  package(:jar)
  package(:sources)

  if BuildrPlus::FeatureManager.activated?(:gwt)
    BuildrPlus::Gwt.add_source_to_jar(project)
    BuildrPlus::Gwt.define_gwt_idea_facet(project)
  end
end
