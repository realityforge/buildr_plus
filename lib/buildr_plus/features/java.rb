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

    attr_writer :require_annotation_processors_path

    def require_annotation_processors_path?
      @require_annotation_processors_path.nil? ? true : !!@require_annotation_processors_path
    end
  end
  f.enhance(:ProjectExtension) do
    attr_writer :enable_annotation_processor

    def enable_annotation_processor?
      @enable_annotation_processor.nil? ? BuildrPlus::Java.enable_annotation_processor? : !!@enable_annotation_processor
    end

    def annotation_processor_active?
      if @enable_annotation_processor.nil?
        BuildrPlus::Java.enable_annotation_processor? &&
          (
            !BuildrPlus::Java.require_annotation_processors_path? ||
            !self.processorpath.empty?
          )
      else
        enable_annotation_processor?
      end
    end

    def processorpath
      @processorpath ||= []
    end

    before_define do |project|
      project.compile.options.lint = 'all'
      project.compile.options.source = "1.#{BuildrPlus::Java.version}"
      project.compile.options.target = "1.#{BuildrPlus::Java.version}"
      project.iml.instance_variable_set('@main_generated_source_directories', [])
      project.iml.instance_variable_set('@processorpath', {})
      (project.test.options[:java_args] ||= []) << %w(-ea)
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

      if project.annotation_processor_active?
        project.file(project._(:target, 'generated/processors/main/java')).enhance([project.compile])
        project.file(project._(:target, 'generated/processors/test/java')).enhance([project.compile])
        t = project.task('processors_setup') do
          mkdir_p project._(:target, 'generated/processors/main/java')
          mkdir_p project._(:target, 'generated/processors/test/java')
        end
        project.compile.enhance([t.name])
        unless project.processorpath.empty?
          processor_deps = Buildr.artifacts(project.processorpath)
          project.compile.enhance(processor_deps)
          processorpath = processor_deps.collect {|d| d.to_s}.join(File::PATH_SEPARATOR)
          project.compile.options[:other] = ['-processorpath', processorpath, '-s', project._(:target, 'generated/processors/main/java')]
        end
        if project.iml?
          project.iml.main_generated_source_directories << project._('generated/processors/main/java')
          project.iml.test_generated_source_directories << project._('generated/processors/test/java')
        end
      else
        project.compile.options[:other] = ['-proc:none']
      end

      if project.ipr? && BuildrPlus::Java.enable_annotation_processor?

        # If an annotation processor fails it can result in lots of errors due to code not
        # being generated yet. So make sure the compiler reports all errors so can track down
        # the root cause
        project.ipr.add_component('JavacSettings') do |component|
          # TODO: Remove -Aarez.defer.unresolved=false once we have fixed router_fu
          # dagger.formatGeneratedSource=DISABLE speeds up the dagger annotation processor by ~ 40%
          component.option(:name => 'ADDITIONAL_OPTIONS_STRING', :value => "-Xmaxerrs 10000#{BuildrPlus::FeatureManager.activated?(:arez) ? ' -Aarez.defer.unresolved=false' : ''}#{BuildrPlus::FeatureManager.activated?(:arez) ? ' -Adagger.formatGeneratedSource=DISABLED' : ''} -Xlint:all,-processing,-serial")
        end

        project.ipr.add_component('CompilerConfiguration') do |component|
          component.annotationProcessing do |xml|
            xml.profile(:default => true, :name => 'Default', :enabled => true) do
              xml.sourceOutputDir :name => 'generated/processors/main/java'
              xml.sourceTestOutputDir :name => 'generated/processors/test/java'
              xml.outputRelativeToContentRoot :value => true
              xml.processorPath :useClasspath => true
            end
            enabled = Buildr.projects(:no_invoke => true).select {|p| p.iml? && p.enable_annotation_processor? && !p.processorpath.empty?}
            enabled.each do |prj|
              xml.profile(:name => "#{prj.name}", :enabled => true) do
                xml.sourceOutputDir :name => 'generated/processors/main/java'
                xml.sourceTestOutputDir :name => 'generated/processors/test/java'
                xml.outputRelativeToContentRoot :value => true
                xml.module :name => prj.iml.name
                xml.processorPath :useClasspath => false do
                  Buildr.artifacts(prj.processorpath).each do |path|
                    xml.entry :name => project.ipr.send(:resolve_path, path.to_s)
                  end
                end
              end
            end
            disabled = Buildr.projects(:no_invoke => true).select {|p| p.iml? && !p.annotation_processor_active?}
            unless disabled.empty?
              xml.profile(:name => 'Disabled') do
                disabled.each do |p|
                  xml.module :name => p.iml.name
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
