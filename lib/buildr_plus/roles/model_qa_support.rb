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

BuildrPlus::Roles.role(:model_qa_support) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = BuildrPlus::Deps.model_qa_support_main_generators + project.additional_domgen_generators

    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project) do |t|
      t.filter = project.domgen_filter
    end
  end

  project.publish = BuildrPlus::Artifacts.model?

  compile.with BuildrPlus::Deps.model_qa_support_deps

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :model)

  package(:jar)
  package(:sources)

  check package(:jar), 'should contain generated classes' do
    it.should contain("#{project.root_project.group_as_path}/server/test/util/#{project.root_project.name_as_class}RepositoryModule.class")
  end if BuildrPlus::Domgen.enforce_package_name? && BuildrPlus::FeatureManager.activated?(:db)
end
