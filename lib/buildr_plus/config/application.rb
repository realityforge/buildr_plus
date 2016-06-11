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

        options.each_pair do |environment_key, config|
          environment(environment_key, config)
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

      def to_database_yml
        results = {}
        environments.each do |environment|
          environment.databases.each do |database|
            database
            key = database.key.to_s == 'default' ? environment.key.to_s : "#{database.key}_#{environment.key}"
            results[key] = {}
            results[key]['host'] = database.host
            results[key]['port'] = database.port
            results[key]['database'] = database.database
            results[key]['username'] = database.admin_username
            results[key]['password'] = database.admin_password
            results[key]['timeout'] = 10000 unless defined?(JRUBY_VERSION)

            if database.import_from
              import_key = database.key.to_s == 'default' ? 'import' : "#{database.key}_import"
              unless results[import_key]
                results[import_key] = {}
                results[import_key]['host'] = database.host
                results[import_key]['port'] = database.port
                results[import_key]['database'] = database.import_from
                results[import_key]['username'] = database.admin_username
                results[import_key]['password'] = database.admin_password
                results[key]['timeout'] = 10000 unless defined?(JRUBY_VERSION)
              end
            end
          end
        end
        results
      end
    end
  end
end
