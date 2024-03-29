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
    attr_accessor :username
    attr_accessor :password

    def default?
      self.client_type.to_s == self.application.to_s
    end

    attr_writer :name

    def name(environment = BuildrPlus::Config.environment)
      @name || "#{BuildrPlus::Config.app_scope}#{BuildrPlus::Config.app_scope.nil? ? '' : '_'}#{BuildrPlus::Config.user || 'NOBODY'}_#{self.default? || self.application.nil? ? '' : "#{Reality::Naming.uppercase_constantize(self.application || BuildrPlus::Keycloak.root_project.name)}_"}#{Reality::Naming.uppercase_constantize(self.client_type.to_s)}_#{BuildrPlus::Config.env_code(environment)}"
    end

    def redfish_config_prefix
      prefix = "#{Reality::Naming.uppercase_constantize(self.application || BuildrPlus::Keycloak.root_project.name)}_"
      suffix = self.default? ? '' : "_#{Reality::Naming.uppercase_constantize(self.client_type)}"
      "#{prefix}KEYCLOAK_REMOTE_CLIENT#{suffix}"
    end

    # Generate a secret that is "constant" during development so it is easy to configure in redfish
    def secret_value
      filename = BuildrPlus::Keycloak.root_project._("config/secrets/#{name}")
      File.exists?(filename) ? IO.read(filename) : "-"
    end
  end

  class KeycloakClient < Reality::BaseElement
    def initialize(key, options = {})
      @key = key
      @artifact = nil
      super(options)
    end

    attr_reader :key

    attr_accessor :client_type

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

    def name(environment = BuildrPlus::Config.environment)
      "#{BuildrPlus::Config.app_scope}#{BuildrPlus::Config.app_scope.nil? ? '' : '_'}#{BuildrPlus::Config.user || 'NOBODY'}_#{Reality::Naming.uppercase_constantize(self.key)}_#{BuildrPlus::Config.env_code(environment)}"
    end

    attr_writer :auth_client_type

    def auth_client_type
      @auth_client_type || self.client_type
    end

    def config_prefix
      prefix =
        (self.external? || self.default?) ?
          '' :
          "#{Reality::Naming.uppercase_constantize(BuildrPlus::Keycloak.root_project.name)}_"
      "#{prefix}#{Reality::Naming.uppercase_constantize(self.client_type)}"
    end

    def redfish_config_prefix
      prefix = "#{Reality::Naming.uppercase_constantize(self.application || BuildrPlus::Keycloak.root_project.name)}_"
      suffix = ''
      if self.external?
        if self.application != self.client_type
          suffix = "_#{Reality::Naming.uppercase_constantize(self.client_type.to_s.gsub(/^#{self.application}/,''))}"
        end
      else
        unless self.application.nil? && self.default?
          suffix = "_#{Reality::Naming.uppercase_constantize(self.client_type)}"
        end
      end
      "#{prefix}KEYCLOAK_CLIENT#{suffix}"
    end

    def env_var
      prefix = "#{Reality::Naming.uppercase_constantize(self.external? ? '' : BuildrPlus::Keycloak.root_project.name)}"
      suffix = (!self.external? && self.default?) ? '' : "#{Reality::Naming.uppercase_constantize(self.client_type)}"
      "#{prefix}#{'' == prefix ? '' : '' == suffix ? '' : '_'}#{suffix}"
    end

    # Generate a secret that is "constant" during development so it is easy to configure in redfish
    def secret_value
      filename = BuildrPlus::Keycloak.root_project._("config/secrets/#{name}")
      File.exists?(filename) ? IO.read(filename) : "-"
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

    def keycloak_converger
      'org.realityforge.keycloak.converger:keycloak-converger:jar:1.13'
    end

    def local_application_url
      @local_application_url || ENV['LOCAL_APPLICATION_URL'] || 'http://127.0.0.1:8080'
    end

    attr_writer :local_application_url

    attr_writer :include_api_client

    def include_api_client?
      @include_api_client.nil? ? BuildrPlus::FeatureManager.activated?(:role_user_experience) : !!@include_api_client
    end

    def remote_client(client_type, options = {})
      remote_client = BuildrPlus::Keycloak::KeycloakRemoteClient.new(client_type.to_s, options)
      self.remote_clients_list << remote_client
      remote_client
    end

    def remote_clients
      remote_clients_list.dup
    end

    def remote_clients_list
      @remote_clients ||= []
    end

    def client(name, options = {})
      options = options.dup
      options[:client_type] = name unless options[:client_type]
      client = BuildrPlus::Keycloak::KeycloakClient.new(name, options)
      raise "Attempting to redefine client #{client.key}" if self.clients_map[client.key.to_s]
      self.clients_map[client.key.to_s] = client
      client
    end

    def client_by_key?(key)
      !self.clients_map[key.to_s].nil?
    end

    def client_by_key(key)
      client = self.clients_map[key.to_s]
      raise "Unable to locate client #{key}. Existing clients include: #{self.clients_map.keys}" if client.nil?
      client
    end

    def clients
      clients_map.values
    end

    def clients_map
      @clients ||= {}
    end

    def patch_client(client, filename)
      content = IO.read(filename)
      app = client.application || BuildrPlus::Keycloak.root_project.name
      cname = client.env_var
      content.gsub!("{{#{cname}_NAME}}", "#{client.name}")
      content.gsub!("{{#{cname}_ORIGIN}}", "#{BuildrPlus::Keycloak.local_application_url}")
      content.gsub!("{{#{cname}_URL}}", "#{BuildrPlus::Keycloak.local_application_url}/#{app}")
      IO.write(filename, content)
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

          base_dir = buildr_project._('generated/keycloak')
          rm_rf base_dir
          mkdir_p base_dir

          filename =
            BuildrPlus::Generate.clean_generated_files? ?
              buildr_project._(:target, :generated, 'domgen', name, 'main/etc/keycloak') :
              buildr_project._(:srcgen, 'domgen', name, 'main/etc/keycloak')
          file = buildr_project.file(filename)
          file.invoke

          BuildrPlus::Keycloak.clients.select { |c| !c.external? }.each do |client|
            target_filename = "#{base_dir}/#{client.key}.json"
            cp_r "#{file}/#{client.client_type}.json", target_filename
            BuildrPlus::Keycloak.patch_client(client, target_filename)
          end

          BuildrPlus::Keycloak.clients.select { |c| c.external? }.each do |client|
            a = Buildr.artifact(client.artifact)
            a.invoke
            target_filename = "#{base_dir}/#{client.key}.json"
            cp_r a.to_s, target_filename
            BuildrPlus::Keycloak.patch_client(client, target_filename)
          end
          if BuildrPlus::Config.environment == 'test'
            Dir["#{base_dir}/*"].each do |filename|
              # Patch redirectUris and webOrigins so that always works from tests
              json = JSON.load(IO.read(filename))
              json['redirectUris'] = ['*'] unless json['redirectUris'].size == 0
              json['webOrigins'] = ['*'] unless json['webOrigins'].size == 0
              IO.write(filename, JSON.pretty_generate(json))
            end
          end

          a = Buildr.artifact(BuildrPlus::Keycloak.keycloak_converger)
          a.invoke

          args = []
          args << '-jar'
          args << a.to_s
          args << '-v'
          args << '-d' << base_dir
          args << '--secrets-dir' << buildr_project._('config/secrets')

          args << "--server-url=#{BuildrPlus::Config.environment_config.keycloak.base_url}"
          args << "--realm-name=#{BuildrPlus::Config.environment_config.keycloak.realm}"
          args << "--admin-username=#{BuildrPlus::Config.environment_config.keycloak.admin_username}" if BuildrPlus::Config.environment_config.keycloak.admin_username
          args << "--admin-password=#{BuildrPlus::Config.environment_config.keycloak.admin_password}"

          existing = BuildrPlus::Keycloak.clients.collect{|client| client.name}
          BuildrPlus::Keycloak.remote_clients.select{|c|!existing.include?(c.name)}.sort_by { |c| c.name }.each do |remote_client|
            args << "--unmanaged-client=#{remote_client.name}"
          end

          Java::Commands.java(args)
        end

        desc 'Remove uploaded keycloak client definitions from realm'
        buildr_project.task ':keycloak:destroy' do
          base_dir = buildr_project._('generated/keycloak_to_delete')
          mkdir_p base_dir

          a = Buildr.artifact(BuildrPlus::Keycloak.keycloak_converger)
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
            BuildrPlus::Keycloak.clients.select { |c| !c.external? }.each do |client|
              desc "Keycloak #{client.client_type} Client Definition"
              define client.key.to_s do
                project.no_iml

                [:json, :json_sources].each do |type|
                  package(type).enhance do |t|
                    project.task(':domgen:all').invoke
                    mkdir_p File.dirname(t.to_s)
                    base_path =
                      BuildrPlus::Generate.clean_generated_files? ?
                        buildr_project._(:target, :generated, 'domgen') :
                        buildr_project._(:srcgen, 'domgen')

                    cp "#{base_path}/#{buildr_project.root_project.name}/main/etc/keycloak/#{client.client_type}.json", t.to_s
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
