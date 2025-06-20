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

BuildrPlus::FeatureManager.activate_features([:less]) if File.exist?("#{base_directory}/server/#{BuildrPlus::Less.default_less_path}")

if File.exist?("#{base_directory}/shared")
  BuildrPlus::Roles.project('shared', :roles => [:shared], :parent => :container, :template => true, :description => 'Shared Components')
end

if File.exist?("#{base_directory}/model") || File.exist?("#{base_directory}/model-qa-support")
  BuildrPlus::Roles.project('model', :roles => [:model], :parent => :container, :template => true, :description => 'Persistent Entities, Messages and Data Structures')
  BuildrPlus::Roles.project('model-qa-support', :roles => [:model_qa_support], :parent => :container, :template => true, :description => 'Model Test Infrastructure')
end
if File.exist?("#{base_directory}/model-qa")
  BuildrPlus::Roles.project('model-qa', :roles => [:model_qa], :parent => :container, :template => true, :description => 'Model Tests')
end

if File.exist?("#{base_directory}/gwt") || File.exist?("#{base_directory}/gwt-qa-support") || File.exist?("#{base_directory}/gwt-qa")
  BuildrPlus::Roles.project('gwt', :roles => [:gwt], :parent => :container, :template => true, :description => 'GWT Library')
  BuildrPlus::Roles.project('gwt-qa-support', :roles => [:gwt_qa_support], :parent => :container, :template => true, :description => 'GWT Test Infrastructure')
  if File.exist?("#{base_directory}/gwt-qa")
    BuildrPlus::Roles.project('gwt-qa', :roles => [:gwt_qa], :parent => :container, :template => true, :description => 'GWT Model Tests')
  end
end

if BuildrPlus::FeatureManager.activated?(:soap)
  BuildrPlus::Roles.project('soap-client', :roles => [:soap_client], :parent => :container, :template => true, :description => 'SOAP Client API')
end

BuildrPlus::Roles.default_role = :container
