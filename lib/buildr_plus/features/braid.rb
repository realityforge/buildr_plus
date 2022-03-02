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
  f.enhance(:Config) do

    attr_writer :allow_local_changes

    def allow_local_changes?
      @allow_local_changes.nil? ? false : !!@allow_local_changes
    end
  end

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

      unless config.mirrors.include?('vendor/tools/buildr')
        raise "Braid entry does not exists for path 'vendor/tools/buildr' as expected."
      end
      unless config.mirrors.include?('vendor/tools/buildr_plus')
        raise "Braid entry does not exists for path 'vendor/tools/buildr_plus' as expected."
      end
      {
        'domgen' => 'domgen',
        'dbt' => 'dbt',
        'rptman' => 'rptman',
        'redfish' => 'redfish',
        'resgen' => 'resgen',
        'kinjen' => 'jenkins'
      }.each_pair do |path, feature|
        path = "vendor/tools/#{path}"
        if BuildrPlus::FeatureManager.activated?(feature) && !config.mirrors.include?(path)
          raise "Braid entry does not exists for path '#{path}' despite buildr_plus feature '#{feature}' being enabled."
        end
      end
      raise "Vendor directory 'vendor/tools/buildr' expected to exist." unless File.exist?("#{base_directory}/vendor/tools/buildr")
      raise "Vendor directory 'vendor/tools/buildr_plus' expected to exist." unless File.exist?("#{base_directory}/vendor/tools/buildr_plus")
      %w(domgen dbt rptman redfish).each do |feature|
        if File.exist?("#{base_directory}/vendor/tools/#{feature}")
          raise "Vendor directory 'vendor/tools/#{feature}' exists but buildr_plus '#{feature}' feature is not enabled." unless BuildrPlus::FeatureManager.activated?(feature)
        elsif !File.exist?("#{base_directory}/vendor/tools/#{feature}")
          raise "Vendor directory 'vendor/tools/#{feature}' does not exist but buildr_plus '#{feature}' feature is is enabled." if BuildrPlus::FeatureManager.activated?(feature)
        end
      end
      if BuildrPlus::Braid.allow_local_changes?
        local_changes = false
        config.mirrors.each do |mirror|
          local_changes = true unless `braid diff #{mirror}`.chomp.empty?
        end
        raise "Braid directories have no local changes but buildr_plus is configured to allow local changes. Please remove allow_local_changes setting." unless local_changes
      else
        config.mirrors.each do |mirror|
          unless `braid diff #{mirror}`.chomp.empty?
            raise "Vendor directory '#{mirror}' has local changes but buildr_plus is configured to disallow local changes. Please push changes to upstream or set BuildrPlus::Braid.allow_local_changes = true."
          end
        end
      end
    end
  end
end
