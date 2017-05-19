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

BuildrPlus::FeatureManager.feature(:gwt => [:jackson]) do |f|
  f.enhance(:Config) do
    def gwtc_java_args
      %w(-ea -Djava.awt.headless=true -Xms512M -Xmx1024M)
    end

    def add_source_to_jar(project)
      project.package(:jar).tap do |jar|
        project.compile.sources.each do |src|
          jar.include("#{src}/*")
        end
      end
    end

    def define_gwt_task(project, suffix = '', options = {})
      # Unfortunately buildr does not gracefully handle resource directories not being present
      # when project processed so we collect extra dependencies by looking at the generated directories
      extra_deps = project.iml.main_generated_resource_directories.flatten.compact.collect do |a|
        a.is_a?(String) ? file(a) : a
      end + project.iml.main_generated_source_directories.flatten.compact.collect do |a|
        a.is_a?(String) ? file(a) : a
      end

      dependencies = project.compile.dependencies + [project.compile.target] + extra_deps
      unless ENV['GWT'] == 'no'
        project.gwt(project.determine_top_level_gwt_modules(suffix),
                    {:java_args => BuildrPlus::Gwt.gwtc_java_args, :dependencies => dependencies}.merge(options))
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
                                :settings => {:compilerMaxHeapSize => '1024'},
                                :gwt_dev_artifact => BuildrPlus::Libs.gwt_dev)

    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr/gwt'
    end

    def top_level_gwt_modules
      @top_level_gwt_modules ||= []
    end

    # Determine any top level modules.
    # If none specified then derive one based on root projects name and group
    def determine_top_level_gwt_modules(suffix)
      m = self.top_level_gwt_modules
      gwt_modules = !m.empty? ? m : self.gwt_modules.select{|m| m =~ /#{suffix}$/}

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
      "#{p.group_as_package}.#{p.name_as_class}#{suffix}"
    end

    def gwt_module?(module_name)
      self.gwt_modules.include?(module_name)
    end

    def gwt_modules
      unless @gwt_modules
        @gwt_modules =
          (project.iml.main_generated_resource_directories + project.resources.sources).uniq.collect do |path|
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
