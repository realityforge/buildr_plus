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

module BuildrPlus::RemoteReferences
  class Datasource < Reality::BaseElement
    def initialize(name, options = {})
      @name = name
      super(options)
    end

    attr_reader :name
  end
end


BuildrPlus::FeatureManager.feature(:remote_references) do |f|
  f.enhance(:Config) do

    def remote_datasource(name, options = {})
      BuildrPlus.error("Remote datasource #{name} already defined.") if remote_datasource_map[name.to_s]
      remote_datasource_map[name.to_s] = BuildrPlus::RemoteReferences::Datasource.new(name, options)
    end

    def remote_datasources
      remote_datasource_map.values
    end

    protected

    def remote_datasource_map
      @remote_datasource_map ||= {}
    end
  end
end
