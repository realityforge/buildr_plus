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

    def client_name_overrides
      @client_name_overrides ||= {}
    end

    def client_name_for(client_type)
      client_name_overrides[client_type] || "#{BuildrPlus::Config.app_scope}#{BuildrPlus::Config.app_scope.nil? ? '' : '_'}#{BuildrPlus::Config.user || 'NOBODY'}_#{default_client_type?(client_type) ? '' : "#{BuildrPlus::Naming.uppercase_constantize(default_client_type)}_"}#{BuildrPlus::Naming.uppercase_constantize(client_type.to_s)}_#{BuildrPlus::Config.env_code}"
    end

    def root_project
      if Buildr.application.current_scope.size > 0
        return Buildr.project(Buildr.application.current_scope.join(':')).root_project rescue nil
      end
      Buildr.projects.first.root_project
    end
  end

  f.enhance(:ProjectExtension) do
    after_define do |buildr_project|
      if buildr_project.ipr?

        desc 'Upload keycloak client definition to realm'
        buildr_project.task ':keycloak:create' do
          a = Buildr.artifact('org.realityforge.keycloak.converger:keycloak-converger:jar:1.3')
          a.invoke

          name = buildr_project.name
          cname = BuildrPlus::Naming.uppercase_constantize(name)

          args = []
          args << '-jar'
          args << a.to_s
          args << '-v'
          args << '-d' << "generated/domgen/#{name}/main/etc/keycloak"
          args << "--server-url=#{BuildrPlus::Config.environment_config.keycloak.base_url}"
          args << "--realm-name=#{BuildrPlus::Config.environment_config.keycloak.realm}"
          args << "--admin-username=#{BuildrPlus::Config.environment_config.keycloak.admin_username}" if BuildrPlus::Config.environment_config.keycloak.admin_username
          args << "--admin-password=#{BuildrPlus::Config.environment_config.keycloak.admin_password}"
          BuildrPlus::Keycloak.client_types.each do |client_type|
            args << "-e#{name == client_type ? '' : "#{cname}_"}#{BuildrPlus::Naming.uppercase_constantize(client_type)}_NAME=#{BuildrPlus::Keycloak.client_name_for(client_type)}"
          end
          args << "-e#{cname}_ORIGIN=http://127.0.0.1:8080"
          args << "-e#{cname}_URL=http://127.0.0.1:8080/#{name}"

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

                package(:json).enhance do |t|
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

class Buildr::Project
  def package_as_json(file_name)
    file(file_name)
  end
end
