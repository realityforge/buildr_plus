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

BuildrPlus::FeatureManager.feature(:config) do |f|
  f.enhance(:Config) do
    attr_writer :application_config_location

    def application_config_location
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      "#{base_directory}/config/application.yml"
    end

    def application_config_example_location
      application_config_location.gsub(/\.yml$/, '.example.yml')
    end

    def application_config
      @application_config ||= load_application_config
    end

    attr_writer :environment

    def environment
      @environment || 'development'
    end

    def environment_config
      raise "Attempting to configuration for #{self.environment} environment which is not present." unless self.application_config.environment_by_key?(self.environment)
      self.application_config.environment_by_key(self.environment)
    end

    def domain_environment_var(domain, key, default_value = nil)
      domain_name = Redfish::Naming.uppercase_constantize(domain.name)
      scope = self.app_scope
      code = self.env_code

      return ENV["#{domain_name}_#{scope}_#{key}_#{code}"] if scope && ENV["#{domain_name}_#{scope}_#{key}_#{code}"]
      return ENV["#{domain_name}_#{key}_#{code}"] if ENV["#{domain_name}_#{key}_#{code}"]
      return ENV["#{scope}_#{key}_#{code}"] if scope && ENV["#{scope}_#{key}_#{code}"]

      ENV["#{scope}_#{key}_#{code}"] ||
        ENV["#{key}_#{code}"] ||
        ENV[key] ||
        default_value
    end

    def environment_var(key, default_value = nil)
      scope = self.app_scope
      code = self.env_code

      return ENV["#{scope}_#{key}_#{code}"] if scope && ENV["#{scope}_#{key}_#{code}"]

      ENV["#{key}_#{code}"] ||
        ENV[key] ||
        default_value
    end

    def user
      ENV['USER']
    end

    def app_scope
      ENV['APP_SCOPE']
    end

    def env_code
      if self.environment == 'development'
        'DEV'
      elsif self.environment == 'uat'
        'UAT'
      elsif self.environment == 'training'
        'TRN'
      elsif self.environment == 'ci'
        'CI'
      elsif self.environment == 'production'
        'PRD'
      else
        self.environment
      end
    end

    private

    def load_application_config
      if !File.exist?(self.application_config_location) && File.exist?(self.application_config_example_location)
        FileUtils.cp self.application_config_example_location, self.application_config_location
      end
      unless File.exist?(self.application_config_location)
        raise "Missing application configuration file at #{self.application_config_location}"
      end
      config = BuildrPlus::Config::ApplicationConfig.new(YAML::load(ERB.new(IO.read(self.application_config_location)).result))

      populate_configuration(config)

      ::Dbt.repository.configuration_data = config.to_database_yml if BuildrPlus::FeatureManager.activated?(:dbt)
      config
    end

    def populate_configuration(config)
      %w(development test).each do |environment_key|
        config.environment(environment_key) unless config.environment_by_key?(environment_key)
        populate_environment_configuration(config.environment_by_key(environment_key), false)
      end
      config.environments.each do |environment|
        unless %w(development test).include?(environment.key.to_s)
          populate_environment_configuration(environment, true)
        end
      end
    end

    def populate_environment_configuration(environment, check_only = false)
      populate_database_configuration(environment, check_only)
      populate_broker_configuration(environment, check_only)
      populate_ssrs_configuration(environment, check_only)
    end

    def populate_database_configuration(environment, check_only)
      if !BuildrPlus::FeatureManager.activated?(:dbt) && !environment.databases.empty?
        raise "Databases defined in application configuration but BuildrPlus facet 'dbt' not enabled"
      elsif BuildrPlus::FeatureManager.activated?(:dbt)
        # Ensure all databases are registered in dbt
        environment.databases.each do |database|
          unless ::Dbt.database_for_key?(database.key)
            raise "Database '#{database.key}' defined in application configuration but has not been defined as a dbt database"
          end
        end
        # Create database configurations if in Dbt but configuration does not already exist
        ::Dbt.repository.database_keys.each do |database_key|
          environment.database(database_key) unless environment.database_by_key?(database_key)
        end unless check_only

        scope = self.app_scope
        buildr_project = if ::Buildr.application.current_scope.size > 0
          ::Buildr.project(::Buildr.application.current_scope.join(':')) rescue nil
        else
          Buildr.projects[0]
        end

        environment.databases.each do |database|
          dbt_database = ::Dbt.database_for_key(database.key)
          dbt_imports = !dbt_database.imports.empty? || (dbt_database.packaged? && dbt_database.extra_actions.any?{|a| a.to_s =~ /import/})
          short_name = BuildrPlus::Naming.uppercase_constantize(database.key.to_s == 'default' ? buildr_project.root_project.name : database.key.to_s)
          database.database = "#{user || 'NOBODY'}#{scope.nil? ? '' : "_#{scope}"}_#{short_name}_#{self.env_code}" unless database.database
          database.import_from = "PROD_CLONE_#{short_name}" unless database.import_from || !dbt_imports
          database.host = environment_var('DB_SERVER_HOST') unless database.host
          database.port = environment_var('DB_SERVER_PORT', database.port) unless database.port_set?
          database.admin_username = environment_var('DB_SERVER_USERNAME') unless database.admin_username
          database.admin_password = environment_var('DB_SERVER_PASSWORD') unless database.admin_password

          if database.is_a?(BuildrPlus::Config::MssqlDatabaseConfig)
            database.delete_backup_history = environment_var('DB_SERVER_DELETE_BACKUP_HISTORY', 'true') unless database.delete_backup_history_set?
            database.instance = environment_var('DB_SERVER_INSTANCE', '') unless database.instance
          end

          raise "Configuration for database key #{database.key} is missing host attribute and can not be derived from environment variable DB_SERVER_HOST" unless database.host
          raise "Configuration for database key #{database.key} is missing admin_username attribute and can not be derived from environment variable DB_SERVER_USERNAME" unless database.admin_username
          raise "Configuration for database key #{database.key} is missing admin_password attribute and can not be derived from environment variable DB_SERVER_PASSWORD" unless database.admin_password
          raise "Configuration for database key #{database.key} specifies import_from but dbt defines no import for database" if database.import_from && !dbt_imports
        end
      end
    end

    def populate_ssrs_configuration(environment, check_only)
      if !BuildrPlus::FeatureManager.activated?(:rptman) && environment.ssrs?
        raise "Ssrs defined in application configuration but BuildrPlus facet 'rptman' not enabled"
      elsif BuildrPlus::FeatureManager.activated?(:rptman) && !environment.ssrs? && !check_only
        endpoint = BuildrPlus::Config.environment_var('RPTMAN_ENDPOINT')
        domain = BuildrPlus::Config.environment_var('RPTMAN_DOMAIN')
        username = BuildrPlus::Config.environment_var('RPTMAN_USERNAME')
        password = BuildrPlus::Config.environment_var('RPTMAN_PASSWORD')
        raise "Ssrs not defined in application configuration or environment but BuildrPlus facet 'rptman' enabled" unless endpoint && domain && username && password
        environment.ssrs(:report_target => endpoint, :domain => domain, :username => username, :password => password)
      end
    end

    def populate_broker_configuration(environment, check_only)
      if !BuildrPlus::FeatureManager.activated?(:jms) && environment.broker?
        raise "Broker defined in application configuration but BuildrPlus facet 'jms' not enabled"
      elsif BuildrPlus::FeatureManager.activated?(:jms) && !environment.broker? && !check_only
        host = BuildrPlus::Config.environment_var('OPENMQ_HOST')
        raise "Broker not defined in application configuration or environment but BuildrPlus facet 'jms' enabled" unless host

        # The following are the default settings for a default install of openmq
        port = BuildrPlus::Config.environment_var('OPENMQ_PORT', '7676')
        username = BuildrPlus::Config.environment_var('OPENMQ_ADMIN_USERNAME', 'admin')
        password = BuildrPlus::Config.environment_var('OPENMQ_ADMIN_PASSWORD', 'admin')

        environment.broker(:host => host, :port => port, :admin_username => username, :admin_password => password)
      end
    end
  end
  f.enhance(:ProjectExtension) do
    after_define do |project|

      if project.ipr?
        desc 'Generate a complete application configuration from context'
        project.task(':config:expand_application_yml') do
          filename = project._('generated/buildr_plus/config/application.yml')
          info("Expanding application configuration to #{filename}")
          FileUtils.mkdir_p File.dirname(filename)
          File.open(filename, 'wb') do |file|
            file.write BuildrPlus::Config.application_config.to_h.to_yaml
          end
          database_filename = project._('generated/buildr_plus/config/database.yml')
          info("Expanding database configuration to #{database_filename}")
          File.open(database_filename, 'wb') do |file|
            file.write BuildrPlus::Config.application_config.to_database_yml.to_yaml
          end
        end
      end
    end
  end
end
