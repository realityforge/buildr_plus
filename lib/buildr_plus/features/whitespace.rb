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
BuildrPlus::FeatureManager.feature(:whitespace) do |f|
  f.enhance(:Config) do
    attr_writer :whitespace_needs_update

    def whitespace_needs_update?
      @whitespace_needs_update.nil? ? false : !!@whitespace_needs_update
    end

    def process_dos_whitespace_files(apply_fix)
      files = BuildrPlus::Whitespace.collect_files(%w(rdl), %w())

      files.each do |filename|
        content = File.read(filename)
        original_content = content.dup
        content = clean_dos_whitespace(filename, content)
        if content != original_content
          BuildrPlus::Whitespace.whitespace_needs_update = true
          if apply_fix
            puts "Fixing: #{filename}"
            File.open(filename, 'wb') do |out|
              out.write content
            end
          else
            puts "Non-normalized dos whitespace in #{filename}"
          end
        end
      end
    end

    def process_whitespace_files(apply_fix)
      extensions = %w(jsp sass scss xsl sql haml less rake xml html gemspec properties yml yaml css rb java xhtml rdoc txt erb gitattributes gitignore xsd textile md wsdl sh)
      filenames = %w(Jenkinsfile rakefile Rakefile buildfile Buildfile Gemfile LICENSE)

      files_to_remove_duplicate_newlines = Dir['etc/checkstyle/*.xml'].flatten + Dir['tasks/*.rake'].flatten + Dir['**/*.md'].flatten + Dir['config/*.sh'].flatten + %w(buildfile Gemfile README.md)

      files = BuildrPlus::Whitespace.collect_files(extensions, filenames)

      files.each do |filename|
        content = File.read(filename)
        original_content = content.dup
        content = clean_whitespace(filename, content)
        content.gsub!(/\n\n\n/, "\n\n") if files_to_remove_duplicate_newlines.include?(filename)

        if content != original_content
          BuildrPlus::Whitespace.whitespace_needs_update = true
          if apply_fix
            puts "Fixing: #{filename}"
            File.open(filename, 'wb') do |out|
              out.write content
            end
          else
            puts "Non-normalized whitespace in #{filename}"
          end
        end
      end
    end

    protected

    def collect_files(extensions, full_filenames)
      `git ls-files`.split("\n").select do |f|
        is_vendor = /^vendor\/.*/ =~ f
        matches_extension = extensions.any? { |ext| f =~ /.*\.#{ext}/ }

        matches_filename = full_filenames.any? { |filename| filename == File.basename(f) }
        !is_vendor && (matches_extension || matches_filename)
      end
    end

    def clean_whitespace(filename, content)
      content = patch_encoding(content)
      begin
        content.gsub!(/\r\n/, "\n")
        content.gsub!(/[ \t]+\n/, "\n")
        content.gsub!(/[ \r\t\n]+\Z/, '')
        content += "\n"
      rescue
        puts "Skipping whitespace cleanup: #{filename}"
      end
      content
    end

    def clean_dos_whitespace(filename, content)
      content = patch_encoding(content)
      begin
        content.gsub!(/\r\n/, "\n")
        content.gsub!(/[ \t]+\n/, "\n")
        content.gsub!(/[ \r\t\n]+\Z/, '')
        content += "\n" unless /.*\.rdl$/ =~ filename # Don't add EOL for SSRS reports
        content.gsub!(/\n/, "\r\n")
      rescue
        puts "Skipping dos whitespace cleanup: #{filename}"
      end
      content
    end

    def patch_encoding(content)
      content =
        content.respond_to?(:encode!) ?
          content.encode!('UTF-8', 'binary', :invalid => :replace, :undef => :replace, :replace => '') :
          content
      content.gsub!(/^\xEF\xBB\xBF/, '')
      content
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check whitespace has been normalized.'
    task 'whitespace:check_whitespace' do
      BuildrPlus::Whitespace.process_whitespace_files(false)
      if BuildrPlus::Whitespace.whitespace_needs_update?
        raise 'Whitespace has not been normalized. Please run "buildr whitespace:fix_whitespace" and commit changes.'
      end
    end

    desc 'Normalize whitespace.'
    task 'whitespace:fix_whitespace' do
      BuildrPlus::Whitespace.process_whitespace_files(true)
    end

    desc 'Check whitespace has been normalized for dos files.'
    task 'whitespace:check_dos_whitespace' do
      BuildrPlus::Whitespace.process_dos_whitespace_files(false)
      if BuildrPlus::Whitespace.whitespace_needs_update?
        raise 'Whitespace has not been normalized in dos files. Please run "buildr whitespace:fix_dos_whitespace" and commit changes.'
      end
    end

    desc 'Normalize whitespace.'
    task 'whitespace:fix_dos_whitespace' do
      BuildrPlus::Whitespace.process_dos_whitespace_files(true)
    end

    desc 'Check all whitespace is normalized.'
    task 'whitespace:check' => %w(whitespace:check_whitespace whitespace:check_dos_whitespace)

    desc 'Check all whitespace is fixed.'
    task 'whitespace:fix' => %w(whitespace:fix_whitespace whitespace:fix_dos_whitespace)
  end
end
