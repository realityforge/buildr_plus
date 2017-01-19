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
BuildrPlus::FeatureManager.feature(:java => [:ruby]) do |f|
  f.enhance(:Config) do
    def version=(version)
      raise "Invalid java version #{version}" unless [7, 8].include?(version)
      @version = version
    end

    def version
      @version || 8
    end
  end
  f.enhance(:ProjectExtension) do
    before_define do |project|
      project.compile.options.source = "1.#{BuildrPlus::Java.version}"
      project.compile.options.target = "1.#{BuildrPlus::Java.version}"
    end
  end
end
