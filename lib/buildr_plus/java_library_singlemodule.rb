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

require 'buildr_plus/java'

BuildrPlus::Dbt.library = true
BuildrPlus::Artifacts.library = true
BuildrPlus::Artifacts.war = false

BuildrPlus::Roles.default_role = :all_in_one_library
BuildrPlus::ExtensionRegistry.auto_activate!
