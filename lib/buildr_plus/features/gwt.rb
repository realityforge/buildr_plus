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

BuildrPlus::FeatureManager.feature(:gwt => [:sting]) do |f|
  f.enhance(:Config) do
    def gwt_test_options
      {'braincheck.environment' => 'development'}
    end

    attr_writer :code_server_port

    def code_server_port
      @code_server_port.nil? ? 8889 : @code_server_port
    end

    def gwtc_java_args
      %w(-ea -Djava.awt.headless=true -Dgwt.watchFileChanges=false -Xms512M -Xmx6G)
    end

    def add_source_to_jar(project)
      project.package(:jar).tap do |jar|
        project.compile.sources.each do |src|
          jar.include("#{src}/*")
        end
        generated_source_deps(project).each do |src|
          jar.include("#{src}/*")
          jar.enhance([src])
          jar.enhance do |j|
            j.include("#{src}/*")
          end
        end
      end
    end

    def generated_source_deps(project)
      extra_deps = project.iml.main_generated_resource_directories.flatten.compact.collect do |a|
        a.is_a?(String) ? file(a) : a
      end + project.iml.main_generated_source_directories.flatten.compact.collect do |a|
        a.is_a?(String) ? file(a) : a
      end

      if !!project.compile.options[:processor] || (project.compile.options[:processor].nil? && !(project.compile.options[:processor_path] || []).empty?)
        extra_deps += [file(project._(:target, :generated, 'processors/main/java'))]
      end

      extra_deps
    end

    def define_gwt_task(project, suffix = '', options = {})
      extra_deps = generated_source_deps(project)

      dependencies = project.compile.dependencies + [project.compile.target] + extra_deps
      if ENV['GWT'].nil? || ENV['GWT'] == project.name
        project.gwt(project.determine_top_level_gwt_modules(suffix),
                    {
                      :java_args => BuildrPlus::Gwt.gwtc_java_args,
                      :dependencies => dependencies,
                      :gwtc_args => options[:gwtc_args],
                      :skip_merge_gwt_dependencies => true,
                      :compile_report_dir => project._(:reports, :gwt, suffix),
                    }.merge(options))
      end
    end

    def define_gwt_idea_facet(project)
      gwt_modules = project.gwt_modules
      module_config = {}
      gwt_modules.each do |m|
        module_config[m] = false
      end
      if gwt_modules.empty?
        message = "No gwt modules defined for project '#{project.name}'"
        puts message
        raise message
      end
      project.iml.add_gwt_facet(module_config,
                                :settings => { :compilerMaxHeapSize => '1024' },
                                :gwt_dev_artifact => BuildrPlus::Libs.gwt_dev)

    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr/gwt'
    end

    before_define do |project|
      project.clean { rm_rf project._(:target, :generated, :deps) }
    end

    def top_level_gwt_modules
      @top_level_gwt_modules ||= []
    end

    #
    # Used when you want to co-evolve two gwt libraries, one of which is in a different
    # project. If this was not available then you would be forced to restart superdev mode
    # each time the dependency was updated which can be painful.
    #
    # Add something like this into user-experience to achieve it.
    #
    # expand_dependency(Buildr.artifacts(BuildrPlus::Libs.replicant_gwt_client).select{|a|a.group == 'org.realityforge.replicant'})
    #
    def expand_dependency(artifacts)
      project.compile.dependencies = Buildr.artifacts(project.compile.dependencies)
      Buildr.artifacts([artifacts]).each do |artifact|
        key = artifact.group + '_' + artifact.id
        target_directory = _(:target, :generated, 'deps', key)
        t = task(target_directory => [artifact]) do
          rm_rf target_directory
          unzip(target_directory => artifact).target.invoke
          rm_f Dir["#{target_directory}/**/*.class"]
        end
        project.iml.main_generated_source_directories << target_directory
        project.compile.from(target_directory)
        project.compile.dependencies.delete_if{|a| a.to_s == artifact.to_s}

        desc 'Expand all GWT deps so they are accessible to GWT compiler'
        expand_task = task('gwt:expand_deps').enhance([t.name])
        project.compile.enhance([expand_task.name])
        task(':domgen:all').enhance([expand_task.name])
      end
    end

    # Determine any top level modules.
    # If none specified then derive one based on root projects name and group
    def determine_top_level_gwt_modules(suffix)
      m = self.top_level_gwt_modules
      gwt_modules = !m.empty? ? m : self.gwt_modules.select {|m| m =~ /#{suffix}$/}

      if gwt_modules.empty?
        puts "Unable to determine top level gwt modules for project '#{project.name}'."
        puts 'Please specify modules via project.top_level_gwt_modules setting or name'
        puts "with suffix '#{suffix}'."

        raise "Unable to determine top level gwt modules for project '#{project.name}'"
      end
      gwt_modules
    end

    def guess_gwt_module_name(suffix = '')
      p = self.root_project
      "#{p.java_package_name}.#{p.name_as_class}#{suffix}"
    end

    def gwt_module?(module_name)
      self.gwt_modules.include?(module_name)
    end

    def gwt_modules
      unless @gwt_modules
        @gwt_modules =
          (project.iml.main_generated_source_directories + project.compile.sources + project.iml.main_generated_resource_directories + project.resources.sources).uniq.collect do |path|
            Dir["#{path}/**/*.gwt.xml"].collect do |gwt_module|
              length = path.to_s.length
              gwt_module[length + 1, gwt_module.length - length - 9].gsub('/', '.')
            end
          end.flatten
      end
      @gwt_modules
    end
  end
end
