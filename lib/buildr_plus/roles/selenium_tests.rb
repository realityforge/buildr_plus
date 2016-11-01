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

BuildrPlus::Roles.role(:selenium_tests, :requires => [:role_integration_tests, :selenium]) do
  server_project = BuildrPlus::Roles.buildr_project_with_role(:server)
  war_package = server_project.package(:war)

  project.publish = false
  test.enhance(artifacts(BuildrPlus::Libs.glassfish_embedded))
  test.enhance([war_package])

  compile.with BuildrPlus::Libs.findbugs_provided,
               Buildr::Selenium.dependencies

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :soap_client)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :integration_qa_support)

  test.with BuildrPlus::Libs.db_drivers

  test.exclude "#{root_project.group_as_package}.*" unless ENV['ENABLE_SELENIUM'] == 'true'

  test.using :java_args => BuildrPlus::Guiceyloops.integration_test_java_args,
             :properties =>
               {
                 'browser.name' => ENV['BROWSER'],
                 'embedded.glassfish.artifacts' => BuildrPlus::Guiceyloops.glassfish_spec_list,
                 'war.filename' => war_package.to_s,
               }

  package(:jar)
  package(:sources)

  Buildr::Selenium.configure_chromium_driver(project)
end
