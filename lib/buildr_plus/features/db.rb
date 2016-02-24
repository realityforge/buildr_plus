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
  class DbConfig
    class << self
      def pg_defined?
        unless @pg_loaded
          @pg_loaded = true
          begin
            require 'pg'
          rescue LoadError
            # Ignored
          end
        end
        Object.const_defined?('PG')
      end

      def tiny_tds_defined?
        unless @tiny_tds_loaded
          @tiny_tds_loaded = true
          begin
            require 'tiny_tds'
          rescue LoadError
            # Ignored
          end
        end
        Object.const_defined?('TinyTds')
      end

      def valid_db_types
        [:pgsql, :mssql]
      end

      def db_type=(db_type)
        raise "db_type '#{db_type}' is invalid. Expected values #{self.valid_db_types.inspect}" unless self.valid_db_types.include?(db_type)
        @db_type = db_type
      end

      def db_type
        return @db_type unless @db_type.nil?
        return :mssql if tiny_tds_defined? && !pg_defined?
        return :pgsql if !tiny_tds_defined? && pg_defined?

        return :mssql if ENV['DB_TYPE'].nil? || ENV['DB_TYPE'] == 'mssql'
        return :pgsql if ENV['DB_TYPE'] == 'pg'

        raise 'Unable to determine database type'
      end

      def mssql?
        self.db_type == :mssql
      end

      def pgsql?
        self.db_type == :pgsql
      end
    end
  end
end
