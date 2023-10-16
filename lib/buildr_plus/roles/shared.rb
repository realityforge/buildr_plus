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

BuildrPlus::Roles.role(:shared) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = BuildrPlus::Deps.shared_generators + project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators.flatten,
                                       :buildr_project => project,
                                       :keep_file_patterns => project.all_keep_file_patterns,
                                       :clean_generated_files => BuildrPlus::Generate.clean_generated_files?) do |t|
      BuildrPlus::Generate.generated_directories << t.target_dir
      t.mark_as_generated_in_ide = !project.inline_generated_source?
      t.filter = project.domgen_filter
    end
  end

  project.publish = BuildrPlus::Artifacts.model? || BuildrPlus::Artifacts.gwt?

  compile.with BuildrPlus::Deps.shared_deps
  # Lock down to Java 11 as this is the latest language level supported by GWT 2.10.0
  project.compile.options.source = '11'
  project.compile.options.target = '11'
  project.iml.jdk_version = '17'
  test.with BuildrPlus::Deps.shared_test_deps

  package(:jar)
  package(:sources)

  if BuildrPlus::FeatureManager.activated?(:gwt)
    BuildrPlus::Gwt.add_source_to_jar(project)

    BuildrPlus::Gwt.define_gwt_idea_facet(project)
  end
end
