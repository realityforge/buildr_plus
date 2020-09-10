
class Buildr::IntellijIdea::IdeaProject

  def add_glassfish_configuration(project, options = {})
    version = options[:version] || '4.1.0'
    server_name = options[:server_name] || "GlassFish #{version}"
    configuration_name = options[:configuration_name] || server_name
    domain_name = options[:domain] || project.iml.id
    domain_port = options[:port] || '9009'
    packaged = options[:packaged] || {}
    exploded = options[:exploded] || {}
    artifacts = options[:artifacts] || {}

    add_to_composite_component(self.configurations) do |xml|
      xml.configuration(:name => configuration_name, :type => 'GlassfishConfiguration', :factoryName => 'Local', :default => false, :APPLICATION_SERVER_NAME => server_name) do |xml|
        xml.option(:name => 'OPEN_IN_BROWSER', :value => 'false')
        xml.option(:name => 'UPDATING_POLICY', :value => 'restart-server')

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
          exploded.each do |deployable_name, context_root|
            deployment.artifact(:name => deployable_name) do |file|
              file.settings do |settings|
                settings.option(:name => 'contextRoot', :value => "/#{context_root}")
                settings.option(:name => 'defaultContextRoot', :value => 'false')
              end
            end
          end
          artifacts.each do |deployable_name, context_root|
            deployment.artifact(:name => deployable_name) do |file|
              file.settings do |settings|
                settings.option(:name => 'contextRoot', :value => "/#{context_root}")
                settings.option(:name => 'defaultContextRoot', :value => 'false')
              end
            end
          end
        end

        xml.tag! 'server-settings' do |server_settings|
          server_settings.option(:name => 'VIRTUAL_SERVER')
          server_settings.option(:name => 'DOMAIN', :value => domain_name.to_s)
          server_settings.option(:name => 'PRESERVE', :value => 'false')
          server_settings.option(:name => 'USERNAME', :value => 'admin')
          server_settings.option(:name => 'PASSWORD', :value => '')
        end

        xml.predefined_log_file(:id => 'GlassFish', :enabled => 'true')

        xml.extension(:name => 'coverage', :enabled => 'false', :merge => 'false', :sample_coverage => 'true', :runner => 'idea')

        xml.RunnerSettings(:RunnerId => 'Cover')

        add_glassfish_runner_settings(xml, 'Cover')
        add_glassfish_configuration_wrapper(xml, 'Cover')

        add_glassfish_runner_settings(xml, 'Debug', {
          :DEBUG_PORT => domain_port.to_s,
          :TRANSPORT => '0',
          :LOCAL => 'true',
        })
        add_glassfish_configuration_wrapper(xml, 'Debug')

        add_glassfish_runner_settings(xml, 'Run')
        add_glassfish_configuration_wrapper(xml, 'Run')

        xml.method do |method|
          method.option(:name => 'BuildArtifacts', :enabled => 'true') do |option|
            exploded.keys.each do |deployable_name|
              option.artifact(:name => deployable_name)
            end
            artifacts.keys.each do |deployable_name|
              option.artifact(:name => deployable_name)
            end
          end
        end
      end
    end
  end

  def add_glassfish_remote_configuration(project, options = {})
    artifact_name = options[:name] || project.iml.id
    version = options[:version] || '4.1.0'
    server_name = options[:server_name] || "GlassFish #{version}"
    configuration_name = options[:configuration_name] || "Remote #{server_name}"
    domain_port = options[:port] || '9009'
    packaged = options[:packaged] || {}
    exploded = options[:exploded] || {}
    artifacts = options[:artifacts] || {}

    add_to_composite_component(self.configurations) do |xml|
      xml.configuration(:name => configuration_name, :type => 'GlassfishConfiguration', :factoryName => 'Remote', :default => false, :APPLICATION_SERVER_NAME => server_name) do |xml|
        xml.option(:name => 'LOCAL', :value => 'false')
        xml.option(:name => 'OPEN_IN_BROWSER', :value => 'false')
        xml.option(:name => 'UPDATING_POLICY', :value => 'redeploy-artifacts')

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
          exploded.each do |deployable_name, context_root|
            deployment.artifact(:name => deployable_name) do |file|
              file.settings do |settings|
                settings.option(:name => 'contextRoot', :value => "/#{context_root}")
                settings.option(:name => 'defaultContextRoot', :value => 'false')
              end
            end
          end
          artifacts.each do |deployable_name, context_root|
            deployment.artifact(:name => deployable_name) do |file|
              file.settings do |settings|
                settings.option(:name => 'contextRoot', :value => "/#{context_root}")
                settings.option(:name => 'defaultContextRoot', :value => 'false')
              end
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
            exploded.keys.each do |deployable_name|
              option.artifact(:name => deployable_name)
            end
            artifacts.keys.each do |deployable_name|
              option.artifact(:name => deployable_name)
            end
          end
        end
      end
    end
  end

  def add_war_artifact(project, options = {})
    artifact_name = to_artifact_name(project, options)
    artifacts = options[:artifacts] || []

    add_artifact(artifact_name, 'war', build_on_make(options)) do |xml|
      dependencies = (options[:dependencies] || ([project] + project.compile.dependencies)).flatten
      libraries, projects = partition_dependencies(dependencies)

      emit_output_path(xml, artifact_name, options)
      xml.root :id => 'archive', :name => "#{artifact_name}.war" do
        xml.element :id => 'directory', :name => 'WEB-INF' do
          xml.element :id => 'directory', :name => 'classes' do
            artifact_content(xml, project, projects, options)
          end
          xml.element :id => 'directory', :name => 'lib' do
            emit_libraries(xml, libraries)
            emit_jar_artifacts(xml, artifacts)
          end
        end

        if options[:enable_war].nil? || options[:enable_war] || (options[:war_module_names] && options[:war_module_names].size > 0)
          module_names = options[:war_module_names] || [project.iml.name]
          module_names.each do |module_name|
            facet_name = options[:war_facet_name] || 'Web'
            xml.element :id => 'javaee-facet-resources', :facet => "#{module_name}/web/#{facet_name}"
          end
        end

        if options[:enable_gwt] || (options[:gwt_module_names] && options[:gwt_module_names].size > 0)
          module_names = options[:gwt_module_names] || [project.iml.name]
          module_names.each do |module_name|
            facet_name = options[:gwt_facet_name] || 'GWT'
            xml.element :id => 'gwt-compiler-output', :facet => "#{module_name}/gwt/#{facet_name}"
          end
        end
      end
    end
  end
end
