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

BuildrPlus::FeatureManager.feature(:jms => [:ejb]) do |f|
  f.enhance(:Config) do
    def mq_container_name(project)
      app_scope = BuildrPlus::Config.app_scope
      env_code = BuildrPlus::Config.env_code
      "openmq_#{project.root_project.name}#{app_scope.nil? ? '' : '_'}#{app_scope}_#{env_code}"
    end

    def stop_container(project)
      name = mq_container_name(project)
      sh "docker stop #{name} > /dev/null" if is_openmq_running?(project)
      sh "docker rm #{name} > /dev/null" if is_openmq_created?(project)
    end

    def start_container(project)
      name = mq_container_name(project)

      stop_container(project)

      port = find_free_port

      sh "docker run -d -ti -P --name=#{name} --net=host --env=\"IMQ_PORTMAPPER_PORT=#{port}\" --label org.realityforge.buildr_plus.omq.port=#{port} stocksoftware/openmq > /dev/null"
      link_container_to_configuration(project, BuildrPlus::Config.environment_config)
      BuildrPlus::Config.output_aux_confgs!
    end

    def link_container_to_configuration(project, environment_config)
      name = mq_container_name(project)

      if is_openmq_running?(project)
        omq_port =
          `docker inspect --format '{{ index .Config.Labels "org.realityforge.buildr_plus.omq.port"}}' #{name} 2>/dev/null`.chomp
        environment_config.broker(:host => BuildrPlus::Redfish.docker_ip,
                                  :port => omq_port.to_i,
                                  :admin_username => 'admin',
                                  :admin_password => 'admin')
      end
    end

    def find_free_port
      server = TCPServer.new('127.0.0.1', 0)
      port = server.addr[1]
      server.close
      port
    end

    def is_openmq_running?(project)
      `docker ps | grep #{mq_container_name(project)}`.chomp != ''
    end

    def is_openmq_created?(project)
      `docker ps -a | grep #{mq_container_name(project)}`.chomp != ''
    end
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|
      if project.ipr?
        if BuildrPlus::FeatureManager.activated?(:redfish)
          desc 'Start an openmq server useful to test against'
          project.task ':openmq:start' do
            BuildrPlus::Jms.start_container(project)
          end

          desc 'Stop the openmq server'
          project.task ':openmq:stop' do
            BuildrPlus::Jms.stop_container(project)
          end
        end
      end
    end
  end
end
