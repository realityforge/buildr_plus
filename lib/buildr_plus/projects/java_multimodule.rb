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

base_directory = File.dirname(Buildr.application.buildfile.to_s)

BuildrPlus::Roles.project('server', :roles => [:server], :parent => :container, :template => true, :description => 'Server Archive')

if File.exist?("#{base_directory}/user-experience")
  BuildrPlus::Roles.project('user-experience', :roles => [:user_experience], :parent => :container, :template => true, :description => 'GWT Client-side UI')

  BuildrPlus::FeatureManager.activate_features([:appcache]) unless BuildrPlus::FeatureManager.activated?(:appcache)
  BuildrPlus::FeatureManager.activate_features([:gwt_cache_filter]) unless BuildrPlus::FeatureManager.activated?(:gwt_cache_filter)
end

if File.exist?("#{base_directory}/selenium-tests")
  BuildrPlus::Roles.project('selenium-tests', :roles => [:selenium_tests], :parent => :container, :template => true, :description => 'Selenium Tests')
end

require 'buildr_plus/projects/_activate'
