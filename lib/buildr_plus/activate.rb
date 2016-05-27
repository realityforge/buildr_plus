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
  projects = BuildrPlus::Roles.projects.select { |p| !p.template? }
  projects[0].roles << BuildrPlus::Roles.default_role if projects.size == 1 && projects[0].roles.empty?
end

BuildrPlus::Roles.define_top_level_projects

# Force the materialization of projects so the
# redfish tasks config has been set up
Buildr.projects
Redfish::Buildr.define_tasks_for_domains if BuildrPlus::FeatureManager.activated?(:redfish)
