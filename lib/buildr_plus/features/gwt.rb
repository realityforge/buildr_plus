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

BuildrPlus::FeatureManager.feature(:gwt) do |f|
  f.enhance(:Config) do
    def gwtc_java_args
      %w(-ea -Djava.awt.headless=true -Xms512M -Xmx1024M -XX:PermSize=128M -XX:MaxPermSize=256M)
    end

    def add_source_to_jar(project)
      project.package(:jar).tap do |jar|
        project.compile.sources.each do |src|
          jar.include("#{src}/*")
        end
      end
    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr_plus/patches/gwt_patch'
    end

    def top_level_gwt_modules
      @top_level_gwt_modules ||= []
    end

    def root_project
      p = project
      while p.parent
        p = p.parent
      end
      p
    end

    # Determine any top level modules.
    # If none specified then derive one based on root projects name and group
    def determine_top_level_gwt_modules
      m = self.top_level_gwt_modules
      return m unless m.empty?
      p = self.root_project
      ["#{p.group}.#{BuildrPlus::Naming.pascal_case(p.name)}"]
    end

    def gwt_modules
      project.resources.sources.collect do |path|
        Dir["#{path}/**/*.gwt.xml"].collect do |gwt_module|
          length = path.to_s.length
          gwt_module[length + 1, gwt_module.length - length - 9].gsub('/', '.')
        end
      end.flatten
    end
  end
end
