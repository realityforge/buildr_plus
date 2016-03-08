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

BuildrPlus::FeatureManager.feature(:checkstyle) do |f|
  f.enhance(:Config) do
    def default_checkstyle_rules
      'au.com.stocksoftware.checkstyle:checkstyle:xml:1.8'
    end

    def checkstyle_rules
      @checkstyle_rules || self.default_checkstyle_rules
    end

    attr_writer :checkstyle_rules

    attr_accessor :additional_project_names
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'buildr_plus/patches/checkstyle'
    end

    before_define do |project|
      if project.ipr?
        project.checkstyle.config_directory = project._('etc/checkstyle')
        project.checkstyle.configuration_artifact = BuildrPlus::Checkstyle.checkstyle_rules

        import_control_present = File.exist?(project.checkstyle.import_control_file)

        unless File.exist?(project.checkstyle.suppressions_file)
          dir = File.expand_path(File.dirname(__FILE__))
          project.checkstyle.suppressions_file =
            import_control_present ?
              "#{dir}/checkstyle_suppressions.xml" :
              "#{dir}/checkstyle_suppressions_no_import_control.xml"
        end

        unless import_control_present
          project.checkstyle.properties['checkstyle.import-control.file'] = ''
        end
      end
    end

    after_define do |project|
      if project.ipr?
        project.checkstyle.additional_project_names =
          BuildrPlus::Findbugs.additional_project_names || BuildrPlus::Util.subprojects(project)
      end
    end
  end
end
