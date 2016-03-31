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

BuildrPlus::FeatureManager.feature(:pmd) do |f|
  f.enhance(:Config) do
    def default_pmd_rules
      'au.com.stocksoftware.pmd:pmd:xml:1.2'
    end

    def pmd_rules
      @pmd_rules || self.default_pmd_rules
    end

    attr_writer :pmd_rules

    attr_accessor :additional_project_names
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr/pmd'
    end

    before_define do |project|
      project.pmd.enabled = true if project.ipr?
    end

    after_define do |project|
      if project.ipr?
        project.pmd.rule_set_artifacts << BuildrPlus::Pmd.pmd_rules
        # TODO: Use project.pmd.exclude_paths rather than excluding projects

        project.pmd.additional_project_names =
          BuildrPlus::Pmd.additional_project_names ||
            BuildrPlus::Util.subprojects(project).select { |p| !(p =~ /.*\:soap-client$/) }
      end
    end
  end
end
