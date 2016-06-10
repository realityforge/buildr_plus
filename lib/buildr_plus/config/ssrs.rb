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

module BuildrPlus #nodoc
  module Config #nodoc
    class SsrsConfig < BuildrPlus::BaseElement
      attr_accessor :report_target
      attr_accessor :domain
      attr_accessor :admin_username
      attr_accessor :admin_password
      attr_accessor :prefix

      def to_h
        {
          'report_target' => self.report_target || '',
          'domain' => self.domain || '',
          'admin_username' => self.admin_username || '',
          'admin_password' => self.admin_password || '',
          'prefix' => self.prefix || '',
        }
      end
    end
  end
end
