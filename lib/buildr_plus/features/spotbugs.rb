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

BuildrPlus::FeatureManager.feature(:spotbugs) do |f|
  f.enhance(:Config) do
    attr_accessor :additional_project_names
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr_plus/patches/spotbugs'
    end

    before_define do |project|
      if project.ipr?
        project.spotbugs.enabled = true
        project.spotbugs.config_directory = project._(:etc, :spotbugs)
      end
    end

    after_define do |project|
      if project.ipr?
        project.spotbugs.additional_project_names =
          BuildrPlus::Spotbugs.additional_project_names ||
            BuildrPlus::Util.subprojects(project).select {|p| !(p =~ /.*:soap-client$/)}
      end
    end
  end
end
