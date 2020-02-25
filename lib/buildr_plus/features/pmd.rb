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

BuildrPlus::FeatureManager.feature(:pmd) do |f|
  f.enhance(:Config) do
    def default_pmd_rules
      'au.com.stocksoftware.pmd:pmd:xml:1.8'
    end

    def pmd_rules
      @pmd_rules || self.default_pmd_rules
    end

    attr_writer :pmd_rules

    attr_accessor :additional_project_names
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr/pmd'
      Buildr::Pmd.instance_eval do
        class << self
          # The specs for requirements
          def dependencies
            %w(
              net.sourceforge.pmd:pmd-core:jar:6.11.0
              net.sourceforge.pmd:pmd-java:jar:6.11.0
              net.sourceforge.pmd:pmd-java8:jar:6.11.0
              jaxen:jaxen:jar:1.1.6
              commons-io:commons-io:jar:2.6
              com.beust:jcommander:jar:1.72
              org.ow2.asm:asm:jar:7.1
              com.google.code.gson:gson:jar:2.8.5
              net.java.dev.javacc:javacc:jar:5.0
              net.sourceforge.saxon:saxon:jar:9.1.0.8
              org.apache.commons:commons-lang3:jar:3.8.1
              org.antlr:antlr4-runtime:jar:4.7
              )
          end

          def pmd(rule_set_files, format, output_file_prefix, source_paths, options = {})
            dependencies = (options[:dependencies] || []) + self.dependencies
            cp = Buildr.artifacts(dependencies).each(&:invoke).map(&:to_s)
            (options[:rule_set_paths] || []).each {|p| cp << p}

            rule_sets = rule_set_files.dup

            Buildr.artifacts(options[:rule_set_artifacts] || []).each do |artifact|
              a = artifact.to_s
              dirname = File.dirname(a)
              rule_sets << a[dirname.length + 1, a.length]
              cp << File.dirname(a)
              artifact.invoke
            end

            puts 'PMD: Analyzing source code...'
            mkdir_p File.dirname(output_file_prefix)

            Buildr.ant('pmd-report') do |ant|
              ant.taskdef :name => 'pmd', :classpath => cp.join(';'), :classname => 'net.sourceforge.pmd.ant.PMDTask'
              ant.pmd :shortFilenames => true, :rulesetfiles => rule_sets.join(','), :noCache => true do
                ant.formatter :type => format, :toFile => "#{output_file_prefix}.#{format}"
                source_paths.each do |src|
                  ant.fileset :dir => src, :includes => '**/*.java' if File.directory?(src)
                end
              end
            end
          end
        end
      end
    end

    before_define do |project|
      project.pmd.enabled = true if project.ipr?
    end

    after_define do |project|
      if project.ipr?
        project.pmd.rule_set_artifacts << BuildrPlus::Pmd.pmd_rules
        # TODO: Use project.pmd.exclude_paths rather than excluding projects

        project.pmd.additional_project_names =
          BuildrPlus::Pmd.additional_project_names ||
            BuildrPlus::Util.subprojects(project).select {|p| !(p =~ /.*:soap-client$/)}
      end
    end
  end
end
