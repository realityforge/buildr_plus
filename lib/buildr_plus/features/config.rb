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

      ENV["#{domain_name}_#{scope}_#{key}_#{code}"] ||
        ENV["#{domain_name}_#{key}_#{code}"] ||
        ENV["#{scope}_#{key}_#{code}"] ||
        ENV["#{key}_#{code}"] ||
        ENV[key] ||
        default_value
    end

    def environment_var(key, default_value = nil)
      scope = self.app_scope
      code = self.env_code

      ENV["#{scope}_#{key}_#{code}"] ||
        ENV["#{key}_#{code}"] ||
        ENV[key] ||
        default_value
    end

    def app_scope
      ENV['APP_SCOPE'] || 'NONE'
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

      config
    end

    def populate_configuration(config)
      config.environment(self.environment) unless config.environment_by_key?(self.environment)
      environment = config.environment_by_key(self.environment)

      populate_environment_configuration(environment)
    end

    def populate_environment_configuration(environment)
      populate_broker_configuration(environment)
      populate_ssrs_configuration(environment)
    end

    def populate_ssrs_configuration(environment)
      if !BuildrPlus::FeatureManager.activated?(:rptman) && environment.ssrs?
        raise "Ssrs defined in application configuration but BuildrPlus facet 'rptman' not enabled"
      elsif BuildrPlus::FeatureManager.activated?(:rptman) && !environment.ssrs?
        endpoint = BuildrPlus::Config.environment_var('RPTMAN_ENDPOINT')
        domain = BuildrPlus::Config.environment_var('RPTMAN_DOMAIN')
        username = BuildrPlus::Config.environment_var('RPTMAN_USERNAME')
        password = BuildrPlus::Config.environment_var('RPTMAN_PASSWORD')
        raise "Ssrs not defined in application configuration or environment but BuildrPlus facet 'rptman' enabled" unless endpoint && domain && username && password
        environment.ssrs(:report_target => endpoint, :domain => domain, :username => username, :password => password)
      end
    end

    def populate_broker_configuration(environment)
      if !BuildrPlus::FeatureManager.activated?(:jms) && environment.broker?
        raise "Broker defined in application configuration but BuildrPlus facet 'jms' not enabled"
      elsif BuildrPlus::FeatureManager.activated?(:jms) && !environment.broker?
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
        end
      end
    end
  end
end
