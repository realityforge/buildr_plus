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

require 'rexml/document'

module BuildrPlus::Checkstyle
  class Rule
    def initialize(rule, options = {})
      @rule = rule
      @allow = !options[:disallow]
      @package_rule = !(options[:rule_type] == :class)
      @exact_match = !!options[:exact_match]
      @local_only = !!options[:local_only]
      @regex = !!options[:regex]
    end

    attr_reader :rule

    def allow?
      !!@allow
    end

    def package_rule?
      !!@package_rule
    end

    def exact_match?
      !!@exact_match
    end

    def local_only?
      !!@local_only
    end

    def regex?
      !!@regex
    end

    def as_xml(indent = 0)
      "#{'  ' * indent}<#{allow? ? 'allow' : 'disallow' } #{package_rule? ? 'pkg' : 'class'}=\"#{rule}\"#{local_only? ? " local-only=\"true\"" : ''}#{regex? ? " regex=\"true\"" : ''}#{exact_match? ? " exact-match=\"true\"" : ''}/>\n"
    end
  end

  class Subpackage
    attr_reader :parent
    attr_reader :name

    def initialize(parent, name)
      @parent, @name = parent, name
      @rules = []
      @subpackages = {}
    end

    def qualified_name
      "#{parent.nil? ? '' : "#{parent.qualified_name}."}#{name}"
    end

    def rule(rule, options = {})
      raise "Duplicate checkstyle rule #{rule} for package #{qualified_name}" if @rules.any? { |r| r.rule == rule }
      @rules << Rule.new(rule, options)
    end

    def rules
      @rules.dup
    end

    def subpackage(path)
      path_elements = path.split('.')
      path_element = path_elements.first
      subpackage = (@subpackages[path_element] ||= Subpackage.new(self, path_element))
      path_elements.size == 1 ? subpackage : subpackage.subpackage(path_elements[1, path_elements.size].join('.'))
    end

    def subpackages
      @subpackages.values.dup
    end

    def subpackage_rule(subpackage_name, rule, options = {})
      subpackage(subpackage_name).rule(rule, options)
    end

    def as_xml(indent = 0)
      xml = ''
      xml << <<XML if parent.nil?
<?xml version="1.0"?>
<!-- DO NOT EDIT: File is auto-generated -->
<!DOCTYPE import-control PUBLIC
  "-//Puppy Crawl//DTD Import Control 1.1//EN"
  "http://www.puppycrawl.com/dtds/import_control_1_1.dtd">

<import-control pkg="#{name}">
XML
      xml << "\n#{'  ' * indent}<subpackage name=\"#{name}\">\n" unless parent.nil?

      rules.each do |r|
        xml << r.as_xml(indent + 1)
      end

      subpackages.each do |s|
        xml << s.as_xml(indent + 1)
      end

      xml << "#{'  ' * indent}</subpackage>\n" unless parent.nil?
      xml << "</import-control>\n" if parent.nil?

      xml
    end
  end

  class Parser
    def self.merge_existing_import_control_file(project)
      filename = project.checkstyle.import_control_file
      if File.exist?(filename)
        content = IO.read(filename)
        doc = REXML::Document.new(content, :attribute_quote => :quote)
        name = doc.root.attributes['pkg']
        root = project.import_rules
        base =
          if name == root.name
            root
          elsif name =~ /^#{Regexp.replace(root.name)}\./
            root.subpackage(name[root.name.length + 1, name.length])
          else
            raise "Unable to merge checkstyle import rules at #{filename} with base #{name} into rules with base at #{root.name}"
          end

        parse_package_elements(base, doc.root.elements)
      end
    end

    def self.parse_package_elements(subpackage, elements)
      elements.each do |element|
        if element.name == 'allow' || element.name == 'disallow'
          rule_type = element.attributes['pkg'].nil? ? :class : :package
          rule = element.attributes['pkg'] || element.attributes['class']

          subpackage.rule(rule,
                          :disallow => (element.name == 'disallow'),
                          :rule_type => rule_type,
                          :exact_match => element.attributes['exact-match'] == 'true',
                          :local_only => element.attributes['local-only'] == 'true',
                          :regex => element.attributes['regex'] == 'true')
        elsif element.name == 'subpackage'
          name = element.attributes['name']
          parse_package_elements(subpackage.subpackage(name), element.elements)
        end
      end
    end
  end
end

BuildrPlus::FeatureManager.feature(:checkstyle) do |f|
  f.enhance(:Config) do
    def default_checkstyle_rules
      'au.com.stocksoftware.checkstyle:checkstyle:xml:1.8'
    end

    def checkstyle_rules
      @checkstyle_rules || self.default_checkstyle_rules
    end

    attr_writer :checkstyle_rules

    attr_accessor :additional_project_names

    def setup_checkstyle_import_rules(project)
      r = project.import_rules
      g = project.group
      r.rule('edu.umd.cs.findbugs.annotations.SuppressFBWarnings', :rule_type => :class)
      r.rule('edu.umd.cs.findbugs.annotations.SuppressWarnings', :rule_type => :class, :disallow => true)

      r.rule('java.util')

      if BuildrPlus::FeatureManager.activated?(:ejb)
        r.subpackage_rule('server.entity', 'javax.persistence')
      end

      if BuildrPlus::FeatureManager.activated?(:ejb)
        r.rule('javax.annotation')
        r.subpackage_rule('server', 'javax.enterprise.context.ApplicationScoped', :rule_type => :class)
        r.subpackage_rule('server', 'javax.transaction.Transactional', :rule_type => :class)
        r.subpackage_rule('server', 'javax.enterprise.inject.Typed', :rule_type => :class)
        r.subpackage_rule('server', 'javax.inject')
        r.subpackage_rule('server', 'javax.ejb')
        r.subpackage_rule('server', 'javax.ejb.EJB', :rule_type => :class, :disallow => true)
        r.subpackage_rule('server', 'javax.ejb.Asynchronous', :rule_type => :class, :disallow => true)

        r.subpackage_rule('server.service', "#{g}.server.data_type")
        r.subpackage_rule('server.service', "#{g}.server.entity")
        r.subpackage_rule('server.service', "#{g}.server.service")
      end

      if BuildrPlus::FeatureManager.activated?(:jaxrs)
        r.subpackage_rule('server', 'javax.ws.rs')
        r.subpackage_rule('server', 'javax.json')
        r.subpackage_rule('server', 'javax.xml')
        r.subpackage_rule('server.rest', "#{g}.server.data_type")
        r.subpackage_rule('server.rest', "#{g}.server.entity")
        r.subpackage_rule('server.rest', "#{g}.server.service")
      end
    end
  end

  f.enhance(:ProjectExtension) do
    def import_rules
      @import_rules ||= BuildrPlus::Checkstyle::Subpackage.new(nil, self.root_project.group)
    end

    first_time do
      require 'buildr/checkstyle'
    end

    before_define do |project|
      if project.ipr?
        BuildrPlus::Checkstyle.setup_checkstyle_import_rules(project)

        project.checkstyle.config_directory = project._('etc/checkstyle')
        project.checkstyle.configuration_artifact = BuildrPlus::Checkstyle.checkstyle_rules

        import_control_present = File.exist?(project.checkstyle.import_control_file)

        BuildrPlus::Checkstyle::Parser.merge_existing_import_control_file(project)

        unless File.exist?(project.checkstyle.suppressions_file)
          dir = File.expand_path(File.dirname(__FILE__))
          project.checkstyle.suppressions_file =
            import_control_present ?
              "#{dir}/checkstyle_suppressions.xml" :
              "#{dir}/checkstyle_suppressions_no_import_control.xml"
        end

        checkstyle_import_rules = project._(:target, :generated, 'checkstyle/import-control.xml')

        t = task 'checkstyle:setup' do
          FileUtils.mkdir_p File.dirname(checkstyle_import_rules)
          File.open(checkstyle_import_rules, 'wb') do |f|
            f.write project.import_rules.as_xml
          end
        end

        task 'checkstyle:xml' => %w(checkstyle:setup)

        project.task(':domgen:all').enhance([t.name])

        project.clean do
          FileUtils.rm_rf project._(:target, :generated, 'checkstyle')
        end

        if import_control_present
          project.checkstyle.properties['checkstyle.import-control.file'] = checkstyle_import_rules
        else
          project.checkstyle.properties['checkstyle.import-control.file'] = ''
        end
      end
    end

    after_define do |project|
      if project.ipr?
        project.checkstyle.additional_project_names =
          BuildrPlus::Findbugs.additional_project_names || BuildrPlus::Util.subprojects(project)
      end
    end
  end
end
