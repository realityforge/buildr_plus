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
    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project)
  end

  project.publish = true

  compile.with BuildrPlus::Deps.server_deps
  test.with BuildrPlus::Deps.server_test_deps

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :shared)
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

  package(:war).tap do |war|
    war.enhance do
      if BuildrPlus::FeatureManager.activated?(:gwt_cache_filter)
        project.assets.invoke

        puts "Pre-encoding assets with brotli"
        Dir.glob("#{project.assets.to_s}/**/*").select { |f| !File.directory?(f) }.each do |f|
          next if f =~ /^.*\.br$/
          next if f.start_with?("#{project.assets.to_s}/WEB-INF")
          FileUtils.rm_f "#{f}.br" if File.exist?("#{f}.br")
          puts "Pre-encoding asset #{f}" if trace?
          sh "brotli #{f}"
        end
        puts "Asset encoding complete"
      end
    end
  end

  webroots = {}
  webroots[_(:source, :main, :webapp)] = '/'
  if BuildrPlus::FeatureManager.activated?(:role_user_experience)
    webroots[_(:source, :main, :webapp_local)] = '/'
    BuildrPlus::Roles.buildr_projects_with_role(:user_experience).each do |p|
      p.determine_top_level_gwt_modules('Prod').each do |gwt_module|
        short_name = gwt_module.gsub(/.*\.([^.]+)Prod$/, '\1').downcase
        webroots[_('..', :generated, 'gwt-export', short_name)] = "/#{short_name}"
      end
      p.determine_top_level_gwt_modules('Dev').each do |gwt_module|
        short_name = gwt_module.gsub(/.*\.([^.]+)Dev$/, '\1').downcase + "_dev"
        webroots[_('..', :generated, 'gwt-export', short_name)] = "/#{short_name}"
      end
      BuildrPlus::Gwt.define_gwt_task(p,
                                      'Dev',
                                      :target_project => project.name,
                                      :gwtc_args => %w(-optimize 0 -checkAssertions -XmethodNameDisplayMode FULL -noincremental -logLevel INFO -compileReport))
      BuildrPlus::Gwt.define_gwt_task(p,
                                      'Prod',
                                      :target_project => project.name,
                                      :gwtc_args => (BuildrPlus::FeatureManager.activated?(:replicant) && BuildrPlus::Replicant.enable_entity_broker? ? [] : %w(-XdisableClassMetadata)) + %w(-XdisableCastChecking -optimize 9 -nocheckAssertions -XmethodNameDisplayMode NONE -noincremental -logLevel INFO -compileReport))
    end
  end

  project.assets.paths.each do |path|
    next if path.to_s =~ /generated\/gwt\// && BuildrPlus::FeatureManager.activated?(:gwt)
    webroots[path.to_s] = '/'
  end

  project.iml.add_web_facet(:webroots => webroots)
end
