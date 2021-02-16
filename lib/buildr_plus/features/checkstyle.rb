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

    def rule?(rule)
      @rules.any? { |r| r.rule == rule }
    end

    def remove_rule(rule)
      @rules.delete_if { |r| r.rule == rule }
    end

    def rule(rule, options = {})
      raise "Duplicate checkstyle rule #{rule} for package #{qualified_name}" if rule?(rule)
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
<!DOCTYPE import-control PUBLIC "-//Puppy Crawl//DTD Import Control 1.4//EN" "https://checkstyle.org/dtds/import_control_1_4.dtd">

<import-control pkg="#{name}">
XML
      xml << "\n#{'  ' * indent}<subpackage name=\"#{name}\">\n" unless parent.nil?

      rules.sort_by {|rule| rule.rule == '.*' ? 2 : rule.allow? ? 0 : 1}.each do |r|
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
      content = IO.read(filename)
      doc = REXML::Document.new(content, :attribute_quote => :quote)
      name = doc.root.attributes['pkg']
      root = project.import_rules
      base =
        if name == root.name
          root
        elsif name =~ /^#{Regexp.escape(root.name)}\./
          root.subpackage(name[root.name.length + 1, name.length])
        else
          raise "Unable to merge checkstyle import rules at #{filename} with base #{name} into rules with base at #{root.name}"
        end

      parse_package_elements(base, doc.root.elements)
    end

    def self.parse_package_elements(subpackage, elements)
      elements.each do |element|
        if element.name == 'allow' || element.name == 'disallow'
          rule_type = element.attributes['pkg'].nil? ? :class : :package
          rule = element.attributes['pkg'] || element.attributes['class']

          # If the user has specified a rule that overrides existing rule then remove existing rule
          subpackage.remove_rule(rule) if subpackage.rule?(rule)

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
    attr_writer :modern_checkstyle_rule_type

    def modern_checkstyle_rule_type?
      @modern_checkstyle_rule_type.nil? ? BuildrPlus::FeatureManager.activated?(:react4j) : !!@modern_checkstyle_rule_type
    end

    def default_checkstyle_rules
      "au.com.stocksoftware.checkstyle:checkstyle#{modern_checkstyle_rule_type? ? '-ng' : ''}:xml:1.19"
    end

    def checkstyle_rules
      @checkstyle_rules || self.default_checkstyle_rules
    end

    attr_writer :checkstyle_rules

    attr_accessor :additional_project_names

    def setup_checkstyle_import_rules(project, allow_any_imports)
      r = project.import_rules
      g = project.java_package_name
      c = project.name_as_class
      r.rule('.*', :regex => true, :rule_type => :class) if allow_any_imports
      r.rule('edu.umd.cs.findbugs.annotations.SuppressFBWarnings', :rule_type => :class)
      r.rule('edu.umd.cs.findbugs.annotations.SuppressWarnings', :rule_type => :class, :disallow => true)
      r.rule('org.jetbrains.annotations.NotNull', :rule_type => :class, :disallow => true)
      r.rule('org.jetbrains.annotations.Nullable', :rule_type => :class, :disallow => true)
      r.rule('org.testng.internal.Nullable', :rule_type => :class, :disallow => true)
      r.rule('com.sun.istack.NotNull', :rule_type => :class, :disallow => true)
      r.rule('com.sun.istack.Nullable', :rule_type => :class, :disallow => true)
      r.rule('com.sun.istack.internal.NotNull', :rule_type => :class, :disallow => true)
      r.rule('com.sun.istack.internal.Nullable', :rule_type => :class, :disallow => true)
      r.rule('org.mockito.internal.matchers.NotNull', :rule_type => :class, :disallow => true)
      r.rule('edu.umd.cs.findbugs.annotations.Nonnull', :rule_type => :class, :disallow => true)
      r.rule('edu.umd.cs.findbugs.annotations.Nullable', :rule_type => :class, :disallow => true)
      r.rule('javax.faces.bean', :disallow => true)
      r.rule('org.hamcrest', :disallow => true)

      r.rule('java.util')
      r.subpackage_rule('server', 'java.nio.charset.StandardCharsets', :rule_type => :class)
      r.subpackage_rule('server', 'java.time')

      if BuildrPlus::FeatureManager.activated?(:graphql)
        r.subpackage_rule('server.service', 'graphql.schema')
        r.subpackage_rule('server.service', 'graphql.servlet.config.GraphQLSchemaProvider', :rule_type => :class)
      end

      if BuildrPlus::FeatureManager.activated?(:giggle)
        r.subpackage_rule('server.service', "#{g}.server.graphql")
      end

      if BuildrPlus::FeatureManager.activated?(:appconfig)
        r.rule("#{g}.shared.#{project.name_as_class}FeatureFlags", :rule_type => :class)
      end

      if BuildrPlus::FeatureManager.activated?(:gwt)
        # If arez is enabled then we assume we are using modern GWT, otherwise we can use the old stuff
        if BuildrPlus::FeatureManager.activated?(:arez)
          r.subpackage_rule('client', 'com.google.inject', :disallow => true)
          r.subpackage_rule('client', 'com.google.gwt', :disallow => true)
        end

        r.subpackage_rule('client', 'com.google.gwt.user.client.rpc.AsyncCallback', :rule_type => :class)

        # TODO: Remove this next line when we figure out the solution
        r.subpackage_rule('client', 'com.google.gwt.i18n.shared.DateTimeFormat', :rule_type => :class)
        r.subpackage_rule('client', 'com.google.gwt.i18n.client.DateTimeFormat', :rule_type => :class)

        # We will keep this rule until we figure out a way ala GWT 3 for resources
        r.subpackage_rule('client', 'com.google.gwt.resources.client')

        r.subpackage_rule('client', 'sting.Injectable', :rule_type => :class)
        r.subpackage_rule('client', 'sting.Fragment', :rule_type => :class)
        r.subpackage_rule('client', "#{g}.shared")
        r.subpackage_rule('client', "#{g}.client")
        r.subpackage_rule('client.ioc', 'sting')

        # TODO: Remove this once we move to GWT 3
        r.subpackage_rule('client.ioc', 'com.google.gwt.core.client.GWT', :rule_type => :class)
        r.subpackage_rule('client', 'com.google.gwt.core.client.GWT', :rule_type => :class, :local_only => true)

        if BuildrPlus::FeatureManager.activated?(:keycloak)
          r.subpackage_rule('client', 'org.realityforge.gwt.keycloak.Keycloak', :rule_type => :class)
        end

        if BuildrPlus::FeatureManager.activated?(:iris_audit)
          r.subpackage_rule('client.ioc', 'iris.audit.client.ioc.AuditGwtRpcServicesFragment', :rule_type => :class)
        end

        if BuildrPlus::FeatureManager.activated?(:arez)
          r.subpackage_rule('client', 'javax.xml.ws.Action', :rule_type => :class, :disallow => true)
        end

        if BuildrPlus::FeatureManager.activated?(:replicant)
          r.subpackage_rule('client', 'org.realityforge.replicant.shared')
          r.subpackage_rule('client', 'org.realityforge.replicant.client')
        end
      end

      if BuildrPlus::FeatureManager.activated?(:keycloak)
        r.subpackage_rule('server.filter', "#{g}.shared.#{c}KeycloakClients", :rule_type => :class)
      end

      if BuildrPlus::FeatureManager.activated?(:ejb)
        r.subpackage_rule('server.entity', 'javax.persistence')
        r.subpackage_rule('server.entity', "#{g}.server.data_type")
        r.subpackage_rule('server.entity', "#{g}.server.entity")
      end

      if BuildrPlus::FeatureManager.activated?(:ejb)
        r.rule('javax.annotation')
        r.subpackage_rule('server', 'javax.enterprise.context.ApplicationScoped', :rule_type => :class)
        r.subpackage_rule('server', 'javax.transaction.Transactional', :rule_type => :class)
        r.subpackage_rule('server', 'javax.enterprise.inject.Typed', :rule_type => :class)
        r.subpackage_rule('server', 'javax.enterprise.inject.Produces', :rule_type => :class)
        r.subpackage_rule('server', 'javax.inject')
        r.subpackage_rule('server', 'javax.ejb')
        r.subpackage_rule('server', 'javax.ejb.EJB', :rule_type => :class, :disallow => true)
        r.subpackage_rule('server', 'javax.ejb.Asynchronous', :rule_type => :class, :disallow => true)

        if BuildrPlus::FeatureManager.activated?(:geolatte)
          r.subpackage_rule('server', 'org.geolatte.geom')
        end

        r.subpackage_rule('server.service', "#{g}.server.data_type")
        r.subpackage_rule('server.service', "#{g}.server.entity")
        r.subpackage_rule('server.service', "#{g}.server.service")
        r.subpackage_rule('server.service', 'javax.persistence')
        r.subpackage_rule('server.service', 'javax.validation')
        if BuildrPlus::FeatureManager.activated?(:replicant)
          r.subpackage_rule('server.net', "#{g}.shared.net")
          r.subpackage_rule('server.service', "#{g}.server.net")
          r.subpackage_rule('server.service', 'org.realityforge.replicant.server.transport.ReplicantSession', :rule_type => :class)
          r.subpackage_rule('server.service', 'org.realityforge.replicant.server.EntityMessage', :rule_type => :class)
          r.subpackage_rule('server.service', 'org.realityforge.replicant.server.EntityMessageSet', :rule_type => :class)

          # The following is for test infrastructure
          r.subpackage_rule('client.entity', 'com.google.inject.Injector', :rule_type => :class)
          r.subpackage_rule('client.entity', 'org.realityforge.guiceyloops.shared.ValueUtil', :rule_type => :class)
        end

        if BuildrPlus::FeatureManager.activated?(:mail)
          r.subpackage_rule('server.service', 'javax.mail')
          r.subpackage_rule('server.service', 'iris.mail.server.data_type')
          r.subpackage_rule('server.service', 'iris.mail.server.service')
        end
        if BuildrPlus::FeatureManager.activated?(:appconfig)
          r.subpackage_rule('server.service', 'iris.appconfig.server.entity')
          r.subpackage_rule('server.service', 'iris.appconfig.server.service')
        end
        if BuildrPlus::FeatureManager.activated?(:syncrecord)
          r.subpackage_rule('server.service', 'iris.syncrecord.server.data_type')
          r.subpackage_rule('server.service', 'iris.syncrecord.server.entity')
          r.subpackage_rule('server.service', 'iris.syncrecord.server.service')
          r.subpackage_rule('server.service', 'iris.syncrecord.client.rest')
        end
      end

      if BuildrPlus::FeatureManager.activated?(:jaxrs)
        r.subpackage_rule('server.rest', 'javax.ws.rs')
        r.subpackage_rule('server.rest', 'javax.json')
        r.subpackage_rule('server.rest', 'javax.xml')
        r.subpackage_rule('server.rest', 'javax.validation')
        r.subpackage_rule('server.rest', 'javax.servlet')
        r.subpackage_rule('server.rest', "#{g}.server.data_type")
        r.subpackage_rule('server.rest', "#{g}.server.entity")
        r.subpackage_rule('server.rest', "#{g}.server.service")
        r.subpackage_rule('server.rest', "#{g}.server.rest")
        if BuildrPlus::FeatureManager.activated?(:replicant)
          r.subpackage_rule('server.rest', 'org.realityforge.replicant.server.ee.rest')
        end

        if BuildrPlus::FeatureManager.activated?(:appconfig)
          r.subpackage_rule('server.rest', 'org.realityforge.rest.field_filter')
          r.subpackage_rule('server.rest', 'iris.appconfig.server.rest')
          r.subpackage_rule('server.rest', 'iris.appconfig.server.entity')
          r.subpackage_rule('server.rest', 'iris.appconfig.server.service')
        end
        if BuildrPlus::FeatureManager.activated?(:syncrecord)
          r.subpackage_rule('server.rest', 'iris.syncrecord.server.data_type')
          r.subpackage_rule('server.rest', 'iris.syncrecord.server.rest')
          r.subpackage_rule('server.rest', 'iris.syncrecord.server.entity')
        end

        if BuildrPlus::FeatureManager.activated?(:keycloak)
          r.subpackage_rule('server.filter', 'org.realityforge.keycloak.domgen.KeycloakUrlFilter', :rule_type => :class)
        end

        r.subpackage_rule('server.filter', 'java.io.IOException', :rule_type => :class)
        r.subpackage_rule('server.filter', 'java.io.InputStream', :rule_type => :class)
        r.subpackage_rule('server.filter', 'javax.servlet')
        r.subpackage_rule('server.filter', "#{g}.server.data_type")
        r.subpackage_rule('server.filter', "#{g}.server.entity")
        r.subpackage_rule('server.filter', "#{g}.server.service")

        r.subpackage_rule('server.servlet', 'java.io.IOException', :rule_type => :class)
        r.subpackage_rule('server.servlet', 'java.io.InputStream', :rule_type => :class)
        r.subpackage_rule('server.servlet', 'javax.servlet')
        r.subpackage_rule('server.servlet', "#{g}.server.data_type")
        r.subpackage_rule('server.servlet', "#{g}.server.entity")
        r.subpackage_rule('server.servlet', "#{g}.server.service")
      end
      r.subpackage_rule('server.test.util', "#{g}.server.data_type")
      r.subpackage_rule('server.test.util', "#{g}.server.entity")
      r.subpackage_rule('server.test.util', "#{g}.server.service")
      r.subpackage_rule('server.test.util', 'org.testng')
      r.subpackage_rule('server.test.util', 'org.mockito')
      r.subpackage_rule('server.test.util', 'org.realityforge.guiceyloops')
      r.subpackage_rule('server.test.util', 'com.google.inject')
      r.subpackage_rule('server.test.util', 'javax.persistence')

      if BuildrPlus::FeatureManager.activated?(:replicant)
        r.subpackage_rule('server.test.util', "#{g}.server.net")
        r.subpackage_rule('server.test.util', 'javax.transaction.TransactionSynchronizationRegistry', :rule_type => :class)
      end

      if BuildrPlus::FeatureManager.activated?(:appconfig)
        r.subpackage_rule('server.test.util', 'iris.appconfig.server.entity')
        r.subpackage_rule('server.test.util', 'iris.appconfig.server.service')
        r.subpackage_rule('server.test.util', 'iris.appconfig.server.test.util')
      end
      if BuildrPlus::FeatureManager.activated?(:mail)
        r.subpackage_rule('server.test.util', 'javax.mail')
        r.subpackage_rule('server.test.util', 'iris.mail.server.entity')
        r.subpackage_rule('server.test.util', 'iris.mail.server.service')
        r.subpackage_rule('server.test.util', 'iris.mail.server.test.util')
      end
      if BuildrPlus::FeatureManager.activated?(:syncrecord)
        r.subpackage_rule('server.test.util', 'iris.syncrecord.server.data_type')
        r.subpackage_rule('server.test.util', 'iris.syncrecord.server.entity')
        r.subpackage_rule('server.test.util', 'iris.syncrecord.server.service')
        r.subpackage_rule('server.test.util', 'iris.syncrecord.server.test.util')
      end
    end
  end

  f.enhance(:ProjectExtension) do
    def import_rules
      @import_rules ||= BuildrPlus::Checkstyle::Subpackage.new(nil, self.root_project.java_package_name)
    end

    first_time do
      require 'buildr/checkstyle'

      class Buildr::Checkstyle::Config
        def enabled?
          project.ipr?
        end
      end

      module ::Buildr::Checkstyle
        class << self
          # The specs for requirements
          def dependencies
            %w(
              com.puppycrawl.tools:checkstyle:jar:8.40
              org.antlr:antlr4-runtime:jar:4.9.1
              antlr:antlr:jar:2.7.7

              com.google.guava:guava:jar:30.0-jre
              commons-beanutils:commons-beanutils:jar:1.9.4
              commons-logging:commons-logging:jar:1.2
              commons-collections:commons-collections:jar:3.2.2
              info.picocli:picocli:jar:4.6.1
              net.sf.saxon:Saxon-HE:jar:10.3
              com.ibm.icu:icu4j:jar:63.1

              org.javassist:javassist:jar:3.26.0-GA
              org.reflections:reflections:jar:0.9.12
            )
          end
        end
      end
    end

    before_define do |project|
      if project.ipr?
        project.checkstyle.config_directory = project._('etc/checkstyle')

        original_suppressions_file = project.checkstyle.suppressions_file
        unless File.exist?(original_suppressions_file)
          original_suppressions_file = "#{File.expand_path(File.dirname(__FILE__))}/checkstyle_suppressions.xml"
        end

        checkstyle_dir = project._(:target, :generated, :checkstyle)
        checkstyle_import_rules = "#{checkstyle_dir}/import-control.xml"
        checkstyle_check_rules = "#{checkstyle_dir}/rules.xml"
        checkstyle_suppressions = "#{checkstyle_dir}/suppressions.xml"

        project.checkstyle.configuration_file = checkstyle_check_rules
        project.checkstyle.suppressions_file = checkstyle_suppressions
        project.checkstyle.properties['checkstyle.suppressions.file'] = checkstyle_suppressions
        project.checkstyle.properties['checkstyle.import-control.file'] = checkstyle_import_rules

        t = task 'checkstyle:setup' do
          FileUtils.mkdir_p checkstyle_dir
          File.open(checkstyle_import_rules, 'wb') do |file|
            file.write project.import_rules.as_xml
          end

          supressions = IO.read(original_suppressions_file)
          File.open(checkstyle_suppressions, 'wb') do |file|
            file.write supressions
          end

          a = Buildr.artifact(BuildrPlus::Checkstyle.checkstyle_rules)
          a.invoke
          rules = IO.read(a.to_s)
          if BuildrPlus::FeatureManager.activated?(:timeservice)
            rules.gsub!("<module name=\"Checker\">\n", <<RULES)
<module name="Checker">
  <module name="RegexpSingleline">
    <property name="id" value="noLocalDateNow"/>
    <property name="format" value="LocalDate\\.now\\(\\)"/>
    <property name="message" value="Avoid the use of LocalDate.now(). Use TimeService.currentLocalDate()"/>
  </module>
  <module name="RegexpSingleline">
    <property name="id" value="noLocalDateTimeNow"/>
    <property name="format" value="LocalDateTime\\.now\\(\\)"/>
    <property name="message" value="Avoid the use of LocalDateTime.now(). Use TimeService.currentLocalDateTime()"/>
  </module>
  <module name="RegexpSingleline">
    <property name="id" value="noNewDate"/>
    <property name="format" value="new Date\\(\\)"/>
    <property name="message" value="Avoid the use of new Date(). Use TimeService.currentDate()"/>
  </module>
  <module name="RegexpSingleline">
    <property name="id" value="noSystemCurrentTimeMillis"/>
    <property name="format" value="System\\.currentTimeMillis\\(\\)"/>
    <property name="message" value="Avoid the use of System.currentTimeMillis(). Use TimeService.currentTimeMillis()"/>
  </module>

RULES
          end
          File.open(checkstyle_check_rules, 'wb') do |file|
            file.write rules
          end
        end

        task 'checkstyle:xml' => %w(checkstyle:setup)

        project.task(':domgen:all').enhance([t.name])

        project.clean do
          FileUtils.rm_rf project._(:target, :generated, 'checkstyle')
        end

        project.checkstyle.properties['checkstyle.import-control.file'] = checkstyle_import_rules
      end
    end

    after_define do |project|
      if project.ipr?
        import_control_present = File.exist?(project.checkstyle.import_control_file)
        BuildrPlus::Checkstyle.setup_checkstyle_import_rules(project, !import_control_present)
        BuildrPlus::Checkstyle::Parser.merge_existing_import_control_file(project) if import_control_present

        project.checkstyle.additional_project_names =
          BuildrPlus::Spotbugs.additional_project_names || BuildrPlus::Util.subprojects(project)
      end
    end
  end
end
