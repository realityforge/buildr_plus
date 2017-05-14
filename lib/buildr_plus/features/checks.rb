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

BuildrPlus::FeatureManager.feature(:checks) do |f|
  f.enhance(:ProjectExtension) do
    fixable_features = %w(oss gitignore gitattributes whitespace travis jenkins gems whitespace)
    features = fixable_features + %w(braid java assets generated_files)

    desc 'Perform basic checks on formats of local files'
    task 'checks:check' do
      features.each do |feature|
        if BuildrPlus::FeatureManager.activated?(feature.to_sym)
          task("#{feature}:check").invoke
        end
      end
      root_project = Buildr.projects[0].root_project
      if root_project.name.include?('-') && BuildrPlus::Artifacts.war?
        raise "Root project name '#{root_project.name}' has a '-' character and is configured to produce a war which can cause downstrem issues when deploying to GlassFish."
      end
      if BuildrPlus::FeatureManager.activated?(:appcache) && BuildrPlus::FeatureManager.activated?(:role_library)
        raise "Can not enable the BuildrPlus 'appcache' feature for libraries"
      end
      if BuildrPlus::FeatureManager.activated?(:gwt_cache_filter) && BuildrPlus::FeatureManager.activated?(:role_library)
        raise "Can not enable the BuildrPlus 'gwt_cache_filter' feature for libraries"
      end
      if BuildrPlus::FeatureManager.activated?(:timerstatus) && BuildrPlus::FeatureManager.activated?(:role_library)
        raise "Can not enable the BuildrPlus 'timerstatus' feature for libraries"
      end
    end

    desc 'Apply basic fixes on formats of local files'
    task 'checks:fix' do
      fixable_features.each do |feature|
        if BuildrPlus::FeatureManager.activated?(feature.to_sym)
          task("#{feature}:fix").invoke
        end
      end
    end
  end
end
