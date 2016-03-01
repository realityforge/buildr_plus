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
  class CheckstyleConfig
    class << self
      def default_checkstyle_rules
        'au.com.stocksoftware.checkstyle:checkstyle:xml:1.8'
      end

      def checkstyle_rules
        @checkstyle_rules || self.default_checkstyle_rules
      end

      def checkstyle_rules=(checkstyle_rules)
        @checkstyle_rules = checkstyle_rules
      end
    end
  end
  module CheckstyleExtension
    module ProjectExtension
      include Extension
      BuildrPlus::ExtensionRegistry.register(self)

      before_define do |project|
        project.checkstyle.config_directory = project._('etc/checkstyle')
        project.checkstyle.configuration_artifact = CheckstyleConfig.checkstyle_rules

        import_control_present = File.exist?(project.checkstyle.import_control_file)

        unless File.exist?(project.checkstyle.suppressions_file)
          dir = File.expand_path(File.dirname(__FILE__))
          project.checkstyle.suppressions_file =
            import_control_present ?
              "#{dir}/checkstyle_suppressions.xml" :
              "#{dir}/checkstyle_suppressions_no_import_control.xml"
        end

        unless import_control_present
          project.checkstyle.properties['checkstyle.import-control.file'] = ''
        end
      end
    end
  end
end
