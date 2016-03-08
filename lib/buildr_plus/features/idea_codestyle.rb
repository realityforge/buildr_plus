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

BuildrPlus::FeatureManager.feature(:idea_codestyle) do |f|
  f.enhance(:Config) do
    def default_codestyle
      'au.com.stocksoftware.idea.codestyle:idea-codestyle:xml:1.3'
    end

    def codestyle
      @codestyle || self.default_codestyle
    end

    attr_writer :codestyle
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|
      project.ipr.add_component_from_artifact(BuildrPlus::IdeaCodestyle.codestyle) if project.ipr?
    end
  end
end
