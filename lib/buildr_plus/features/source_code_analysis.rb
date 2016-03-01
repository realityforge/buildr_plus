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

module BuildrPlus
  class SourceCodeAnalysisConfig
    class << self
      attr_writer :findbugs_enabled

      def findbugs_enabled?
        @findbugs_enabled.nil? ? true : !!@findbugs_enabled
      end

      attr_writer :pmd_enabled

      def pmd_enabled?
        @pmd_enabled.nil? ? true : !!@pmd_enabled
      end

      attr_writer :jdepend_enabled

      def jdepend_enabled?
        @jdepend_enabled.nil? ? true : !!@jdepend_enabled
      end
    end
  end

  module SourceCodeAnalysisExtension
    module ProjectExtension
      include Extension
      BuildrPlus::ExtensionRegistry.register(self)

      before_define do |project|
        if project.ipr?
          project.jdepend.enabled = true if BuildrPlus::SourceCodeAnalysisConfig.jdepend_enabled?
          project.findbugs.enabled = true if BuildrPlus::SourceCodeAnalysisConfig.findbugs_enabled?
          project.pmd.enabled = true if BuildrPlus::SourceCodeAnalysisConfig.pmd_enabled?
        end
      end

      after_define do |project|
        if project.ipr?
          project_names = Buildr.projects(:scope => project.name).collect { |p| p.name }

          non_soap_projects = project_names.select { |p| !(p =~ /.*\:soap-client$/) }
          project.jdepend.additional_project_names = project_names if project.jdepend.enabled?
          project.findbugs.additional_project_names = non_soap_projects if project.findbugs.enabled?
          project.pmd.additional_project_names = non_soap_projects if project.pmd.enabled?
          project.checkstyle.additional_project_names = project_names if project.checkstyle.enabled?
        end
      end
    end
  end
end
