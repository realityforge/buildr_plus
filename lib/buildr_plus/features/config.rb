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

BuildrPlus::FeatureManager.feature(:config) do |f|
  f.enhance(:Config) do
    attr_writer :application_config_location

    def application_config_location
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      "#{base_directory}/config/application.yml"
    end

    def application_config_example_location
      application_config_location.gsub(/\.yml$/, '.example.yml')
    end

    def application_config
      @application_config ||= load_application_config
    end

    private

    def load_application_config
      if !File.exist?(self.application_config_location) && File.exist?(self.application_config_example_location)
        FileUtils.cp self.application_config_example_location, self.application_config_location
      end
      unless File.exist?(self.application_config_location)
        raise "Missing application configuration file at #{self.application_config_location}"
      end
      BuildrPlus::Config::ApplicationConfig.new(YAML::load(ERB.new(IO.read(self.application_config_location)).result))
    end
  end
  f.enhance(:ProjectExtension) do
    after_define do |project|

      if project.ipr?
        desc 'Generate a complete application configuration from context'
        project.task('config:expand_application_yml') do
          filename = project._('generated/buildr_plus/config/application.yml')
          info("Expanding application configuration to #{filename}")
          FileUtils.mkdir_p File.dirname(filename)
          File.open(filename, 'wb') do |file|
            file.write BuildrPlus::Config.application_config.to_h.to_yaml
          end
        end
      end
    end
  end
end
