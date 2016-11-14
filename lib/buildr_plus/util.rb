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
  class Util
    class << self
      def is_addon_loaded?(addon)
        $LOADED_FEATURES.any? { |f| f =~ /\/addon\/buildr\/#{addon}\.rb$/ }
      end

      def is_gem_present?(require_file, symbol)
        begin
          require require_file
        rescue LoadError
          # Ignored
        end

        Object.const_defined?(symbol.to_s)
      end

      def is_braid_gem_present?
        is_gem_present?('braid','Braid')
      end

      def is_redfish_gem_present?
        is_gem_present?('redfish','Redfish')
      end

      def is_dbt_gem_present?
        is_gem_present?('dbt','Dbt')
      end

      def is_rptman_gem_present?
        is_gem_present?('rptman','SSRS')
      end

      def is_itest_gem_present?
        is_gem_present?('itest','ITest')
      end

      def is_sass_gem_present?
        is_gem_present?('sass','Sass')
      end

      def is_domgen_gem_present?
        is_gem_present?('domgen','Domgen')
      end

      def is_calendar_date_select_gem_present?
        is_gem_present?('calendar_date_select/calendar_date_select','CalendarDateSelect')
      end

      def subprojects(project)
        Buildr.projects(:scope => project.name).collect { |p| p.name }
      end
    end
  end
end
