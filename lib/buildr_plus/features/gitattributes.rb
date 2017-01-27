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
      super(options)
    end

    attr_reader :pattern

    attr_accessor :text
    attr_accessor :binary
    attr_accessor :crlf
    attr_accessor :flags

    def to_s
      text = self.text.nil? ? '' : " #{!!self.text ? '' : '-'}text"
      crlf = self.crlf.nil? ? '' : " #{!!self.crlf ? '' : '-'}crlf"
      binary = self.binary.nil? ? '' : " #{!!self.binary ? '' : '-'}binary"

      "#{pattern}#{text}#{crlf}#{binary}#{self.flags}\n"
    end

    def <=>(other)
      to_s <=> other.to_s
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
      rule(pattern, {:text => true, :crlf => false, :binary => false}.merge(options))
    end

    def binary_rule(pattern, options = {})
      rule(pattern, {:binary => true}.merge(options))
    end

    def process_gitattributes_file(apply_fix)
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.gitattributes"
      if File.exist?(filename)
        content = IO.read(filename)

        original_content = content.dup

        additional_invalid_patterns = []
        gitattributes = build_gitattributes(additional_invalid_patterns)
        (invalid_patterns + additional_invalid_patterns).each do |v|
          content = content.gsub(/^#{Regexp.escape(v)}.*$/, '')
        end

        # Ignores known to be required
        content += "\n" + gitattributes

        # Normalize new lines, order libs and strip duplicates
        content = content.split("\n").collect { |f| f.strip }.select { |f| f.size > 0 }.sort.uniq.join("\n") + "\n"

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
    end

    private

    def add(map, rule)
      map[rule.pattern] = rule
    end

    def invalid_patterns
      [
        '#',
        '*.axl' # Mapping projects
      ]
    end

    def build_gitattributes(invalid_patterns)
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
      add(gitattributes, text_rule('*.css'))
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

      if BuildrPlus::FeatureManager.activated?(:jenkins)
        add(gitattributes, text_rule('Jenkinsfile'))
        add(gitattributes, text_rule('*.groovy'))
      else
        invalid_patterns << 'Jenkinsfile'
        invalid_patterns << '*.groovy'
      end

      if BuildrPlus::FeatureManager.activated?(:rptman)
        add(gitattributes, rule('*.rdl', :text => false, :crlf => true))
      else
        invalid_patterns << '*.rdl'
      end

      invalid_patterns << '*.rhtml'
      invalid_patterns << '*.haml'

      if BuildrPlus::FeatureManager.activated?(:domgen)
        add(gitattributes, text_rule('*.erb'))
      else
        invalid_patterns << '*.erb'
      end

      if BuildrPlus::FeatureManager.activated?(:sass)
        add(gitattributes, text_rule('*.sass'))
        add(gitattributes, text_rule('*.scss'))
      else
        invalid_patterns << '*.sass'
        invalid_patterns << '*.scss'
      end

      if BuildrPlus::FeatureManager.activated?(:less)
        add(gitattributes, text_rule('*.less'))
      else
        invalid_patterns << '*.less'
      end

      if BuildrPlus::FeatureManager.activated?(:less)
        add(gitattributes, text_rule('*.sql'))
      else
        invalid_patterns << '*.sql'
      end

      if BuildrPlus::FeatureManager.activated?(:java)
        add(gitattributes, text_rule('*.java'))
        add(gitattributes, text_rule('*.jsp'))
      else
        invalid_patterns << '*.java'
        invalid_patterns << '*.jsp'
      end

      if BuildrPlus::FeatureManager.activated?(:java)
        add(gitattributes, text_rule('*.properties'))
        add(gitattributes, rule('*.jar', :binary => true))
      else
        invalid_patterns << '*.properties'
        invalid_patterns << '*.jar'
      end

      if BuildrPlus::FeatureManager.activated?(:docker)
        add(gitattributes, text_rule('Dockerfile'))
      else
        invalid_patterns << 'Dockerfile'
      end

      if BuildrPlus::FeatureManager.activated?(:oss)
        add(gitattributes, text_rule('LICENSE'))
        add(gitattributes, text_rule('CHANGELOG'))
      else
        invalid_patterns << 'CHANGELOG'
        invalid_patterns << 'LICENSE'
      end

      # Shell scripts
      add(gitattributes, rule('*.cmd', :crlf => true, :text => true))
      add(gitattributes, rule('*.bat', :crlf => true, :text => true))
      add(gitattributes, text_rule('*.sh'))

      # Native development files
      add(gitattributes, text_rule('*.c'))
      add(gitattributes, binary_rule('*.dll'))
      add(gitattributes, binary_rule('*.so'))

      gitattributes.values.collect { |r| r.to_s }.sort.uniq.join
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
