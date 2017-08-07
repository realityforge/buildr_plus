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

module BuildrPlus::Gitattributes
  class Rule < Reality::BaseElement
    def initialize(pattern, options = {})
      @pattern = pattern
      @priority = 1
      super(options)
    end

    attr_reader :pattern

    attr_accessor :text
    attr_accessor :binary
    attr_accessor :eol
    attr_accessor :eofnl
    attr_accessor :flags
    attr_accessor :priority

    def to_s
      text = self.text.nil? ? '' : " #{!!self.text ? '' : '-'}text"
      eol = self.eol.nil? ? '' : " eol=#{self.eol}"
      binary = self.binary.nil? ? '' : " #{!!self.binary ? '' : '-'}binary"
      eofnl = self.eofnl.nil? ? '' : " #{!!self.eofnl ? '' : '-'}eofnl"
      flags = self.flags.nil? ? '' : " #{self.flags}"

      "#{pattern}#{text}#{eol}#{binary}#{eofnl}#{flags}\n"
    end

    def <=>(other)
      order = self.priority <=> other.priority
      if 0 != order
        order
      else
        to_s <=> other.to_s
      end
    end
  end
end

BuildrPlus::FeatureManager.feature(:gitattributes) do |f|
  f.enhance(:Config) do
    attr_writer :gitattributes_needs_update

    def gitattributes_needs_update?
      @gitattributes_needs_update.nil? ? false : !!@gitattributes_needs_update
    end

    def rule(pattern, options = {})
      BuildrPlus::Gitattributes::Rule.new(pattern, options)
    end

    def text_rule(pattern, options = {})
      rule(pattern, { :text => true, :eol => 'lf' }.merge(options))
    end

    def dos_text_rule(pattern, options = {})
      rule(pattern, { :text => true, :eol => 'crlf' }.merge(options))
    end

    def binary_rule(pattern, options = {})
      rule(pattern, { :binary => true }.merge(options))
    end

    def additional_rules
      @additional_rules ||= []
    end

    def process_gitattributes_file(apply_fix)
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.gitattributes"
      content = File.exist?(filename) ? IO.read(filename) : ''

      original_content = content.dup

      content = build_gitattributes

      if content != original_content
        BuildrPlus::Gitattributes.gitattributes_needs_update = true
        if apply_fix
          puts 'Fixing: .gitattributes'
          File.open(filename, 'wb') do |out|
            out.write content
          end
        else
          puts 'Non-normalized .gitattributes'
        end
      end
    end

    private

    def add(map, rule)
      map[rule.pattern] = rule
    end

    def build_gitattributes
      gitattributes = {}

      # Default
      add(gitattributes, rule('*', :text => false))
      add(gitattributes, text_rule('.gitignore'))
      add(gitattributes, text_rule('.gitattributes'))

      # Ruby defaults
      add(gitattributes, text_rule('Gemfile'))
      add(gitattributes, text_rule('*.gemspec'))
      add(gitattributes, text_rule('.ruby-version'))
      add(gitattributes, text_rule('*.rb'))
      add(gitattributes, text_rule('*.yaml'))
      add(gitattributes, text_rule('*.yml'))

      # Documentation defaults
      add(gitattributes, text_rule('*.txt'))
      add(gitattributes, text_rule('*.md'))
      add(gitattributes, text_rule('*.textile'))
      add(gitattributes, text_rule('*.rdoc'))
      add(gitattributes, text_rule('*.html'))
      add(gitattributes, text_rule('*.xhtml'))
      add(gitattributes, text_rule('*.css', :flags => 'encoding=UTF8'))
      add(gitattributes, text_rule('*.js'))
      add(gitattributes, binary_rule('*.jpg'))
      add(gitattributes, binary_rule('*.jpeg'))
      add(gitattributes, binary_rule('*.png'))
      add(gitattributes, binary_rule('*.bmp'))
      add(gitattributes, binary_rule('*.ico'))

      add(gitattributes, binary_rule('*.pdf'))
      add(gitattributes, binary_rule('*.doc'))

      # Common file formats
      add(gitattributes, text_rule('*.json'))
      add(gitattributes, text_rule('*.xml'))
      add(gitattributes, text_rule('*.xsd'))
      add(gitattributes, text_rule('*.xsl'))
      add(gitattributes, text_rule('*.wsdl'))

      # Build system defaults
      add(gitattributes, text_rule('buildfile'))
      add(gitattributes, text_rule('Buildfile'))
      add(gitattributes, text_rule('Rakefile'))
      add(gitattributes, text_rule('rakefile'))
      add(gitattributes, text_rule('*.rake'))

      if BuildrPlus::FeatureManager.activated?(:graphql)
        add(gitattributes, text_rule('*.graphql'))
      end

      if BuildrPlus::FeatureManager.activated?(:javascript)
        add(gitattributes, text_rule('*.ts'))
        add(gitattributes, text_rule('*.tsx'))
      end

      if BuildrPlus::FeatureManager.activated?(:typescript)
        add(gitattributes, text_rule('*.ts'))
        add(gitattributes, text_rule('*.tsx'))
      end

      if BuildrPlus::FeatureManager.activated?(:jenkins)
        add(gitattributes, text_rule('Jenkinsfile'))
        add(gitattributes, text_rule('*.groovy'))
      end

      if BuildrPlus::FeatureManager.activated?(:rptman)
        add(gitattributes, dos_text_rule('*.rdl', :eofnl => false))
      end

      if BuildrPlus::FeatureManager.activated?(:domgen)
        add(gitattributes, text_rule('*.erb'))
      end

      if BuildrPlus::FeatureManager.activated?(:sass)
        add(gitattributes, text_rule('*.sass'))
        add(gitattributes, text_rule('*.scss'))
      end

      if BuildrPlus::FeatureManager.activated?(:less)
        add(gitattributes, text_rule('*.less'))
      end

      if BuildrPlus::FeatureManager.activated?(:db)
        add(gitattributes, text_rule('*.sql'))
      end

      if BuildrPlus::FeatureManager.activated?(:java)
        add(gitattributes, text_rule('*.java'))
        add(gitattributes, text_rule('*.jsp'))
      end

      if BuildrPlus::FeatureManager.activated?(:java)
        add(gitattributes, text_rule('*.properties'))
        add(gitattributes, rule('*.jar', :binary => true))
      end

      if BuildrPlus::FeatureManager.activated?(:docker)
        add(gitattributes, text_rule('Dockerfile'))
      end

      if BuildrPlus::FeatureManager.activated?(:oss)
        add(gitattributes, text_rule('LICENSE'))
        add(gitattributes, text_rule('CHANGELOG'))
      end

      # Shell scripts
      add(gitattributes, dos_text_rule('*.cmd'))
      add(gitattributes, dos_text_rule('*.bat'))
      add(gitattributes, text_rule('*.sh'))

      # Native development files
      add(gitattributes, text_rule('*.c'))
      add(gitattributes, binary_rule('*.dll'))
      add(gitattributes, binary_rule('*.so'))

      additional_rules.each do |r|
        add(gitattributes, r)
      end

      "# DO NOT EDIT: File is auto-generated\n" + gitattributes.values.sort.collect {|r| r.to_s}.uniq.join
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check .gitattributes has been normalized.'
    task 'gitattributes:check' do
      BuildrPlus::Gitattributes.process_gitattributes_file(false)
      if BuildrPlus::Gitattributes.gitattributes_needs_update?
        raise '.gitattributes has not been normalized. Please run "buildr gitattributes:fix" and commit changes.'
      end
    end

    desc 'Normalize .gitattributes.'
    task 'gitattributes:fix' do
      BuildrPlus::Gitattributes.process_gitattributes_file(true)
    end
  end
end
