module BuildrPlus
  class DbConfig
    class << self
      def default_codestyle
        'au.com.stocksoftware.idea.codestyle:idea-codestyle:xml:1.3'
      end

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
