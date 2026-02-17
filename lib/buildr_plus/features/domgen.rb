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

BuildrPlus::FeatureManager.feature(:domgen => [:generate]) do |f|
  f.enhance(:ProjectExtension) do

    attr_accessor :domgen_filter

    first_time do
      require 'domgen'

      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      candidate_file = File.expand_path("#{base_directory}/architecture.rb")

      if ::File.exist?(candidate_file)
        Domgen::Build.define_load_task do |t|
          t.verbose = 'true' == ENV['DEBUG_DOMGEN']
        end
      end
      database = Dbt.repository.database_for_key(:default)
      database.enable_domgen(:perform_analysis_checks => true)
    end

    after_define do |project|
      if project.ipr?
        if BuildrPlus::FeatureManager.activated?(:dbt) && Dbt.repository.database_for_key?(:default)
          Domgen::Build.define_generate_task([:mssql, :sql_analysis_sql, :action_types_mssql],
                                             :buildr_project => project,
                                             :keep_file_patterns => project.all_keep_file_patterns,
                                             :keep_file_names => project.keep_file_names,
                                             :pre_generate_task => 'domgen:pre_generate',
                                             :clean_generated_files => false,
                                             :target_dir => 'database') do |t|
            t.verbose = 'true' == ENV['DEBUG_DOMGEN']
            t.mark_as_generated_in_ide = false
            BuildrPlus::Generate.generated_directories << t.target_dir
          end

          database = Dbt.repository.database_for_key(:default)
          database.search_dirs = %w(database)
        end

        project.task(':domgen:postload') do
          facet_mapping =
            {
              :redfish => :redfish,
              :keycloak => :keycloak,
              :gwt => :gwt
            }

          Domgen.repositories.each do |r|
            unless BuildrPlus::FeatureManager.activated?(:timers)
              r.data_modules.select(&:ejb?).each do |data_module|
                data_module.services.select(&:ejb?).each do |service|
                  service.methods.select(&:ejb?).each do |method|
                    if method.ejb.schedule?
                      raise "Buildr project does not define 'timers' feature but domgen defines method '#{method.qualified_name}' that defines a schedule."
                    end
                  end
                end
              end
            end

            if r.application? && r.application.db_deployable? && BuildrPlus::Dbt.library?
              raise "Domgen declared 'repository.application.db_deployable = true' but buildr configured 'BuildrPlus::Dbt.library = true'."
            end

            if r.application? && r.sql? && !r.application.db_deployable? && !BuildrPlus::Dbt.library?
              raise "Domgen declared 'repository.application.db_deployable = false' but buildr configured 'BuildrPlus::Dbt.library = false'."
            end

            facet_mapping.each_pair do |buildr_plus_facet, domgen_facet|
              if BuildrPlus::FeatureManager.activated?(buildr_plus_facet) && !r.facet_enabled?(domgen_facet)
                BuildrPlus.error("BuildrPlus feature '#{buildr_plus_facet}' requires that domgen facet '#{domgen_facet}' is enabled but it is not.")
              end
              if !BuildrPlus::FeatureManager.activated?(buildr_plus_facet) && r.facet_enabled?(domgen_facet)
                BuildrPlus.error("Domgen facet '#{domgen_facet}' requires that buildrPlus feature '#{buildr_plus_facet}' is enabled but it is not.")
              end
            end
            if BuildrPlus::FeatureManager.activated?(:keycloak)
              domgen_clients = r.keycloak.clients.collect { |client| client.key.to_s }.sort.uniq
              clients = BuildrPlus::Keycloak.clients.select { |c| !c.external? }.collect { |c| c.client_type }.sort.uniq
              if clients != domgen_clients
                raise "Domgen repository #{r.name} declares keycloak clients #{domgen_clients.inspect} while buildr is aware of #{clients.inspect}"
              end

              domgen_clients = r.keycloak.remote_clients.collect { |client| client.name.to_s }.sort.uniq
              clients = BuildrPlus::Keycloak.remote_clients.select { |c| c.application.nil? }.collect { |c| c.client_type }.sort.uniq
              if clients != domgen_clients
                raise "Domgen repository #{r.name} declares keycloak remote clients #{domgen_clients.inspect} while buildr is aware of #{clients.inspect}"
              end
            end

            if r.jpa?
              if r.jpa.include_default_unit? && !Dbt.database_for_key?(:default)
                raise "Domgen repository #{r.name} includes a default jpa persistence unit but there is no Dbt database with key :default"
              elsif !r.jpa.include_default_unit? && Dbt.database_for_key?(:default)
                raise "Domgen repository #{r.name} does not include a default jpa persistence unit but there is a Dbt database with key :default"
              end
            end
          end
        end
      end
    end
  end
end
