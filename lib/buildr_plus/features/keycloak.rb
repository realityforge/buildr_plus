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

module BuildrPlus::Keycloak
  class KeycloakRemoteClient < Reality::BaseElement
    def initialize(client_type, options = {})
      @client_type = client_type
      super(options)
    end

    attr_reader :client_type
    attr_accessor :application

    def default?
      self.client_type == self.application
    end

    def redfish_config_prefix
      prefix = "#{Reality::Naming.uppercase_constantize(self.application || BuildrPlus::Keycloak.root_project.name)}_"
      suffix = self.default? ? '' : "_#{Reality::Naming.uppercase_constantize(self.client_type)}"
      "#{prefix}KEYCLOAK_REMOTE_CLIENT#{suffix}"
    end
  end

  class KeycloakClient < Reality::BaseElement
    def initialize(client_type, options = {})
      @client_type = client_type
      @artifact = nil
      super(options)
    end

    attr_reader :client_type

    # Buildr application representing keycloak configuration
    attr_accessor :artifact

    attr_writer :application

    # The application that this client belongs to.
    # Defaults to client_type if an external client and application not specified
    def application
      @application || (external? ? self.client_type : nil)
    end

    def external?
      !@artifact.nil?
    end

    def default?
      BuildrPlus::Keycloak.root_project.name == self.client_type
    end

    attr_writer :name

    def name(environment = BuildrPlus::Config.environment)
      @name || "#{BuildrPlus::Config.app_scope}#{BuildrPlus::Config.app_scope.nil? ? '' : '_'}#{BuildrPlus::Config.user || 'NOBODY'}_#{self.default? || self.external? ? '' : "#{Reality::Naming.uppercase_constantize(BuildrPlus::Keycloak.root_project.name)}_"}#{Reality::Naming.uppercase_constantize(self.client_type.to_s)}_#{BuildrPlus::Config.env_code(environment)}"
    end

    attr_writer :auth_client_type

    def auth_client_type
      @auth_client_type || self.client_type
    end

    # Return the client that is responsible for the initial authentication process for this client
    def auth_client
      BuildrPlus::Keycloak.client_by_client_type(self.auth_client_type)
    end

    def config_prefix
      prefix =
        (self.external? || self.default?) ?
          '' :
          "#{Reality::Naming.uppercase_constantize(BuildrPlus::Keycloak.root_project.name)}_"
      "#{prefix}#{Reality::Naming.uppercase_constantize(self.client_type)}"
    end

    def redfish_config_prefix
      prefix = "#{Reality::Naming.uppercase_constantize(self.external? ? self.application : BuildrPlus::Keycloak.root_project.name)}_"
      suffix =
        ((!self.external? && self.default?) || (self.external? && self.application == self.client_type)) ?
          '' :
          "_#{Reality::Naming.uppercase_constantize(self.client_type)}"
      "#{prefix}KEYCLOAK_CLIENT#{suffix}"
    end
  end
end

BuildrPlus::FeatureManager.feature(:keycloak) do |f|
  f.enhance(:Config) do
    def root_project
      if Buildr.application.current_scope.size > 0
        return Buildr.project(Buildr.application.current_scope.join(':')).root_project rescue nil
      end
      Buildr.projects.first.root_project
    end

    attr_writer :include_api_client

    def include_api_client?
      @include_api_client.nil? ? BuildrPlus::FeatureManager.activated?(:role_user_experience) : !!@include_api_client
    end

    def remote_client_by_client_type(client_type)
      self.remote_clients_map[client_type.to_s] || (raise "Unable to locate remote_client with client_type '#{client_type}'")
    end

    def remote_client(client_type, options = {})
      raise "Attempting to redefine remote_client #{client_type}" if self.remote_clients_map[client_type.to_s]
      remote_client = BuildrPlus::Keycloak::KeycloakRemoteClient.new(client_type, options)
      self.remote_clients_map[client_type.to_s] = remote_client
      remote_client
    end

    def remote_clients
      remote_clients_map.values
    end

    def remote_clients_map
      @remote_clients ||= {}
    end

    def client_by_client_type(client_type)
      self.clients_map[client_type.to_s] || (raise "Unable to locate client with client_type '#{client_type.name}'")
    end

    def client(client_type, options = {})
      raise "Attempting to redefine client_type #{client_type}" if self.clients_map[client_type.to_s]
      client = BuildrPlus::Keycloak::KeycloakClient.new(client_type.to_s, options)
      self.clients_map[client_type.to_s] = client
      client
    end

    def clients
      clients_map.values
    end

    def clients_map
      @clients ||= {}
    end
  end

  f.enhance(:ProjectExtension) do
    before_define do |buildr_project|
      if buildr_project.ipr?
        # Libraries integrate with their host application so we can exclude them
        unless BuildrPlus::FeatureManager.activated?(:role_library)
          BuildrPlus::Keycloak.client(buildr_project.root_project.name)
          BuildrPlus::Keycloak.client('api') if BuildrPlus::Keycloak.include_api_client?
        end
      end
    end

    after_define do |buildr_project|
      if buildr_project.ipr?
        desc 'Upload keycloak client definition to realm'
        buildr_project.task ':keycloak:create' do
          name = buildr_project.name
          cname = Reality::Naming.uppercase_constantize(name)

          base_dir = buildr_project._('generated/keycloak')
          mkdir_p base_dir

          file = buildr_project.file("generated/domgen/#{name}/main/etc/keycloak")
          file.invoke
          cp_r Dir["#{file}/*"], base_dir

          BuildrPlus::Keycloak.clients.select {|c| c.external?}.each do |client|
            a = Buildr.artifact(client.artifact)
            a.invoke
            cp_r a.to_s, "#{base_dir}/#{client.client_type}.json"
          end

          a = Buildr.artifact(BuildrPlus::Libs.keycloak_converger)
          a.invoke

          args = []
          args << '-jar'
          args << a.to_s
          args << '-v'
          args << '-d' << base_dir
          args << "--server-url=#{BuildrPlus::Config.environment_config.keycloak.base_url}"
          args << "--realm-name=#{BuildrPlus::Config.environment_config.keycloak.realm}"
          args << "--admin-username=#{BuildrPlus::Config.environment_config.keycloak.admin_username}" if BuildrPlus::Config.environment_config.keycloak.admin_username
          args << "--admin-password=#{BuildrPlus::Config.environment_config.keycloak.admin_password}"
          BuildrPlus::Keycloak.clients.each do |client|
            args << "-e#{client.config_prefix}_NAME=#{client.name}"
          end
          args << "-e#{cname}_ORIGIN=http://127.0.0.1:8080"
          args << "-e#{cname}_URL=http://127.0.0.1:8080/#{name}"

          BuildrPlus::Keycloak.clients.collect {|c| c.application}.compact.sort.uniq.each do |app|
            cname = Reality::Naming.uppercase_constantize(app)
            args << "-e#{cname}_ORIGIN=http://127.0.0.1:8080"
            args << "-e#{cname}_URL=http://127.0.0.1:8080/#{app}"
          end

          Java::Commands.java(args)
        end

        desc 'Remove uploaded keycloak client definitions from realm'
        buildr_project.task ':keycloak:destroy' do
          base_dir = buildr_project._('generated/keycloak_to_delete')
          mkdir_p base_dir

          a = Buildr.artifact(BuildrPlus::Libs.keycloak_converger)
          a.invoke

          args = []
          args << '-jar'
          args << a.to_s
          args << '-v'
          args << '-d' << base_dir
          args << "--server-url=#{BuildrPlus::Config.environment_config.keycloak.base_url}"
          args << "--realm-name=#{BuildrPlus::Config.environment_config.keycloak.realm}"
          args << "--admin-username=#{BuildrPlus::Config.environment_config.keycloak.admin_username}" if BuildrPlus::Config.environment_config.keycloak.admin_username
          args << "--admin-password=#{BuildrPlus::Config.environment_config.keycloak.admin_password}"
          BuildrPlus::Keycloak.clients.each do |client|
            args << '--delete-client' << client.name
          end

          Java::Commands.java(args)
        end

        buildr_project.instance_eval do
          desc 'Keycloak Client Definitions'
          define 'keycloak-clients' do
            project.no_iml
            BuildrPlus::Keycloak.clients.select {|c| !c.external?}.each do |client|
              desc "Keycloak #{client.client_type} Client Definition"
              define client.client_type.to_s do
                project.no_iml

                [:json, :json_sources].each do |type|
                  package(type).enhance do |t|
                    project.task(':domgen:all').invoke
                    mkdir_p File.dirname(t.to_s)
                    cp "generated/domgen/#{buildr_project.root_project.name}/main/etc/keycloak/#{client.client_type}.json", t.to_s
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

class Buildr::Project
  def package_as_json(file_name)
    file(file_name)
  end

  def package_as_json_sources_spec(spec)
    spec.merge(:type => :json, :classifier => :sources)
  end

  def package_as_json_sources(file_name)
    file(file_name)
  end
end
