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

# Enable this feature if the code is "open source" code
BuildrPlus::FeatureManager.feature(:oss => [:github]) do |f|
  f.enhance(:ProjectExtension) do
    task 'oss:check_license' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      unless File.exist?("#{base_directory}/LICENSE")
        raise 'No LICENSE file present for project. Please run "buildr oss:fix_license" and commit changes.'
      end
    end

    task 'oss:fix_license' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      license_filename = "#{base_directory}/LICENSE"
      unless File.exist?(license_filename)
        FileUtils.cp "#{File.dirname(__FILE__)}/../../../LICENSE", license_filename
      end
    end

    task 'oss:check_contributing' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      unless File.exist?("#{base_directory}/CONTRIBUTING.md")
        raise 'No CONTRIBUTING.md file present for project. Please run "buildr oss:fix_contributing" and commit changes.'
      end
    end

    task 'oss:fix_contributing' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      contributing_filename = "#{base_directory}/CONTRIBUTING.md"
      unless File.exist?(contributing_filename)
        FileUtils.cp "#{File.dirname(__FILE__)}/../../../CONTRIBUTING.md", contributing_filename
      end
    end

    task 'oss:check' => %w(oss:check_license oss:check_contributing)

    task 'oss:fix' => %w(oss:fix_license oss:fix_contributing)
  end
end
