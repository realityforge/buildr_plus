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

BuildrPlus::Roles.role(:gwt_qa, :requires => [:role_gwt_qa_support]) do

  project.publish = false

  project.test.options[:properties] = (project.test.options[:properties] ? project.test.options[:properties] : {}).merge(BuildrPlus::Gwt.gwt_test_options) if BuildrPlus::FeatureManager.activated?(:gwt)
  if BuildrPlus::FeatureManager.activated?(:arez)
    project.test.options[:properties] = (project.test.options[:properties] ? project.test.options[:properties] : {}).merge(BuildrPlus::Arez.arez_test_options)
    if BuildrPlus::FeatureManager.activated?(:replicant)
      project.test.options[:properties] = (project.test.options[:properties] ? project.test.options[:properties] : {}).merge(BuildrPlus::Replicant.replicant_test_options)
    end
  end

  (compile.options.processor_path ||= []) << BuildrPlus::Deps.gwt_qa_processorpath
  (test.compile.options.processor_path ||= []) << BuildrPlus::Deps.gwt_qa_processorpath

  BuildrPlus::Roles.merge_projects_with_role(project.test, :gwt)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :gwt_qa_support)
end
