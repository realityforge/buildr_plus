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

module BuildrPlus #nodoc
  module Config #nodoc
    class ApplicationConfig < BuildrPlus::BaseElement
      def initialize(options = {}, &block)
        @environments = {}

        options.each_pair do |environment_key, config|
          environment(environment_key, config)
        end

        super({}, &block)
      end

      def environment_by_key?(key)
        !!@environments[key.to_s]
      end

      def environment_by_key(key)
        raise "Attempting to retrieve environment with key '#{key}' but no such environment exists." unless @environments[key.to_s]
        @environments[key.to_s]
      end

      def environments
        @environments.values
      end

      def environment(key, config = {}, &block)
        raise "Attempting to redefine environment with key '#{key}'." if @environments[key.to_s]
        config = config.dup
        @environments[key.to_s] = BuildrPlus::Config::EnvironmentConfig.new(key, config, &block)
      end

      def to_h
        results = {}
        environments.each do |environment|
          results[environment.key.to_s] = environment.to_h
        end
        results
      end
    end
  end
end
