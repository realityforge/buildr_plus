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
    class DatabaseConfig < BuildrPlus::BaseElement
      attr_reader :key
      attr_accessor :database
      attr_accessor :host
      attr_writer :port
      attr_accessor :admin_username
      attr_accessor :admin_password
      attr_accessor :import_from

      def initialize(key, options = {}, &block)
        @key = key
        super(options, &block)
      end

      def port_set?
        !@port.nil?
      end

      def to_h
        data = {}
        data['database'] = self.database if self.database
        data['host'] = self.host if self.host
        data['port'] = self.port if self.port
        data['admin_username'] = self.admin_username if self.admin_username
        data['admin_password'] = self.admin_password if self.admin_password
        data['import_from'] = self.import_from if self.import_from
        data
      end
    end

    class MssqlDatabaseConfig < DatabaseConfig
      def port
        @port || 1433
      end

      attr_accessor :instance

      attr_writer :delete_backup_history

      attr_accessor :restore_from

      attr_accessor :backup_location

      attr_accessor :instance_registry_key

      def delete_backup_history_set?
        !@delete_backup_history.nil?
      end

      def delete_backup_history?
        @delete_backup_history.nil? ? true : !!@delete_backup_history
      end

      def to_h
        data = {'delete_backup_history' => self.delete_backup_history?}
        data['instance'] = self.instance if self.instance
        data['restore_from'] = self.restore_from if self.restore_from
        data['backup_location'] = self.backup_location if self.backup_location
        data['instance_registry_key'] = self.instance_registry_key if self.instance_registry_key
        super.merge(data)
      end
    end

    class PostgresDatabaseConfig < DatabaseConfig
      def port
        @port || 5432
      end
    end
  end
end
