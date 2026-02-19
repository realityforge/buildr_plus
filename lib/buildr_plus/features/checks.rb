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
    desc 'Perform basic checks on formats of local files'
    task 'checks:check' do
      task('bazel:check').invoke
      task('braid:check').invoke
      task('generated_files:check').invoke
    end

    desc 'Apply basic fixes on formats of local files'
    task 'checks:fix' do
      task('bazel:fix').invoke
    end
  end
end
