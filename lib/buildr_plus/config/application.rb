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
    class ApplicationConfig < BuildrPlus::BaseElement
      def initialize(options = {}, &block)
        @environments = {}

        (options || {}).each_pair do |environment_key, config|
          environment(environment_key, config || {})
        end

        super({}, &block)
      end

      def environment_by_key?(key)
        !!@environments[key.to_s]
      end

      def environment_by_key(key)
        raise "Attempting to retrieve environment with key '#{key}' but no such environment exists." unless @environments[key.to_s]
        @environments[key.to_s]
      end

      def environments
        @environments.values
      end

      def environment(key, config = {}, &block)
        raise "Attempting to redefine environment with key '#{key}'." if @environments[key.to_s]
        config = config.dup
        @environments[key.to_s] = BuildrPlus::Config::EnvironmentConfig.new(key, config, &block)
      end

      def to_h
        results = {}
        environments.each do |environment|
          results[environment.key.to_s] = environment.to_h
        end
        results
      end

      def to_database_yml(options = {})
        jruby = options.key?(:jruby) ? !!options[:jruby] : defined?(JRUBY_VERSION)
        results = {}
        environments.each do |environment|
          environment.databases.each do |database|
            key = database.key.to_s == 'default' ? environment.key.to_s : "#{database.key}_#{environment.key}"
            results[key] = {}
            if BuildrPlus::FeatureManager.activated?(:rails)
              results[key]['ignore_elements'] = %w(adapter)
              results[key]['adapter'] = 'mssql' if BuildrPlus::Db.mssql?
            end
            results[key]['host'] = database.host
            results[key]['port'] = database.port
            results[key]['database'] = database.database
            results[key]['username'] = database.admin_username
            results[key]['password'] = database.admin_password
            if BuildrPlus::Db.mssql?
              results[key]['force_drop'] = true
              results[key]['timeout'] = 10000 unless jruby
              results[key]['restore_from'] = database.restore_from if database.restore_from
              results[key]['backup_location'] = database.backup_location if database.backup_location
              results[key]['instance_registry_key'] = database.instance_registry_key if database.instance_registry_key
            end

            if database.import_from
              import_key = database.key.to_s == 'default' ? 'import' : "#{database.key}_import"
              unless results[import_key]
                results[import_key] = {}
                if BuildrPlus::FeatureManager.activated?(:rails)
                  results[import_key]['ignore_elements'] = %w(adapter)
                  results[import_key]['adapter'] = 'mssql' if BuildrPlus::Db.mssql?
                end
                results[import_key]['host'] = database.host
                results[import_key]['port'] = database.port
                results[import_key]['database'] = database.import_from
                results[import_key]['username'] = database.admin_username
                results[import_key]['password'] = database.admin_password
                if BuildrPlus::Db.mssql?
                  results[import_key]['force_drop'] = true
                  results[import_key]['timeout'] = 10000 unless jruby
                end
              end
            end

            # This is to support having separate configuration during import process where the main
            # database is effectively development and all others are effectively the import from
            if environment.key.to_s == 'test'
              key = database.key.to_s == 'default' ? 'import_test' : "#{database.key}_import_test"
              results[key] = {}
              if BuildrPlus::FeatureManager.activated?(:rails)
                results[key]['ignore_elements'] = %w(adapter)
                results[key]['adapter'] = 'mssql' if BuildrPlus::Db.mssql?
              end
              results[key]['host'] = database.host
              results[key]['port'] = database.port
              results[key]['database'] = database.key.to_s == 'default' ? database.database : (database.import_from || database.database)
              results[key]['username'] = database.admin_username
              results[key]['password'] = database.admin_password
              if BuildrPlus::Db.mssql?
                results[key]['force_drop'] = true
                results[key]['timeout'] = 10000 unless jruby
                results[key]['restore_from'] = database.restore_from if database.restore_from
                results[key]['backup_location'] = database.backup_location if database.backup_location
                results[key]['instance_registry_key'] = database.instance_registry_key if database.instance_registry_key
              end
            end
          end
          if environment.ssrs?
            key = "ssrs_#{environment.key}"
            results[key] = {}
            results[key]['report_target'] = environment.ssrs.report_target.to_s
            results[key]['domain'] = environment.ssrs.domain.to_s
            results[key]['username'] = environment.ssrs.admin_username.to_s
            results[key]['password'] = environment.ssrs.admin_password.to_s
            results[key]['prefix'] = environment.ssrs.prefix.to_s
          end
        end
        results
      end
    end
  end
end
