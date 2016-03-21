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

  package(:jar)
  package(:sources)

  BuildrPlus::Gwt.add_source_to_jar(project)
  gwt_modules = project.gwt_modules
  top_level_gwt_modules = project.determine_top_level_gwt_modules

  # Unfortunately buildr does not gracefully handle resource directories not being present
  # when project processed so we collect extra dependencies by looking at the generated directories
  extra_deps = project.iml.main_generated_resource_directories.flatten.compact.collect do |a|
      a.is_a?(String) ? file(a) : a
    end + project.iml.main_generated_source_directories.flatten.compact.collect do |a|
      a.is_a?(String) ? file(a) : a
  end

  # This compile exists to verify that module is independently compilable
  gwt(top_level_gwt_modules,
      :java_args => BuildrPlus::Gwt.gwtc_java_args,
      :dependencies => project.compile.dependencies + [project.compile.target] + extra_deps)

  p = project.root_project

  check package(:jar), 'should contain generated source files' do
    it.should contain("#{p.group.gsub('.', '/')}/shared/net/#{BuildrPlus::Naming.pascal_case(p.name)}ReplicationGraph.class")
    it.should contain("#{p.group.gsub('.', '/')}/shared/net/#{BuildrPlus::Naming.pascal_case(p.name)}ReplicationGraph.java")
  end

  module_config = {}
  gwt_modules.each do |m|
    module_config[m] = top_level_gwt_modules.include?(m)
  end
  iml.add_gwt_facet(module_config,
                    :settings => {:compilerMaxHeapSize => '1024'},
                    :gwt_dev_artifact => BuildrPlus::Libs.gwt_dev)
end
