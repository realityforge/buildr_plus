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
    generators = [:ee_data_types]
    if BuildrPlus::FeatureManager.activated?(:db)
      generators << [:jpa_orm_xml, :jpa_model, :jpa_ejb_dao]
      generators << [:jpa_persistence_xml] unless BuildrPlus::Dbt.library?

      generators << [:jpa_ejb_dao] if BuildrPlus::FeatureManager.activated?(:ejb)

      generators << [:imit_server_entity_listener] if BuildrPlus::FeatureManager.activated?(:replicant)
    end

    generators << [:jaxb_marshalling_tests, :xml_xsd_resources] if BuildrPlus::FeatureManager.activated?(:xml)

    generators += project.additional_domgen_generators

    Domgen::Build.define_generate_task(generators.flatten, :buildr_project => project)
  end

  project.publish = BuildrPlus::Artifacts.model?

  compile.using :javac
  compile.with BuildrPlus::Libs.ee_provided

  # Our JPA beans are occasionally generated with eclipselink specific artifacts
  compile.with BuildrPlus::Libs.glassfish_embedded if BuildrPlus::FeatureManager.activated?(:db)

  if BuildrPlus::FeatureManager.activated?(:geolatte)
    compile.with artifacts(BuildrPlus::Libs.geolatte_geom)
    compile.with artifacts(BuildrPlus::Libs.geolatte_support)
    compile.with artifacts(BuildrPlus::Libs.geolatte_geom_jpa) if BuildrPlus::FeatureManager.activated?(:db)
  end

  if BuildrPlus::FeatureManager.activated?(:gwt)
    compile.with BuildrPlus::Libs.jackson_gwt_support, BuildrPlus::Libs.gwt_datatypes
  end

  BuildrPlus::Roles.merge_projects_with_role(project.compile, :shared)

  package(:jar)
  package(:sources)

  if BuildrPlus::FeatureManager.activated?(:db)

    check package(:jar), 'should contain resources and generated classes' do
      it.should contain('META-INF/orm.xml')
      if BuildrPlus::Dbt.library?
        it.should_not contain('META-INF/persistence.xml')
      else
        it.should contain('META-INF/persistence.xml')
      end
      it.should contain("#{project.root_project.group.gsub('.','/')}/server/entity/#{BuildrPlus::Naming.pascal_case(project.root_project.name)}PersistenceUnit.class")
    end

    iml.add_jpa_facet
    iml.add_ejb_facet if BuildrPlus::FeatureManager.activated?(:ejb)
  end
end
