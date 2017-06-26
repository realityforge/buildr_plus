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

BuildrPlus::FeatureManager.feature(:node) do |f|
  f.enhance(:Config) do
    def base_directory
      File.dirname(Buildr.application.buildfile.to_s)
    end

    def node_version_filename
      "#{base_directory}/.node-version"
    end

    def package_json_filename
      "#{base_directory}/package.json"
    end

    def yarn_lock_filename
      "#{base_directory}/yarn.lock"
    end

    def node_version
      IO.read(node_version_filename).strip
    end

    def root_package_json_present?
      File.exist?(BuildrPlus::Node.package_json_filename)
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check presence of NodeJS configuration.'
    task 'node:check' do
      BuildrPlus.error("Expected node version file #{BuildrPlus::Node.node_version_filename} to exist when node enabled.") unless File.exist?(BuildrPlus::Node.node_version_filename)
      if BuildrPlus::Node.root_package_json_present?
        BuildrPlus.error("Expected yarn lock file #{BuildrPlus::Node.yarn_lock_filename} to exist when node enabled and package.json present.") unless File.exist?(BuildrPlus::Node.yarn_lock_filename)
      end
    end
  end
end
