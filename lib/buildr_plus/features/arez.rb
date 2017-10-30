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

BuildrPlus::FeatureManager.feature(:arez) do |f|
  f.enhance(:Config) do

    def arez_test_options
      {
        'braincheck.dynamic_provider' => 'true',
        'braincheck.environment' => 'development',
        'arez.dynamic_provider' => 'true',
        'arez.environment' => 'development'
      }
    end

    def arez_java_args
      %w(-ea)
    end
  end
end