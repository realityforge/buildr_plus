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
    def default_client_name(project)
      @default_client_name || "#{BuildrPlus::Config.app_scope}#{BuildrPlus::Config.app_scope.nil? ? '' : '_'}#{BuildrPlus::Config.user || 'NOBODY'}_#{BuildrPlus::Naming.uppercase_constantize(project.root_project.name)}_#{BuildrPlus::Config.env_code}"
    end

    attr_writer :default_client_name
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|
      if project.ipr?
        project.task ':keycloak:create' do

          a = Buildr.artifact('org.realityforge.keycloak.converger:keycloak-converger:jar:1.3')
          a.invoke

          name = project.name
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
          args << "-e#{cname}_NAME=#{BuildrPlus::Keycloak.default_client_name(project)}"
          args << "-e#{cname}_URL=http://127.0.0.1:8080/#{name}"

          Java::Commands.java(args)

        end
      end
    end
  end
end
