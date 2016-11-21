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

  class Feature < BaseElement
    attr_reader :key
    attr_reader :required_features
    attr_reader :suggested_features

    def initialize(key, required_features, options = {}, &block)
      @key = key
      @required_features = required_features
      @suggested_features = []

      module_name = ::BuildrPlus::Naming.pascal_case(key)
      ::BuildrPlus.class_eval "module #{module_name}\n end"
      module_instance = ::BuildrPlus.const_get(module_name)

      @component_map = {}

      @component_map[:Config] = module_instance.class

      module_instance.class_eval 'module ProjectExtension; include Extension; end'
      @component_map[:ProjectExtension] = module_instance.const_get(:ProjectExtension)

      FeatureManager.register_feature(self)

      super(options, &block)
    end

    def activated?
      BuildrPlus::ExtensionRegistry.registered?(component_by_key(:ProjectExtension))
    end

    def activate
      BuildrPlus::ExtensionRegistry.register(component_by_key(:ProjectExtension))
    end

    def deactivate
      BuildrPlus::ExtensionRegistry.deregister(component_by_key(:ProjectExtension))
    end

    def enhance(component_key, &block)
      component_by_key(component_key).class_eval &block
    end

    def component_by_key(component_key)
      component = @component_map[component_key]
      BuildrPlus.error("Unknown component key #{component_key.name}") unless component
      component
    end

    def self.is_class_feature?(component_key)
      [:Config].include?(component_key)
    end

    def self.feature_components
      [:Config, :ProjectExtension]
    end
  end

  class FeatureManager
    class << self
      def register_feature(feature)
        BuildrPlus.error("Attempting to redefine feature #{feature.key}") if feature_map[feature.key.to_s]
        feature_map[feature.key.to_s] = feature
      end

      def ensure_activated(key)
        raise "Expected feature #{key} to be activated" unless activated?(key)
      end

      def activated?(key)
        feature_by_name(key).activated?
      end

      def feature?(key)
        !!feature_map[key.to_s]
      end

      def feature_names
        feature_map.keys
      end

      def feature_by_name(key)
        feature = feature_map[key.to_s]
        BuildrPlus.error("Unknown feature '#{key}'") unless feature
        feature
      end

      def feature(definition, options = {}, &block)
        BuildrPlus.error("Unknown definition form '#{definition.inspect}'") unless (definition.is_a?(Symbol) || (definition.is_a?(Hash) && 1 == definition.size))
        key = (definition.is_a?(Hash) ? definition.keys[0] : definition).to_sym
        BuildrPlus.error("Attempting to redefine feature #{key}") if FeatureManager.feature?(key)
        required_features = definition.is_a?(Hash) ? definition.values[0] : []

        Feature.new(key, required_features, options, &block)
      end

      def activate_features(features)
        features.each do |feature_key|
          activate_feature(feature_key)
        end
      end

      def activate_feature(feature_key)
        feature = feature_by_name(feature_key)
        return if feature.activated?
        feature.required_features.each do |required_feature_key|
          activate_feature(required_feature_key)
        end
        feature.suggested_features.each do |required_feature_key|
          activate_feature(required_feature_key)
        end
        feature.activate
      end

      def deactivate_features(features)
        features.each do |feature_key|
          deactivate_feature(feature_key)
        end
      end

      def deactivate_feature(feature_key)
        feature = feature_by_name(feature_key)
        if BuildrPlus::ExtensionRegistry.activating? || BuildrPlus::ExtensionRegistry.activated?
          return unless feature.activated?

          feature_map.values.each do |f|
            if f.required_features.include?(feature_key)
              deactivate_feature(f.key)
            end
          end
          feature.deactivate
        else
          pending_deactivates << feature_key
        end
      end

      def deactivate_pending
        pending_deactivates.each do |feature_key|
          deactivate_feature(feature_key)
        end
        pending_deactivates.clear
      end

      private

      def pending_deactivates
        @pending_deactivates ||= []
      end

      # Map a feature key to a feature.
      def feature_map
        @features ||= {}
      end
    end
  end
end
