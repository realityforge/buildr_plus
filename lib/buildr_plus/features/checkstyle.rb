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
        'au.com.stocksoftware.checkstyle:checkstyle:xml:1.7'
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
        checkstyle_dir = project._('etc/checkstyle')
        if ::File.exist?(checkstyle_dir)
          project.checkstyle.config_directory = checkstyle_dir
          project.checkstyle.configuration_artifact = CheckstyleConfig.checkstyle_rules
        end
      end
    end
  end
end
