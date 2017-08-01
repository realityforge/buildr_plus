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
    def process_whitespace_files(apply_fix)
      output = `bundle exec zapwhite#{apply_fix ? '' : ' --check-only'}`
      puts output
      if '' != output && !apply_fix
        return false
      else
        return true
      end
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check all whitespace is normalized.'
    task 'whitespace:check' do
      output = `bundle exec zapwhite -d #{File.dirname(Buildr.application.buildfile.to_s)} --check-only`
      unless output.empty?
        puts output
        raise 'Whitespace has not been normalized. Please run "buildr whitespace:fix" and commit changes.'
      end
    end

    desc 'Check all whitespace is fixed.'
    task 'whitespace:fix' do
      output = `bundle exec zapwhite -d #{File.dirname(Buildr.application.buildfile.to_s)}`
      puts output unless output.empty?
    end
  end
end
