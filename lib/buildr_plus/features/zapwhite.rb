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
    def additional_rules
      @additional_rules ||= []
    end

    def zapwhite_command
      "bundle exec zapwhite -d #{File.dirname(Buildr.application.buildfile.to_s)} #{additional_rules.collect{|r| "--rule \"#{r}\""}.join(' ')}"
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Run zapwhite to check that the .gitattribute file and file whitespace is normalized.'
    task 'zapwhite:check' do
      output = `#{BuildrPlus::Zapwhite.zapwhite_command} --check-only`
      unless $?.exitstatus == 0
        puts output
        raise 'Whitespace has not been normalized. Please run "buildr zapwhite:fix" and commit changes.'
      end
    end

    desc 'Run zapwhite to ensure that the .gitattribute file and file whitespace is normalized.'
    task 'zapwhite:fix' do
      output = `#{BuildrPlus::Zapwhite.zapwhite_command}`
      puts output unless output.empty?
    end
  end
end
