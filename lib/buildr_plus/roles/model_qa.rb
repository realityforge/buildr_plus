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

BuildrPlus::Roles.role(:model_qa) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = []
    if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:jpa_dao_test, :jpa_application_orm_xml, :jpa_application_persistence_xml, :jpa_test_orm_xml, :jpa_test_persistence_xml]
    end

    generators += project.additional_domgen_generators

    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project) do |t|
      t.filter = project.domgen_filter
    end
  end

  project.publish = false

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :model)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :model_qa_support)

  test.with BuildrPlus::Libs.ee_provided

  # Our JPA beans are occasionally generated with eclipselink specific artifacts
  test.with BuildrPlus::Libs.glassfish_embedded if BuildrPlus::FeatureManager.activated?(:db)
  test.with BuildrPlus::Libs.guiceyloops
  test.with BuildrPlus::Deps.model_qa_support_deps
  test.with BuildrPlus::Libs.db_drivers
end
