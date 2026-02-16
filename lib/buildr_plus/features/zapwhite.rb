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
BuildrPlus::FeatureManager.feature(:zapwhite) do |f|
  f.enhance(:Config) do
    def zapwhite(check_only)
      extension_patterns = [/.*\.bazel$/, /.*\.bzl$/,  /.*\.html$/, /.*\.json$/, /.*\.md$/, /.*\.rake$/,
                            /.*\.rb$/, /.*\.sh$/, /.*\.sql$/, /.*\.xml$/, /.*\.yaml$/, /.*\.yml$/, /.bazelrc$/,
                            /.bazelversion$/, /.gitattributes$/, /.gitignore$/, /.ruby-version$/, /Gemfile$/,
                            /Jenkinsfile$/,  /buildfile$/]
      workspace_dir = File.dirname(Buildr.application.buildfile.to_s).to_s
      `cd #{workspace_dir} && git ls-files`.
          split("\n").
          filter { |filename| !filename.end_with?('vendor/') }.
          each do |filename|
        next unless extension_patterns.any?{|p| p =~ filename}

        full_filename = "#{workspace_dir}/#{filename}"
        original_bin_content = File.binread(full_filename)
        allow_empty = full_filename.end_with?('.bazel')

        content = File.read(full_filename, :encoding => 'bom|utf-8')
        begin
          content.gsub!(/\r\n/, "\n")
          content.gsub!(/[ \t]+\n/, "\n")
          content.gsub!(/[ \r\t\n]+\Z/, '')
          content += "\n"
        rescue
          puts "Skipping whitespace cleanup: #{filename}"
        end
        content = '' if allow_empty && 0 == content.strip.length

        while content.gsub!(/\n\n\n/, "\n\n")
          # Keep removing duplicate new lines till they have gone
        end
        if content.bytes != original_bin_content.bytes
          if check_only
            puts "Non-normalized whitespace in #{filename}"
          else
            puts "Fixing: #{filename}"
            File.open(full_filename, 'wb') do |out|
              out.write content
            end
          end
        end
      end
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Run zapwhite to check that the file whitespace is normalized.'
    task 'zapwhite:check' do
      BuildrPlus::Zapwhite.zapwhite(true)
    end

    desc 'Run zapwhite to ensure that the file whitespace is normalized.'
    task 'zapwhite:fix' do
      BuildrPlus::Zapwhite.zapwhite(false)
    end
  end
end
