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

BuildrPlus::Roles.role(:library_qa_support) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = []
    if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:jpa_test_orm_xml, :jpa_test_persistence_xml] unless BuildrPlus::Artifacts.is_model_standalone?
    end
    if BuildrPlus::FeatureManager.activated?(:ejb)
      generators << [:ejb_test_qa]
    end
    generators += project.additional_domgen_generators

    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project)
  end

  project.publish = true

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :library)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :model_qa_support)

  compile.with BuildrPlus::Libs.guiceyloops

  test.with BuildrPlus::Libs.db_drivers

  package(:jar)
  package(:sources)
end
