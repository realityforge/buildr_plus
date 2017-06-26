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

BuildrPlus::FeatureManager.feature(:artifact_assets) do |f|
  f.enhance(:ProjectExtension) do
    first_time do
      desc 'Generate assets and move them to idea artifact'
      task 'assets:artifact' => %w(assets) do
        Buildr.projects.each do |project|
          target = project.root_project._(:artifacts, project.root_project.name)
          mkdir_p target
          project.assets.paths.each do |asset|
            next if asset.to_s =~ /generated\/gwt\// && BuildrPlus::FeatureManager.activated?(:gwt)
            file(asset.to_s).invoke
            cp_r Dir["#{asset}/./*"], "#{target}/"
          end
        end
      end
    end
  end
end
