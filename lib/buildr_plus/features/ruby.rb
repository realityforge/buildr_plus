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

BuildrPlus::FeatureManager.feature(:ruby) do |f|
  f.enhance(:Config) do
    def ruby_version
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      IO.read("#{base_directory}/.ruby-version").strip
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check vendored Gems align.'
    task 'ruby:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      raise "Vendor directory 'vendor/tools/buildr_plus' expected to exist." unless File.exist?("#{base_directory}/vendor/tools/buildr_plus")
      %w(domgen dbt rptman redfish).each do |feature|
        if File.exist?("#{base_directory}/vendor/tools/#{feature}")
          raise "Vendor directory 'vendor/tools/#{feature}' exists but buildr_plus '#{feature}' feature is not enabled." unless BuildrPlus::FeatureManager.activated?(feature)
        elsif !File.exist?("#{base_directory}/vendor/tools/#{feature}")
          raise "Vendor directory 'vendor/tools/#{feature}' does not exist but buildr_plus '#{feature}' feature is is enabled." if BuildrPlus::FeatureManager.activated?(feature)
        end
      end
    end
  end
end
