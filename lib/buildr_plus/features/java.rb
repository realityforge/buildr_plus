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
      raise "Invalid java version #{version}" unless [8, 11, 17].include?(version)
      @version = version
    end

    def version
      @version || 17
    end

    attr_writer :fail_on_compile_warning

    def fail_on_compile_warning?
      # Defaults to false as projects with arez/sting/react4j will fail in java 17 as annotation processor
      # does not run processors in test package which results in warnings for unexpected annotation options
      @fail_on_compile_warning.nil? ? false : !!@fail_on_compile_warning
    end

    attr_writer :compile_with_linting_enabled

    def compile_with_linting_enabled?
      @compile_with_linting_enabled.nil? ? true : !!@compile_with_linting_enabled
    end
  end
  f.enhance(:ProjectExtension) do
    attr_writer :compile_with_linting_enabled

    def compile_with_linting_enabled?
      @compile_with_linting_enabled.nil? ? BuildrPlus::Java.compile_with_linting_enabled? : !!@compile_with_linting_enabled
    end

    attr_writer :fail_on_compile_warning

    def fail_on_compile_warning?
      @fail_on_compile_warning.nil? ? BuildrPlus::Java.fail_on_compile_warning? : !!@fail_on_compile_warning
    end

    before_define do |project|
      project.compile.options.lint = 'all,-processing,-serial' if project.compile_with_linting_enabled?
      java_version_spec = 8 == BuildrPlus::Java.version ? '1.8' : BuildrPlus::Java.version.to_s
      project.compile.options.source = java_version_spec
      project.compile.options.target = java_version_spec
      project.compile.options.warnings = true
      project.compile.options[:other] = %w(-Xmaxerrs 10000 -Xmaxwarns 10000) + (project.fail_on_compile_warning? ? %w(-Werror) : [])
      (project.test.options[:java_args] ||= []) << %w(-ea)

      # If an annotation processor fails it can result in lots of errors due to code not
      # being generated yet. So make sure the compiler reports all errors so can track down
      # the root cause
      project.ipr.add_javac_settings("-Xmaxerrs 10000 -Xmaxwarns 10000#{project.compile_with_linting_enabled? ? ' -Xlint:all,-processing,-serial' : '' }#{project.fail_on_compile_warning? ? ' -Werror' : ''}") if project.ipr?
    end

    after_define do |project|
      project.compile.options.processor = false if project.compile.options.processor_path.nil? || project.compile.options.processor_path.empty?
      project.test.compile.options.processor = false if project.test.compile.options.processor_path.nil? || project.test.compile.options.processor_path.empty?
      project.test.options[:properties].merge!('user.timezone' => 'Australia/Melbourne')

      project.compile.options.processor_options ||= {}

      if BuildrPlus::FeatureManager.activated?(:arez)
        project.compile.options.processor_options['arez.debug'] = 'false'
        project.compile.options.processor_options['arez.profile'] = 'false'
      end
      if BuildrPlus::FeatureManager.activated?(:react4j)
        project.compile.options.processor_options['react4j.debug'] = 'false'
        project.compile.options.processor_options['react4j.profile'] = 'false'
      end
      if BuildrPlus::FeatureManager.activated?(:sting)
        project.compile.options.processor_options['sting.debug'] = 'false'
        project.compile.options.processor_options['sting.profile'] = 'false'
      end

      t = project.task 'java:check' do
        (project.test.compile.sources + project.compile.sources).each do |src|
          Dir.glob("#{src}/**/*").select {|f| File.directory? f}.each do |d|
            dir = d[src.to_s.size + 1, 10000000]
            if dir.include?('.')
              raise "The directory #{d} included in java source path has a path component that includes the '.' character. This violates package name conventions."
            end
          end
        end
      end
      project.task(':java:check').enhance([t.name])
    end

    desc 'Check the directories in java source tree do not have . character'
    task 'java:check'
  end
end
