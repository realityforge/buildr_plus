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

BuildrPlus::Roles.role(:server) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = BuildrPlus::Deps.server_generators + project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project) do |t|
      t.filter = Proc.new do |artifact_type, artifact|
        if artifact_type == :message && (artifact.imit? && artifact.imit.subscription_message?)
          false
        elsif project.domgen_filter
          project.domgen_filter.call(artifact_type, artifact)
        else
          true
        end
      end
    end
  end

  if BuildrPlus::FeatureManager.activated?(:graphiql)
    assets_dir = _(:generated, 'graphiql/src/webapp')
    f = file(assets_dir) do
      BuildrPlus::Graphiql.setup_graphiql(assets_dir)
    end
    task(':domgen:all' => [f])
    project.assets.paths << assets_dir
    project.assets.enhance([f])
  end

  if BuildrPlus::FeatureManager.activated?(:giggle)
    desc 'Generate GraphQL support code'
    generate_task = project.task('giggle:generate')
    jar = artifact(BuildrPlus::Deps.giggle)

    generated_dir = _(:generated, 'giggle/src/java')
    t = project.task(generated_dir => [project.task(':domgen:all')]) do
      type_mapping_file = root_project._("server/generated/domgen/server/main/resources/#{project.group.gsub('.', '/')}/server/types.mapping")
      schema_pkg = project.project('graphqls').package(:graphqls)
      schema_pkg.invoke
      jar.invoke
      Java::Commands.java %W(-jar #{jar} --package #{project.root_project.group}server.graphql --schema #{schema_pkg} --type-mapping #{type_mapping_file} --output-directory #{generated_dir} --generator java-server)
    end

    project.task(':giggle:generate').enhance([t.name])

    generate_task.enhance([t.name])
    project.iml.main_source_directories << generated_dir
    project.compile.enhance([t.name])
    project.compile.from(generated_dir)
    project.root_project.pmd.exclude_paths << generated_dir if BuildrPlus::FeatureManager.activated?(:pmd)
  end

  project.publish = true

  compile.with BuildrPlus::Deps.server_deps
  test.with BuildrPlus::Deps.server_test_deps

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :model)
  BuildrPlus::Roles.merge_projects_with_role(project.test, :model_qa_support)

  package(:war).tap do |war|
    war.libs.clear
    # Spotbugs+jetbrains libs added otherwise CDI scanning slows down due to massive number of ClassNotFoundExceptions
    war.libs << BuildrPlus::Deps.spotbugs_provided
    war.libs << BuildrPlus::Deps.jetbrains_annotations
    war.libs << BuildrPlus::Deps.server_compile_deps
    BuildrPlus::Roles.buildr_projects_with_role(:shared).each do |dep|
      war.libs << dep.package(:jar)
    end
    BuildrPlus::Roles.buildr_projects_with_role(:model).each do |dep|
      war.libs << dep.package(:jar)
    end
    war.exclude project.less_path if BuildrPlus::FeatureManager.activated?(:less)
    if BuildrPlus::FeatureManager.activated?(:sass)
      project.sass_paths.each do |sass_path|
        war.exclude project._(sass_path)
      end
    end
    war.include assets.to_s, :as => '.' if BuildrPlus::FeatureManager.activated?(:gwt) || BuildrPlus::FeatureManager.activated?(:less) || BuildrPlus::FeatureManager.activated?(:sass)
  end

  project.iml.add_ejb_facet if BuildrPlus::FeatureManager.activated?(:ejb)
  webroots = {}
  webroots[_(:source, :main, :webapp)] = '/'
  if BuildrPlus::FeatureManager.activated?(:role_user_experience)
    webroots[_(:source, :main, :webapp_local)] = '/'
    BuildrPlus::Roles.buildr_projects_with_role(:user_experience).each do |p|
      gwt_modules = p.determine_top_level_gwt_modules('Dev')
      gwt_modules.each do |gwt_module|
        short_name = gwt_module.gsub(/.*\.([^.]+)Dev$/, '\1').downcase
        webroots[_('..', :generated, 'gwt-export', short_name)] = "/#{short_name}"
      end
      BuildrPlus::Gwt.define_gwt_task(p,
                                      'Prod',
                                      :target_project => project.name,
                                      :gwtc_args => %w(-XdisableClassMetadata -XdisableCastChecking -optimize 9 -nocheckAssertions -XmethodNameDisplayMode NONE -noincremental -logLevel INFO -compileReport))
    end
  end

  project.assets.paths.each do |path|
    next if path.to_s =~ /generated\/gwt\// && BuildrPlus::FeatureManager.activated?(:gwt)
    webroots[path.to_s] = '/'
  end

  project.iml.add_web_facet(:webroots => webroots)
end
