
class Buildr::IntellijIdea::IdeaProject
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
