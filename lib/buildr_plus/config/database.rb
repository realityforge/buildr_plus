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
    class DatabaseConfig < Reality::BaseElement
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

      attr_accessor :restore_name
      attr_accessor :backup_name
      attr_accessor :backup_location

      def delete_backup_history_set?
        !@delete_backup_history.nil?
      end

      attr_writer :delete_backup_history

      def delete_backup_history?
        @delete_backup_history.nil? ? true : !!@delete_backup_history
      end

      def reindex_on_import_set?
        !@reindex_on_import.nil?
      end

      attr_writer :reindex_on_import

      def reindex_on_import?
        @reindex_on_import.nil? ? true : !!@reindex_on_import
      end

      def shrink_on_import_set?
        !@shrink_on_import.nil?
      end

      attr_writer :shrink_on_import

      def shrink_on_import?
        @shrink_on_import.nil? ? true : !!@shrink_on_import
      end

      def to_h
        data = {'delete_backup_history' => self.delete_backup_history?}
        data['instance'] = self.instance if self.instance
        data['restore_name'] = self.restore_name if self.restore_name
        data['backup_name'] = self.backup_name if self.backup_name
        data['backup_location'] = self.backup_location if self.backup_location
        data['reindex_on_import'] = self.reindex_on_import? if self.reindex_on_import_set?
        data['shrink_on_import'] = self.shrink_on_import? if self.shrink_on_import_set?
        data['delete_backup_history'] = self.delete_backup_history? if self.delete_backup_history_set?
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
