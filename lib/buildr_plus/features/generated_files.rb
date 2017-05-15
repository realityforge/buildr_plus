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
BuildrPlus::FeatureManager.feature(:generated_files) do |f|
  f.enhance(:Config) do
    def check_generated_files(pattern, auto_generated_regex, exceptions = [])
      `git ls-files '#{pattern}' | grep -v vendor/`.split("\n").each do |file|
        if File.file?(file) && !exceptions.include?(file) && IO.read(file) =~ auto_generated_regex
          raise "The file #{file} has a comment indicating it is generated but it is checked into the source tree."
        end
      end
    end
  end
  f.enhance(:ProjectExtension) do
    desc 'Check the directories in java source tree do not have . character'
    task 'generated_files:check' do
      BuildrPlus::GeneratedFiles.check_generated_files('*.java', /^\/\* DO NOT EDIT\: File is auto-generated \*\/$/)
      BuildrPlus::GeneratedFiles.check_generated_files('*.xml', /^<!-- DO NOT EDIT\: File is auto-generated -->$/)
      BuildrPlus::GeneratedFiles.check_generated_files('*.rb', /^# DO NOT EDIT\: File is auto-generated$/)
      BuildrPlus::GeneratedFiles.check_generated_files('*.yaml', /^# DO NOT EDIT\: File is auto-generated$/)
      BuildrPlus::GeneratedFiles.check_generated_files('*.yml', /^# DO NOT EDIT\: File is auto-generated$/, %(.travis.yml))
    end
  end
end
