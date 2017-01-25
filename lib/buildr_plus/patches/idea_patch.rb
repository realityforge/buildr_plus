# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

module Buildr #:nodoc:
  module IntellijIdea #:nodoc:
    class IdeaModule
      def module_root_component
        options = {'inherit-compiler-output' => 'false'}
        options['LANGUAGE_LEVEL'] = "JDK_#{jdk_version.gsub(/\./, '_')}" unless jdk_version == buildr_project.root_project.compile.options.source
        create_component('NewModuleRootManager', options ) do |xml|
          generate_compile_output(xml)
          generate_content(xml) unless skip_content?
          generate_initial_order_entries(xml)
          project_dependencies = []


          self.main_dependency_details.each do |dependency_path, export, source_path|
            next unless export
            generate_lib(xml, dependency_path, export, source_path, project_dependencies)
          end

          self.test_dependency_details.each do |dependency_path, export, source_path|
            next if export
            generate_lib(xml, dependency_path, export, source_path, project_dependencies)
          end

          xml.orderEntryProperties
        end
      end
    end

    class IdeaProject
      def add_glassfish_remote_configuration(project, options = {})
        artifact_name = options[:name] || project.iml.id
        version = options[:version] || '4.1.0'
        server_name = options[:server_name] || "GlassFish #{version}"
        configuration_name = options[:configuration_name] || "Remote #{server_name}"
        domain_port = options[:port] || '9009'
        packaged = options[:packaged] || {}
        exploded = options[:exploded] || {}

        add_to_composite_component(self.configurations) do |xml|
          xml.configuration(:name => configuration_name, :type => 'GlassfishConfiguration', :factoryName => 'Remote', :default => false, :APPLICATION_SERVER_NAME => server_name) do |xml|
            xml.option(:name => 'LOCAL', :value => 'false')
            xml.option(:name => 'OPEN_IN_BROWSER', :value => 'false')
            xml.option(:name => 'UPDATING_POLICY', :value => 'hot-swap-classes')

            xml.deployment do |deployment|
              packaged.each do |name, deployable|
                artifact = Buildr.artifact(deployable)
                artifact.invoke
                deployment.file(:path => resolve_path(artifact.to_s)) do |file|
                  file.settings do |settings|
                    settings.option(:name => 'contextRoot', :value => "/#{name}")
                    settings.option(:name => 'defaultContextRoot', :value => 'false')
                  end
                end
              end
              exploded.each do |deployable_name|
                deployment.artifact(:name => deployable_name) do |artifact|
                  artifact.settings
                end
              end
            end

            xml.tag! 'server-settings' do |server_settings|
              server_settings.option(:name => 'VIRTUAL_SERVER')
              server_settings.data do |data|
                data.option(:name => 'adminServerHost', :value => '')
                data.option(:name => 'clusterName', :value => '')
                data.option(:name => 'stagingRemotePath', :value => '')
                data.option(:name => 'transportHostId')
                data.option(:name => 'transportStagingTarget') do |option|
                  option.TransportTarget do |tt|
                    tt.option(:name => 'id', :value => 'X')
                  end
                end
              end
            end

            xml.predefined_log_file(:id => 'GlassFish', :enabled => 'true')

            add_glassfish_runner_settings(xml, 'Debug', {
              :DEBUG_PORT => domain_port.to_s,
              :TRANSPORT => '0',
              :LOCAL => 'false',
            })
            add_glassfish_configuration_wrapper(xml, 'Debug')

            add_glassfish_runner_settings(xml, 'Run')
            add_glassfish_configuration_wrapper(xml, 'Run')

            xml.method do |method|
              method.option(:name => 'BuildArtifacts', :enabled => 'true') do |option|
                option.artifact(:name => artifact_name)
              end
            end
          end
        end
      end
    end
  end
end

class Buildr::Project
  include Buildr::IntellijIdea::ProjectExtension
end
