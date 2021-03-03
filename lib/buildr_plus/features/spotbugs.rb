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

module BuildrPlus::Spotbugs
  class FilterRule
    def initialize(bug_pattern, options = {})
      @bug_pattern = bug_pattern
      @class_name_pattern = options[:class_name_pattern]
    end

    attr_reader :bug_pattern
    attr_reader :class_name_pattern

    def as_xml(indent = 1)
      xml = "#{'  ' * indent}<Match>\n"
      xml += "#{'  ' * (indent + 1)}<Class name=\"#{self.class_name_pattern}\"/>\n" if self.class_name_pattern
      xml += "#{'  ' * (indent + 1)}<Bug pattern=\"#{self.bug_pattern}\"/>\n"
      xml + "#{'  ' * indent}</Match>\n"
    end
  end

  class Config
    def initialize
      @rules = []
    end

    def rule(bug_pattern, options = {})
      @rules << FilterRule.new(bug_pattern, options)
    end

    def rules
      @rules.dup
    end

    def as_xml
      "<FindBugsFilter>\n#{rules_as_xml}</FindBugsFilter>\n"
    end

    def rules_as_xml
      xml = ''
      rules.each do |r|
        xml += r.as_xml
      end
      xml
    end
  end

  def self.setup_filter_config
    config = Config.new

    config.rule('FCCD_FIND_CLASS_CIRCULAR_DEPENDENCY')
    config.rule('ITC_INHERITANCE_TYPE_CHECKING')
    config.rule('PCAIL_POSSIBLE_CONSTANT_ALLOCATION_IN_LOOP')
    config.rule('BL_BURYING_LOGIC')
    if BuildrPlus::FeatureManager.activated?(:arez)
      config.rule('URF_UNREAD_FIELD,WOC_WRITE_ONLY_COLLECTION_FIELD,CLI_CONSTANT_LIST_INDEX,IICU_INCORRECT_INTERNAL_CLASS_USE,CC_CYCLOMATIC_COMPLEXITY,EXS_EXCEPTION_SOFTENING_NO_CHECKED,PME_POOR_MANS_ENUM,PRMC_POSSIBLY_REDUNDANT_METHOD_CALLS,EI_EXPOSE_REP,RCN_REDUNDANT_NULLCHECK_WOULD_HAVE_BEEN_A_NPE',
                  :class_name_pattern => '~.*\.Arez_.*')
    end

    if BuildrPlus::FeatureManager.activated?(:react4j)
      config.rule('ACEM_ABSTRACT_CLASS_EMPTY_METHODS,CE_CLASS_ENVY,PME_POOR_MANS_ENUM',
                  :class_name_pattern => '~.*\.React4j_.*')
    end

    config
  end

end
BuildrPlus::FeatureManager.feature(:spotbugs) do |f|
  f.enhance(:Config) do
    attr_accessor :additional_project_names
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr/spotbugs'
    end

    before_define do |project|
      if project.ipr?
        project.spotbugs.enabled = true
        project.spotbugs.config_directory = project._(:etc, :spotbugs)

        target_filters_file = project._(:target, :generated, :spotbugs, 'filter.xml')

        t = task 'spotbugs:setup' do
          FileUtils.mkdir_p File.dirname(target_filters_file)

          config = BuildrPlus::Spotbugs.setup_filter_config
          if File.exist?(project.spotbugs.filter_file)
            content = IO.read(project.spotbugs.filter_file)
            content.gsub!('</FindBugsFilter>', config.rules_as_xml + '</FindBugsFilter>')
            IO.write(target_filters_file, content)
          else
            IO.write(target_filters_file, config.as_xml)
          end
          project.spotbugs.filter_file = target_filters_file
        end

        task 'spotbugs:xml' => %w(spotbugs:setup)
        task 'spotbugs:html' => %w(spotbugs:setup)

        project.task(':domgen:all').enhance([t.name])

        project.clean do
          FileUtils.rm_rf project._(:target, :generated, :spotbugs)
        end
      end
    end

    after_define do |project|
      if project.ipr?
        project.spotbugs.additional_project_names =
          BuildrPlus::Spotbugs.additional_project_names ||
            BuildrPlus::Util.subprojects(project).select {|p| !(p =~ /.*:soap-client$/)}
      end
    end
  end
end
