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

BuildrPlus::Roles.role(:model) do
  if BuildrPlus::FeatureManager.activated?(:domgen)
    generators = BuildrPlus::Deps.model_generators + BuildrPlus::Deps.model_only_generators + project.additional_domgen_generators
    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project) do |t|
      t.filter = project.domgen_filter
    end
  end

  project.publish = BuildrPlus::Artifacts.model?

  compile.using :javac

  compile.with BuildrPlus::Deps.model_deps

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :shared)

  package(:jar)
  package(:sources)

  if BuildrPlus::FeatureManager.activated?(:db)

    check package(:jar), 'should contain resources and generated classes' do
      it.should_not contain('META-INF/orm.xml')
      it.should_not contain('META-INF/persistence.xml')
    end

    iml.add_jpa_facet
    iml.add_ejb_facet if BuildrPlus::FeatureManager.activated?(:ejb)
  end
end
