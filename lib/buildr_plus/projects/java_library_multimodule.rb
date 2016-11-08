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

require 'buildr_plus/projects/_java_multimodule_common'

BuildrPlus::Dbt.library = true
BuildrPlus::Artifacts.library = true
BuildrPlus::Artifacts.war = false

base_directory = File.dirname(Buildr.application.buildfile.to_s)

if File.exist?("#{base_directory}/server")
  BuildrPlus::Roles.project('server', :roles => [:library], :parent => :container, :template => true, :description => 'Library Archive')
end
if File.exist?("#{base_directory}/server-qa-support")
  BuildrPlus::Roles.project('server-qa-support', :roles => [:library_qa_support], :parent => :container, :template => true, :description => 'Library Test Infrastructure')
end

require 'buildr_plus/projects/_activate'
