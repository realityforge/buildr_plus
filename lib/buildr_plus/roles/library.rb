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

BuildrPlus::Roles.role(:library) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = BuildrPlus::Deps.library_generators + project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators.flatten,
                                       :buildr_project => project,
                                       :keep_file_patterns => project.all_keep_file_patterns,
                                       :keep_file_names => project.keep_file_names,
                                       :pre_generate_task => 'domgen:pre_generate',
                                       :clean_generated_files => BuildrPlus::Generate.clean_generated_files?) do |t|
      BuildrPlus::Generate.generated_directories << t.target_dir
      t.mark_as_generated_in_ide = !project.inline_generated_source?
      t.filter = project.domgen_filter
    end
  end

  project.publish = true

  compile.with BuildrPlus::Deps.server_deps

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :model)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :model_qa_support)

  test.with BuildrPlus::Deps.server_test_deps

  package(:jar).tap do |jar|
    BuildrPlus::Roles.buildr_projects_with_role(:shared).each do |dep|
      jar.merge(dep.package(:jar))
    end
    BuildrPlus::Roles.buildr_projects_with_role(:model).each do |dep|
      jar.merge(dep.package(:jar))
    end
  end
  package(:sources).tap do |jar|
    BuildrPlus::Roles.buildr_projects_with_role(:shared).each do |dep|
      jar.merge(dep.package(:jar))
    end
    BuildrPlus::Roles.buildr_projects_with_role(:model).each do |dep|
      jar.merge(dep.package(:jar))
    end
  end
end
