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

require 'buildr_plus/projects/_java'

base_directory = File.dirname(Buildr.application.buildfile.to_s)
BuildrPlus::FeatureManager.activate_features([:less]) if File.exist?("#{base_directory}/#{BuildrPlus::Less.default_less_path}")

BuildrPlus::Roles.default_role = :all_in_one

require 'buildr_plus/projects/_activate'
