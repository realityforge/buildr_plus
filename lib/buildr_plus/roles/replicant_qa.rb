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

BuildrPlus::Roles.role(:replicant_qa) do

  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = []
    generators += project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators, :buildr_project => project) do |t|
      t.filter = project.domgen_filter
    end
  end

  project.publish = false

  project.test.options[:java_args] = (project.test.options[:java_args] ? project.test.options[:java_args] : []) << BuildrPlus::Arez.arez_java_args
  project.test.options[:properties] = (project.test.options[:properties] ? project.test.options[:properties] : {}).merge(BuildrPlus::Arez.arez_test_options)

  BuildrPlus::Roles.merge_projects_with_role(project.test, :replicant_shared)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :replicant_qa_support)
end
