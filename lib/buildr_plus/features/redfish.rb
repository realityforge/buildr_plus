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
        @features << :jdbc if BuildrPlus::FeatureManager.activated?(:db)
      end
      @features
    end

    def system_property(domain, key, value)
      RedfishPlus.system_property(domain, key, value)
      domain.docker_run_args << "--env=#{key}=#{value}" if domain.dockerize? && value != ''
    end

    def configure_system_settings(domain, environment)
      properties = build_property_set(domain, environment)
      domain.environment_vars.each_pair do |key, default_value|
        value = properties[key] || default_value
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

    def build_property_set(domain, environment)
      properties = {}

      if environment.broker?
        properties['OPENMQ_HOST'] = as_ip(environment.broker.host.to_s)
        properties['OPENMQ_PORT'] = environment.broker.port.to_s
        properties['OPENMQ_ADMIN_USERNAME'] = environment.broker.admin_username.to_s
        properties['OPENMQ_ADMIN_PASSWORD'] = environment.broker.admin_password.to_s
      end

      constant_prefix = BuildrPlus::Naming.uppercase_constantize(domain.name)

      environment.databases.each do |database|
        if BuildrPlus::FeatureManager.activated?(:timerstatus) && database.key.to_s == 'timers'
          properties['TIMERS_DB_HOST'] = as_ip(database.host.to_s)
          properties['TIMERS_DB_PORT'] = database.port.to_s
          properties['TIMERS_DB_DATABASE'] = database.database.to_s
          properties['TIMERS_DB_USERNAME'] = database.admin_username.to_s
          properties['TIMERS_DB_PASSWORD'] = database.admin_password.to_s
        else
          prefix =
            database.key.to_s == 'default' ?
              constant_prefix :
              "#{constant_prefix}_#{BuildrPlus::Naming.uppercase_constantize(database.key)}"

          properties["#{prefix}_DB_HOST"] = as_ip(database.host.to_s)
          properties["#{prefix}_DB_PORT"] = database.port.to_s
          properties["#{prefix}_DB_DATABASE"] = database.database.to_s
          properties["#{prefix}_DB_USERNAME"] = database.admin_username.to_s
          properties["#{prefix}_DB_PASSWORD"] = database.admin_password.to_s
        end
      end

      properties.merge!(environment.settings)

      properties
    end

    def as_ip(name)
      return name if valid_v4?(name)

      # First collect all the entries from local resolve.conf
      addresses = Resolv.getaddresses(name).select { |a| valid_v4?(a) }.collect { |a| a == '127.0.0.1' ? host_ip : a }

      # Then use configured DNS server if any

      if ENV['DOCKER_DNS']
        addresses += Resolv::DNS.new(:nameserver => [ENV['DOCKER_DNS']]).
          getaddresses(name).
          collect { |a| a.address.unpack('CCCC').join('.') }
      end

      return addresses[0] unless addresses.empty?
      raise "Unable to determine ip address of #{name}. Are you connected to the correct networks?"
    end

    def host_ip
      return ENV['HOST_IP_ADDRESS'] if ENV['HOST_IP_ADDRESS']

      # Old versions of jruby do not support this method on Socket
      if Socket.respond_to?(:ip_address_list)
        address_list = Socket.ip_address_list.select { |a| a.ipv4? && a.inspect_sockaddr != '127.0.0.1' }.collect { |a| a.inspect_sockaddr }

        return address_list[0] unless address_list.empty?
      end

      raise 'Unable to determine host address to use in place of 127.0.0.1, please specify environment variable HOST_IP_ADDRESS'
    end

    def valid_v4?(addr)
      if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ addr
        return $~.captures.all? { |i| i.to_i < 256 }
      end
      return false
    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'redfish'
    end

    before_define do |buildr_project|
      if buildr_project.ipr?
        if Redfish.domain_by_key?(buildr_project.name)
          domain = Redfish.domain_by_key(buildr_project.name)
          if BuildrPlus::FeatureManager.activated?(:db)
            if BuildrPlus::Db.mssql?
              library = ::Buildr.artifact(BuildrPlus::Libs.jtds[0])
              RedfishPlus.add_library_from_path(domain, 'jtds', library.to_s, true)
              buildr_project.task(":#{domain.task_prefix}:pre_build" => [library])
            end
            if BuildrPlus::Db.pgsql?
              library = ::Buildr.artifact(BuildrPlus::Libs.postgresql[0])
              RedfishPlus.add_library_from_path(domain, 'postgresql', library.to_s, true)
              buildr_project.task(":#{domain.task_prefix}:pre_build" => [library])
              if BuildrPlus::FeatureManager.activated?(:geolatte)
                library = ::Buildr.artifact(BuildrPlus::Libs.postgis[0])
                RedfishPlus.add_library_from_path(domain, 'postgis', library.to_s, true)
                buildr_project.task(":#{domain.task_prefix}:pre_build" => [library])
              end
            end
          end
          if BuildrPlus::FeatureManager.activated?(:timerstatus)
            domain.add_pre_artifacts(BuildrPlus::Libs.glassfish_timers_domain)
          end
          if BuildrPlus::FeatureManager.activated?(:domgen) && !BuildrPlus::FeatureManager.activated?(:rails)
            domain.pre_artifacts << buildr_project._("generated/domgen/#{buildr_project.name}/main/etc/#{buildr_project.name_as_class}.redfish.fragment.json")
            buildr_project.task(":#{domain.task_prefix}:pre_build" => ["#{buildr_project.name}:domgen:#{buildr_project.name}"])
          end
        end

        if BuildrPlus::Redfish.local_domain? && Redfish.domain_by_key?(buildr_project.name) && !Redfish.domain_by_key?('local')
          Redfish.domain('local', :extends => buildr_project.name) do |domain|
            RedfishPlus.setup_for_local_development(domain, :features => BuildrPlus::Redfish.features)
          end
          Redfish::Config.default_domain_key = 'local'
        end

        if BuildrPlus::Redfish.local_domain? && Redfish.domain_by_key?(buildr_project.name) && !Redfish.domain_by_key?('docker')
          Redfish.domain('docker', :extends => buildr_project.name) do |domain|
            RedfishPlus.setup_for_docker(domain, :features => BuildrPlus::Redfish.features)
            RedfishPlus.deploy_application(domain, buildr_project.name, '/', "{{file:#{buildr_project.name}}}")
          end
        end
      end
    end

    after_define do |buildr_project|
      if buildr_project.ipr?

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

        if Redfish.domain_by_key?('docker')
          domain = Redfish.domain_by_key('docker')
          prj = nil
          prj = buildr_project if buildr_project.roles.empty?
          [:server, :all_in_one].each do |role|
            prj = Buildr.project(BuildrPlus::Roles.project_with_role(role).name) if BuildrPlus::Roles.project_with_role?(role)
          end

          if prj
            buildr_project.task(":#{domain.task_prefix}:pre_build" => [prj.package(:war).to_s])
            domain.file(buildr_project.name, prj.package(:war).to_s)
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
