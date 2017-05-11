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

BuildrPlus::FeatureManager.feature(:keycloak) do |f|
  f.enhance(:Config) do
    def default_client_type
      root_project.name
    end

    def default_client_type?(client_type)
      default_client_type == client_type
    end

    def client_types
      client_types = []
      client_types += self.additional_client_types
      if BuildrPlus::FeatureManager.activated?(:role_user_experience)
        # api client is for gwt_rpc, default_client_type is for UX
        client_types += [default_client_type, 'api']
      elsif BuildrPlus::FeatureManager.activated?(:role_library)
        # Do nothing. Libraries integrate with their host application
      else
        # default_client_type is for api as there is no UX client
        client_types += [default_client_type]
      end
      client_types
    end

    attr_writer :additional_client_types

    def additional_client_types
      @additional_client_types ||= []
    end

    def external_client_types
      @external_client_types ||= {}
    end

    def add_external_client_type(key, artifact)
      external_client_types[key.to_s] = artifact
    end

    def external_applications
      @external_applications ||= []
    end

    def client_name_overrides
      @client_name_overrides ||= {}
    end

    def client_name_for(client_type, external)
      client_name_overrides[client_type] || "#{BuildrPlus::Config.app_scope}#{BuildrPlus::Config.app_scope.nil? ? '' : '_'}#{BuildrPlus::Config.user || 'NOBODY'}_#{(default_client_type?(client_type) || external) ? '' : "#{Reality::Naming.uppercase_constantize(default_client_type)}_"}#{Reality::Naming.uppercase_constantize(client_type.to_s)}_#{BuildrPlus::Config.env_code}"
    end

    def root_project
      if Buildr.application.current_scope.size > 0
        return Buildr.project(Buildr.application.current_scope.join(':')).root_project rescue nil
      end
      Buildr.projects.first.root_project
    end

    def keycloak_config_prefix(client_type, external)
      prefix = ''
      unless external
        name = root_project.name
        prefix = name == client_type ? '' : "#{Reality::Naming.uppercase_constantize(name)}_"
      end
      "#{prefix}#{Reality::Naming.uppercase_constantize(client_type)}"
    end
  end

  f.enhance(:ProjectExtension) do
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

          BuildrPlus::Keycloak.external_client_types.each do |client_type, artifact|
            a = Buildr.artifact(artifact)
            a.invoke
            cp_r a.to_s, "#{base_dir}/#{client_type}.json"
          end

          a = Buildr.artifact('org.realityforge.keycloak.converger:keycloak-converger:jar:1.3')
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
          BuildrPlus::Keycloak.client_types.each do |client_type|
            args << "-e#{BuildrPlus::Keycloak.keycloak_config_prefix(client_type, false)}_NAME=#{BuildrPlus::Keycloak.client_name_for(client_type, false)}"
          end
          BuildrPlus::Keycloak.external_client_types.keys.each do |client_type|
            args << "-e#{BuildrPlus::Keycloak.keycloak_config_prefix(client_type, true)}_NAME=#{BuildrPlus::Keycloak.client_name_for(client_type, true)}"
          end
          args << "-e#{cname}_ORIGIN=http://127.0.0.1:8080"
          args << "-e#{cname}_URL=http://127.0.0.1:8080/#{name}"

          BuildrPlus::Keycloak.external_applications.each do |app|
            cname = Reality::Naming.uppercase_constantize(app)
            args << "-e#{cname}_ORIGIN=http://127.0.0.1:8080"
            args << "-e#{cname}_URL=http://127.0.0.1:8080/#{app}"
          end

          Java::Commands.java(args)
        end

        buildr_project.instance_eval do
          desc 'Keycloak Client Definitions'
          define 'keycloak-clients' do
            project.no_iml
            BuildrPlus::Keycloak.client_types.each do |client_type|
              desc "Keycloak #{client_type} Client Definition"
              define client_type.to_s do
                project.no_iml

                [:json, :json_sources].each do |type|
                  package(type).enhance do |t|
                    project.task(':domgen:all').invoke
                    mkdir_p File.dirname(t.to_s)
                    cp "generated/domgen/#{buildr_project.root_project.name}/main/etc/keycloak/#{client_type}.json", t.to_s
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
