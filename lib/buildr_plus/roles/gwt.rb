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

BuildrPlus::Roles.role(:gwt) do
  BuildrPlus::FeatureManager.ensure_activated(:gwt)

  if BuildrPlus::FeatureManager.activated?(:domgen)
    Domgen::Build.define_generate_task([:gwt, :gwt_rpc_shared, :gwt_rpc_client_service, :gwt_client_jso, :imit_shared, :imit_client_service, :imit_client_entity], :buildr_project => project)
  end

  compile.with BuildrPlus::Libs.findbugs_provided,
               BuildrPlus::Libs.replicant_client

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :shared)

  test.with BuildrPlus::Libs.mockito

  package(:jar).tap do |jar|
    project.compile.sources.each do |src|
      jar.include("#{src}/*")
    end
  end
  package(:sources)

  gwt_modules = project.gwt_modules
  top_level_gwt_modules = project.determine_top_level_gwt_modules

  # This compile exists to verify that module is independently compilable
  gwt(top_level_gwt_modules, :java_args => BuildrPlus::Gwt.gwtc_java_args)

  module_config = {}
  gwt_modules.each do |m|
    module_config[m] = top_level_gwt_modules.include?(m)
  end
  iml.add_gwt_facet(module_config,
                    :settings => {:compilerMaxHeapSize => '1024'},
                    :gwt_dev_artifact => BuildrPlus::Libs.gwt_dev)
end
