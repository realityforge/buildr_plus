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
BuildrPlus::FeatureManager.feature(:java => [:ruby]) do |f|
  f.enhance(:Config) do
    def version=(version)
      raise "Invalid java version #{version}" unless [7, 8].include?(version)
      @version = version
    end

    def version
      @version || 8
    end

    attr_writer :enable_annotation_processor

    def enable_annotation_processor?
      @enable_annotation_processor.nil? ? true : !!@enable_annotation_processor
    end
  end
  f.enhance(:ProjectExtension) do
    attr_writer :enable_annotation_processor

    def enable_annotation_processor?
      @enable_annotation_processor.nil? ? BuildrPlus::Java.enable_annotation_processor? : !!@enable_annotation_processor
    end

    before_define do |project|
      project.compile.options.lint = 'all'
      project.compile.options.source = "1.#{BuildrPlus::Java.version}"
      project.compile.options.target = "1.#{BuildrPlus::Java.version}"
      project.iml.instance_variable_set('@main_generated_source_directories',[])
    end

    after_define do |project|
      project.test.options[:properties].merge!('user.timezone' => 'Australia/Melbourne')

      t = project.task 'java:check' do
        (project.test.compile.sources + project.compile.sources).each do |src|
          Dir.glob("#{src}/**/*").select {|f| File.directory? f}.each do |d|
            dir = d[src.size + 1, 10000000]
            if dir.include?('.')
              raise "The directory #{d} included in java source path has a path component that includes the '.' character. This violates package name conventions."
            end
          end
        end
      end
      project.task(':java:check').enhance([t.name])

      if project.iml? && project.enable_annotation_processor?
        project.iml.main_generated_source_directories << project._('generated/processors/main/java')
      end

      if project.ipr? && BuildrPlus::Java.enable_annotation_processor?
        project.ipr.add_component('CompilerConfiguration') do |component|
          component.annotationProcessing do |xml|
            xml.profile(:default => true, :name => 'Default', :enabled => true) do
              xml.sourceOutputDir :name => 'generated/processors/main/java'
              xml.sourceTestOutputDir :name => 'generated/processors/test/java'
              xml.outputRelativeToContentRoot :value => true
            end
            disabled = Buildr.projects(:no_invoke => true).select {|p| p.iml? && !p.enable_annotation_processor?}
            unless disabled.empty?
              xml.profile(:name => 'Disabled') do
                disabled.each do |p|
                  xml.module :name => p.name
                end
              end
            end
          end
        end
      end
    end

    desc 'Check the directories in java source tree do not have . character'
    task 'java:check'
  end
end
