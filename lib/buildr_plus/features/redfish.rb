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

BuildrPlus::FeatureManager.feature(:redfish => [:config]) do |f|
  f.enhance(:Config) do
    attr_writer :local_domain

    def local_domain?
      @local_domain.nil? ? true : @local_domain
    end

    attr_writer :docker_domain

    def docker_domain?
      @docker_domain.nil? ? true : @docker_domain
    end

    def features
      if @features.nil?
        @features = []
        @features << :jms if BuildrPlus::FeatureManager.activated?(:jms)
      end
      @features
    end

    def system_property(domain, key, value)
      RedfishPlus.system_property(domain, key, value)
      domain.docker_run_args << "--env=#{key}=#{value}" if domain.dockerize?
    end

    def configure_system_settings(domain, environment)
      domain.environment_vars.each_pair do |key, default_value|
        value =
          if key == 'OPENMQ_HOST' && environment.broker?
            environment.broker.host.to_s
          elsif key == 'OPENMQ_PORT' && environment.broker?
            environment.broker.port.to_s
          elsif key == 'OPENMQ_ADMIN_USERNAME' && environment.broker?
            environment.broker.admin_username.to_s
          elsif key == 'OPENMQ_ADMIN_PASSWORD' && environment.broker?
            environment.broker.admin_password.to_s
          elsif environment.setting?(key)
            raise "Redfish domain with key #{domain.key} requires setting #{key} that is not specified in development configuration." unless environment.setting?(key)
            environment.settings[key] if environment.setting?(key)
          else
            nil
          end
        value ||= default_value
        raise "Redfish domain with key #{domain.key} requires setting #{key} that is not specified and can not be derived." if value.nil?
        system_property(domain, key, value)
      end
    end

    def configure_domain_for_environment(domain, environment)
      configure_system_settings(domain, environment)

      unless domain.docker_dns
        dns = BuildrPlus::Config.domain_environment_var(domain, 'DOCKER_DNS')
        domain.docker_dns = dns if dns
      end
    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'redfish'
    end

    before_define do |buildr_project|
      if buildr_project.ipr?
        environment = BuildrPlus::Config.environment_config

        local_domain_key = "local_#{buildr_project.name}"
        if BuildrPlus::Redfish.local_domain? && Redfish.domain_by_key?(buildr_project.name) && !Redfish.domain_by_key?(local_domain_key)
          Redfish.domain(local_domain_key, :extends => buildr_project.name) do |domain|
            RedfishPlus.setup_for_local_development(domain, :features => BuildrPlus::Redfish.features)
          end
          Redfish::Config.default_domain_key = local_domain_key
        end

        docker_domain_key = "docker_#{buildr_project.name}"
        if BuildrPlus::Redfish.local_domain? && Redfish.domain_by_key?(buildr_project.name) && !Redfish.domain_by_key?(docker_domain_key)
          Redfish.domain(docker_domain_key, :extends => buildr_project.name) do |domain|
            RedfishPlus.setup_for_docker(domain, :features => BuildrPlus::Redfish.features)
            RedfishPlus.deploy_application(domain, buildr_project.name, '/', "{{file:#{buildr_project.name}}}")
            if BuildrPlus::FeatureManager.activated?(:jms)
              raise "Redfish domain with key #{domain.key} requires broker configuration that is not specified in development configuration." unless environment.broker?
            end
          end
        end
      end
    end

    after_define do |buildr_project|
      if buildr_project.ipr?

        if BuildrPlus::FeatureManager.activated?(:domgen) && Redfish.domain_by_key?(buildr_project.name)
          domain = Redfish.domain_by_key(buildr_project.name)
          domain.pre_artifacts << buildr_project._("generated/domgen/#{buildr_project.name}/main/etc/#{buildr_project.name_as_class}.redfish.fragment.json")
          buildr_project.task(":#{domain.task_prefix}:pre_build" => ["#{buildr_project.name}:domgen:#{buildr_project.name}"])
        end

        Redfish.domains.each do |domain|
          if domain.dockerize? || domain.local?
            buildr_project.task(":#{domain.task_prefix}:config" => ["#{domain.task_prefix}:setup_env_vars"])

            buildr_project.task(":#{domain.task_prefix}:setup_env_vars") do
              BuildrPlus::Redfish.configure_domain_for_environment(domain, BuildrPlus::Config.environment_config)
            end
          end

          if domain.extends
            domain.version = buildr_project.version
            buildr_project.task(":#{domain.task_prefix}:pre_build" => ["#{Redfish.domain_by_key(domain.extends).task_prefix}:pre_build"])
          end
        end

        [:server, :all_in_one].each do |role|
          if BuildrPlus::Roles.project_with_role?(role) && Redfish.domain_by_key?("docker_#{buildr_project.name}")
            domain = Redfish.domain_by_key("docker_#{buildr_project.name}")
            server_project = Buildr.project(BuildrPlus::Roles.project_with_role(role).name)
            buildr_project.task(":#{domain.task_prefix}:pre_build" => [server_project.package(:war).to_s])
            domain.file(buildr_project.name, server_project.package(:war).to_s)
          end
        end

        unless BuildrPlus::Util.subprojects(buildr_project).any? { |p| p == "#{buildr_project.name}:domains" }
          buildr_project.instance_eval do
            desc 'Redfish Domain Definitions'
            define 'domains' do
              project.no_iml
              Redfish::Buildr.define_domain_packages
            end
          end
        end
      end
    end
  end
end
