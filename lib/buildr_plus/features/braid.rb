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

BuildrPlus::FeatureManager.feature(:braid) do |f|
  f.enhance(:ProjectExtension) do
    desc 'Check braids align with filesystem.'
    task 'braid:check' do
      require 'braid'
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/#{Braid::CONFIG_FILE}"

      raise "Braid file '#{filename}' missing." unless File.exist?(filename)
      config = Braid::Config.new(filename)
      config.mirrors.each do |path|
        unless File.exist?(path)
          raise "Braid entry exists for path '#{path}' but path does not exist on the filesystem"
        end
      end

      unless config.mirrors.include?('vendor/tools/buildr_plus')
        raise "Braid entry does not exists for path 'vendor/tools/buildr_plus' as expected."
      end
      %w(domgen dbt rptman redfish).each do |feature|
        path = "vendor/tools/#{feature}"
        if BuildrPlus::FeatureManager.activated?(feature) && !config.mirrors.include?(path)
          raise "Braid entry does not exists for path '#{path}' despite buildr_plus feature '#{feature}' being enabled."
        end
      end
      if BuildrPlus::FeatureManager.activated?(:rails)
        %w(itest active_scaffold db_purge no_cache raaa system_settings).each do |plugin|
          path = "vendor/plugins/#{plugin}"
          if File.exist?("#{base_directory}/#{path}") && !config.mirrors.include?(path)
            raise "Rails plugin '#{plugin}' is at path '#{path}' but is not braided in."
          end
        end
      end
      if File.exist?("#{base_directory}/vendor/docs/way_of_stock") && !config.mirrors.include?('vendor/docs/way_of_stock')
        raise "Docs 'way_of_stock' is at path 'vendor/docs/way_of_stock' but is not braided in."
      end
    end
  end
end
