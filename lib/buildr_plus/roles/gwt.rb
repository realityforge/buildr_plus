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

BuildrPlus::Roles.role(:gwt, :requires => [:gwt]) do

  project.publish = BuildrPlus::Artifacts.gwt?

  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = BuildrPlus::Deps.gwt_generators + project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators,
                                       :buildr_project => project,
                                       :clean_generated_files => BuildrPlus::Generate.clean_generated_files?) do |t|
      BuildrPlus::Generate.generated_directories << t.target_dir
      t.filter = Proc.new do |artifact_type, artifact|
        # Non message
        artifact_type != :message ||
          # Or message has only standard types
          !artifact.any_non_standard_types? ||
          # Or message is replication subscription message
          artifact.imit? && artifact.imit.subscription_message?
      end if BuildrPlus::FeatureManager.activated?(:role_user_experience)
    end
  end

  if BuildrPlus::FeatureManager.activated?(:resgen)
    generators = [:mvp_abstract_uibinder_component, :gwt_abstract_uibinder_component, :gwt_client_bundle, :assets]
    generators += project.additional_resgen_generators
    Resgen::Build.define_generate_task(generators,
                                       :buildr_project => project,
                                       :clean_generated_files => BuildrPlus::Generate.clean_generated_files?) do |t|
      BuildrPlus::Generate.generated_directories << t.target_dir
      t.filter = Resgen::Filters.include_catalog_below(project._(:source, :main),
                                                       project.root_project._(:vendor))
    end
  end

  compile.with BuildrPlus::Deps.gwt_deps
  # Lock down to Java 11 as this is the latest language level supported by GWT 2.10.0
  project.compile.options.source = '11'
  project.compile.options.target = '11'
  project.iml.jdk_version = '17'
  compile.options.processor_path << BuildrPlus::Deps.gwt_processorpath
  test.compile.options.processor_path << BuildrPlus::Deps.gwt_processorpath

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :shared)

  project.test.options[:properties] = (project.test.options[:properties] ? project.test.options[:properties] : {}).merge(BuildrPlus::Gwt.gwt_test_options) if BuildrPlus::FeatureManager.activated?(:gwt)
  if BuildrPlus::FeatureManager.activated?(:arez)
    project.test.options[:properties] = (project.test.options[:properties] ? project.test.options[:properties] : {}).merge(BuildrPlus::Arez.arez_test_options)
    if BuildrPlus::FeatureManager.activated?(:replicant)
      project.test.options[:properties] = (project.test.options[:properties] ? project.test.options[:properties] : {}).merge(BuildrPlus::Replicant.replicant_test_options)
    end
  end

  package(:jar)
  package(:sources)

  BuildrPlus::Gwt.add_source_to_jar(project)

  p = project.root_project

  # This compile exists to verify that module is independently compilable
  BuildrPlus::Gwt.define_gwt_task(project, ".#{p.name_as_class}") if BuildrPlus::Artifacts.library?

  BuildrPlus::Gwt.define_gwt_idea_facet(project)
end
