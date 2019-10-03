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

if BuildrPlus::Roles.default_role
  projects = BuildrPlus::Roles.projects.select {|p| !p.template?}
  projects[0].roles << BuildrPlus::Roles.default_role if projects.size == 1 && projects[0].roles.empty?
end

BuildrPlus::Roles.define_top_level_projects

# Force the materialization of projects so the
# redfish tasks config has been set up
Buildr.projects

Buildr.projects.each do |project|
  if project.iml?
    project_deps = Buildr.artifacts([project.iml.main_dependencies]).collect do |d|
      Buildr.projects(:no_invoke => true).select do |other_project|
        [other_project.packages, other_project.compile.target, other_project.resources.target, other_project.test.compile.target, other_project.test.resources.target].flatten.
          detect {|artifact| artifact.to_s == d.to_s}
      end
    end.flatten

    project.iml.main_dependencies.delete_if do |candidate|
      project_deps.any? {|p| Buildr.artifacts([p.compile.dependencies]).any? {|artifact| candidate.to_s == artifact.to_s}}
    end
  end
  if project.ipr?
    Buildr.projects(:no_invoke => true).each do |other|
      unless other.test.compile.sources.empty? || !other.iml? || other.idea_testng_configuration_created?
        project.ipr.add_testng_configuration(other.iml.name,
                                             :module => other.iml.name,
                                             :jvm_args => BuildrPlus::Testng.default_testng_args(project, nil).join(' '))
      end
    end
  end
end

Redfish::Buildr.define_tasks_for_domains if BuildrPlus::FeatureManager.activated?(:redfish)
