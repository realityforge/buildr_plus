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

BuildrPlus::Roles.project('model', :roles => [:model], :parent => :container, :description => 'Persistent Entities, Messages and Data Structures')
BuildrPlus::Roles.project('model-qa-support', :roles => [:model_qa_support], :parent => :container, :description => 'Model Test Infrastructure')
BuildrPlus::Roles.project('server', :roles => [:server], :parent => :container, :description => 'Server Archive')

if BuildrPlus::FeatureManager.activated?(:gwt)
  BuildrPlus::Roles.project('gwt', :roles => [:gwt], :parent => :container, :description => 'GWT Library')
  BuildrPlus::Roles.project('gwt-qa-support', :roles => [:gwt_qa_support], :parent => :container, :description => 'GWT Test Infrastructure')
end

if BuildrPlus::FeatureManager.activated?(:soap)
  BuildrPlus::Roles.project('soap-client', :roles => [:soap_client], :parent => :container, :description => 'SOAP Client API')
  BuildrPlus::Roles.project('soap-qa-support', :roles => [:soap_qa_support], :parent => :container, :description => 'SOAP Test Infrastructure')
end

BuildrPlus::Roles.project('integration-qa-support', :roles => [:integration_qa_support], :parent => :container, :description => 'Integration Test Infrastructure')
BuildrPlus::Roles.project('integration-tests', :roles => [:integration_tests], :parent => :container, :description => 'Integration Tests')

BuildrPlus::ExtensionRegistry.auto_activate!
