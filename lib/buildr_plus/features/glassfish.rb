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

BuildrPlus::FeatureManager.feature(:glassfish) do |f|
  f.enhance(:Config) do
    def packaged_apps
      @packaged_apps ||= {}
    end

    def only_only_packaged_apps
      @only_only_packaged_apps ||= {}
    end

    def remote_only_packaged_apps
      @remote_only_packaged_apps ||= {}
    end

    def non_remote_only_packaged_apps
      @non_remote_only_packaged_apps ||= {}
    end

    def addtional_default_testng_args
      @addtional_default_testng_args ||= []
    end
  end
end
