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
    features = fixable_features + %w(ruby braid)

    desc 'Perform basic checks on formats of local files'
    task 'checks:check' do
      features.each do |feature|
        if BuildrPlus::FeatureManager.activated?(feature.to_sym)
          task("#{feature}:check").invoke
        end
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
