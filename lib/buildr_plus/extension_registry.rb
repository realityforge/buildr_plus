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

module BuildrPlus
  class ExtensionRegistry
    class << self
      def activating?
        !!@activating
      end

      def activated?
        !!@activated
      end

      def registered?(extension)
        raw_extensions.include?(extension)
      end

      def register(extension)
        raise "Can not register extension #{extension.class.name} after registry has been activated" if activated?
        raw_extensions << extension
      end

      def deregister(extension)
        raise "Can not deregister extension #{extension.class.name} after registry has been activated" if activated?
        raw_extensions.delete(extension)
      end

      # Set flag determining whether extensions will auto activate
      def auto_activate=(auto_activate)
        @auto_activate = auto_activate
      end

      # Return true if extensions should auto activate
      def auto_activate?
        @auto_activate.nil? ? true : !!@auto_activate
      end

      def auto_activate!
        self.activate! if auto_activate?
      end

      def activate!
        @activating = true
        BuildrPlus::FeatureManager.deactivate_pending
        @activated = true
        raw_extensions.each do |extension|
          Buildr::Project.class_eval do |p|
            include extension
          end
        end
      end

      private

      def raw_extensions
        @extensions ||= []
      end
    end
  end
end
