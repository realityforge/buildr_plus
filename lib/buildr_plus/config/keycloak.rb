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
    class KeycloakConfig < BuildrPlus::BaseElement
      attr_accessor :base_url
      attr_accessor :public_key
      attr_accessor :admin_username
      attr_accessor :admin_password
      attr_accessor :realm

      def to_h
        config = {
          'base_url' => self.base_url || '',
          'public_key' => self.public_key || '',
          'admin_password' => self.admin_password || '',
          'realm' => self.realm || '',
        }
        config['admin_username'] = self.admin_username if self.admin_username
        config
      end
    end
  end
end
