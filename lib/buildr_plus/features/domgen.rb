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

BuildrPlus::FeatureManager.feature(:domgen) do |f|
  f.enhance(:Config) do
    def default_pgsql_generators
      [:pgsql]
    end

    def default_mssql_generators
      [:mssql]
    end

    def additional_pgsql_generators
      @additional_pgsql_generators || []
    end

    def additional_pgsql_generators=(generators)
      unless generators.is_a?(Array) && generators.all? { |e| e.is_a?(Symbol) }
        raise "additional_pgsql_generators parameter '#{generators.inspect}' is not an array of symbols"
      end
      @additional_pgsql_generators = generators
    end

    def additional_mssql_generators
      @additional_mssql_generators || []
    end

    def additional_mssql_generators=(generators)
      unless generators.is_a?(Array) && generators.all? { |e| e.is_a?(Symbol) }
        raise "additional_mssql_generators parameter '#{generators.inspect}' is not an array of symbols"
      end
      @additional_mssql_generators = generators
    end

    def mssql_generators
      self.default_mssql_generators + self.additional_mssql_generators
    end

    def pgsql_generators
      self.default_pgsql_generators + self.additional_pgsql_generators
    end

    def db_generators
      BuildrPlus::Db.mssql? ? self.mssql_generators : BuildrPlus::Db.pgsql? ? pgsql_generators : []
    end

    def dialect_specific_database_paths
      BuildrPlus::Db.mssql? ? %w(database/mssql) : BuildrPlus::Db.pgsql? ? %w(database/pgsql) : []
    end

    def database_target_dir
      @database_target_dir || 'database/generated'
    end

    def database_target_dir=(database_target_dir)
      @database_target_dir = database_target_dir
    end

    def enforce_postload_constraints?
      @enforce_postload_constraints.nil? ? true : !!@enforce_postload_constraints
    end

    attr_writer :enforce_postload_constraints

    def enforce_package_name?
      enforce_postload_constraints? && (@enforce_package_name.nil? ? true : !!@enforce_package_name)
    end

    attr_writer :enforce_package_name
  end

  f.enhance(:ProjectExtension) do

    attr_accessor :domgen_filter

    def additional_domgen_generators
      @additional_domgen_generators ||= []
    end

    first_time do
      require 'domgen'

      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      candidate_file = File.expand_path("#{base_directory}/architecture.rb")

      Domgen::Build.define_load_task if ::File.exist?(candidate_file)

      Domgen::Build.define_generate_xmi_task

      if BuildrPlus::FeatureManager.activated?(:dbt) && Dbt.repository.database_for_key?(:default)
        generators = BuildrPlus::Domgen.db_generators
        if BuildrPlus::FeatureManager.activated?(:sync)
          generators << (BuildrPlus::Db.mssql? ? :sync_sql : :sync_pgsql)
        end
        if BuildrPlus::FeatureManager.activated?(:appconfig)
          generators << (BuildrPlus::Db.mssql? ? :appconfig_mssql : :appconfig_pgsql)
        end
        Domgen::Build.define_generate_task(generators, :key => :sql, :target_dir => BuildrPlus::Domgen.database_target_dir)

        database = Dbt.repository.database_for_key(:default)
        default_search_dirs = %W(#{BuildrPlus::Domgen.database_target_dir} database) + BuildrPlus::Domgen.dialect_specific_database_paths
        database.search_dirs = default_search_dirs unless database.search_dirs?
        database.enable_domgen
      end
    end

    after_define do |project|
      if project.ipr?
        project.task(':domgen:postload') do
          if BuildrPlus::Domgen.enforce_postload_constraints?
            facet_mapping =
              {
                :keycloak => :keycloak,
                :jms => :jms,
                :mail => :mail,
                :soap => :jws,
                :gwt => :gwt,
                :sync => :sync,
                :replicant => :imit,
                :gwt_cache_filter => :gwt_cache_filter,
                :appconfig => :appconfig,
                :syncrecord => :syncrecord,
                :timerstatus => :timerstatus,
                :appcache => :appcache
              }

            Domgen.repositorys.each do |r|
              if r.java? && BuildrPlus::Domgen.enforce_package_name?
                if r.java.base_package != project.group_as_package
                  raise "Buildr projects group '#{project.group_as_package}' expected to match domgens 'java.base_package' setting ('#{r.java.base_package}') but it does not."
                end
              end

              if r.application? && r.application.db_deployable? && BuildrPlus::Dbt.library?
                raise "Domgen declared 'repository.application.db_deployable = true' but buildr configured 'BuildrPlus::Dbt.library = true'."
              end

              if r.application? && r.application.user_experience? && !BuildrPlus::FeatureManager.activated?(:role_user_experience)
                raise "Domgen declared 'repository.application.user_experience = true' but buildr has not configured user_experience role."
              elsif r.application? && !r.application.user_experience? && BuildrPlus::FeatureManager.activated?(:role_user_experience)
                raise "Domgen declared 'repository.application.user_experience = false' but buildr has configured user_experience role."
              end

              if r.application? && r.sql? && !r.application.db_deployable? && !BuildrPlus::Dbt.library?
                raise "Domgen declared 'repository.application.db_deployable = false' but buildr configured 'BuildrPlus::Dbt.library = false'."
              end

              if r.application? && r.application.service_library? && !BuildrPlus::FeatureManager.activated?(:role_library)
                raise "Domgen declared 'repository.application.service_library = true' but buildr is not configured as a library."
              elsif r.application? && !r.application.service_library? && BuildrPlus::FeatureManager.activated?(:role_library)
                raise "Domgen declared 'repository.application.service_library = false' but buildr is configured as a library."
              end

              facet_mapping.each_pair do |buildr_plus_facet, domgen_facet|
                if BuildrPlus::FeatureManager.activated?(buildr_plus_facet) && !r.facet_enabled?(domgen_facet)
                  raise "BuildrPlus feature '#{buildr_plus_facet}' requires that domgen facet '#{domgen_facet}' is enabled but it is not."
                end
                if !BuildrPlus::FeatureManager.activated?(buildr_plus_facet) && r.facet_enabled?(domgen_facet)
                  raise "Domgen facet '#{domgen_facet}' requires that buildrPlus feature '#{buildr_plus_facet}' is enabled but it is not."
                end
              end
              if BuildrPlus::FeatureManager.activated?(:keycloak)
                domgen_clients = r.keycloak.clients.collect{|client| client.key.to_s}.sort.uniq
                clients = BuildrPlus::Keycloak.client_types.sort.uniq
                if clients != domgen_clients
                  raise "Domgen repository #{r.name} declares keycloak clients #{domgen_clients.inspect} while buildr is aware of #{clients.inspect}"
                end
              end
              if BuildrPlus::FeatureManager.activated?(:appcache) && BuildrPlus::FeatureManager.activated?(:role_library)
                raise "Can not enable the BuildrPlus 'appcache' feature for libraries"
              end

              if r.imit? && r.imit.support_ee_client? && !BuildrPlus::Artifacts.replicant_ee_client?
                raise "Domgen repository #{r.name} declares repository.imit.support_ee_client = true while in BuildrPlus BuildrPlus::Artifacts.replicant_ee_client? is false"
              elsif !(r.imit? && r.imit.support_ee_client?) && BuildrPlus::Artifacts.replicant_ee_client?
                raise "Domgen repository #{r.name} declares repository.imit.support_ee_client = false while in BuildrPlus BuildrPlus::Artifacts.replicant_ee_client? is true"
              end

              if !r.robots? && BuildrPlus::Artifacts.war?
                raise "Domgen repository #{r.name} should enable robots facet as BuildrPlus BuildrPlus::Artifacts.war? is true"
              elsif r.robots? && !BuildrPlus::Artifacts.war?
                raise "Domgen repository #{r.name} should disable robots facet as BuildrPlus BuildrPlus::Artifacts.war? is false"
              end
            end
          end
        end
      end
    end
  end
end
