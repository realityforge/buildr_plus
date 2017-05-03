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

BuildrPlus::FeatureManager.feature(:dbt => [:db]) do |f|
  f.enhance(:Config) do
    attr_writer :manual_testing_only_databases

    def manual_testing_only_databases
      @manual_testing_only_databases || []
    end

    def manual_testing_only_database?(database_key)
      self.manual_testing_only_databases.any? { |d| d.to_s == database_key.to_s }
    end

    # Any databases that are not able to be standalone databases should
    # register module_group to use instead during build process
    def non_standalone_database_module_groups
      @non_standalone_database_module_groups ||= {}
    end

    attr_writer :library

    # Is the db jar created meant to be a library jar?
    def library?
      @library.nil? ? false : @library
    end

    def database_import?(database_key)
      dbt_database = ::Dbt.database_for_key(database_key)
      return true unless dbt_database.imports.empty?
      return true if (dbt_database.packaged? && dbt_database.extra_actions.any? { |a| a.to_s =~ /import/ })
      false
    end

    attr_writer :add_dependent_artifacts

    def add_dependent_artifacts?
      @add_dependent_artifacts.nil? ? !library? : !!@add_dependent_artifacts
    end

    def add_artifact_unless_present(database, artifact)
      artifact_file = ::Buildr.artifact(artifact).to_s
      if !database.pre_db_artifacts.include?(artifact_file) && !database.post_db_artifacts.include?(artifact_file)
        database.add_pre_db_artifacts(artifact)
      end
    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'dbt'

      Dbt::Config.driver = 'postgres' if BuildrPlus::Db.pgsql?
      if Dbt.repository.database_for_key?(:default)
        database = Dbt.repository.database_for_key(:default)
        database.search_dirs = %w(database) if !database.search_dirs? && !BuildrPlus::FeatureManager.activated?(:domgen)

        if BuildrPlus::Dbt.add_dependent_artifacts?
          if BuildrPlus::FeatureManager.activated?(:appconfig) && BuildrPlus::Appconfig.include_db_artifact?
            BuildrPlus::Dbt.add_artifact_unless_present(database, BuildrPlus::Appconfig.appconfig_db)
          end
          if BuildrPlus::FeatureManager.activated?(:syncrecord) && BuildrPlus::Syncrecord.include_db_artifact?
            BuildrPlus::Dbt.add_artifact_unless_present(database, BuildrPlus::Syncrecord.syncrecord_db)
          end
          if BuildrPlus::FeatureManager.activated?(:mail) && BuildrPlus::Mail.include_db_artifact?
            BuildrPlus::Dbt.add_artifact_unless_present(database, BuildrPlus::Mail.mail_db)
          end
        end
      end

      if BuildrPlus::FeatureManager.activated?(:timerstatus)
        Dbt.add_artifact_based_database(:timers, BuildrPlus::Libs.glassfish_timers_db[0])
      end
      if BuildrPlus::FeatureManager.activated?(:iris_audit)
        Dbt.add_artifact_based_database(:audit, :iris_audit_db)
      end

      if BuildrPlus::Db.mssql? && Dbt.repository.database_for_key?(:default) && BuildrPlus::FeatureManager.activated?(:config)
        database = Dbt.repository.database_for_key(:default)

        desc 'Show all owned databases'
        task 'dbt:show_owned_databases' => ["#{database.task_prefix}:load_config"] do
          sql = "SELECT name FROM sys.databases WHERE name LIKE '#{BuildrPlus::Config.user || 'NOBODY'}_%'"
          puts 'Owned databases:'
          puts '========================================'
          Dbt.runtime.query_in_control_database(database, sql).each do |v|
            puts v['name']
          end
          puts '========================================'
        end

        desc 'Remove all owned databases'
        task 'dbt:remove_owned_databases' => ["#{database.task_prefix}:load_config"] do
          sql = "SELECT name FROM sys.databases WHERE name LIKE '#{BuildrPlus::Config.user || 'NOBODY'}_%'"
          Dbt.runtime.query_in_control_database(database, sql).each do |v|
            name = v['name']
            puts "Dropping database #{name}"
            begin
              Dbt.runtime.drop(database)
            rescue => e
              puts e
            end
          end
        end
      end
    end

    after_define do |buildr_project|
      if buildr_project.ipr?
        buildr_project.group = "#{buildr_project.group}#{BuildrPlus::Db.artifact_suffix}"

        BuildrPlus::Config.load_application_config! if BuildrPlus::FeatureManager.activated?(:config)

        # Make sure all the data sources in the configuration file are mapped to idea project
        Dbt::Buildr.add_idea_data_sources_from_configuration_file(buildr_project)

        Dbt.repository.database_keys.each do |key|
          Dbt.repository.database_for_key(key).database_environment_filter = true
        end

        if Dbt.repository.database_for_key?(:default)
          unless BuildrPlus::Util.subprojects(buildr_project).any? { |p| p == "#{buildr_project.name}:db" }
            buildr_project.instance_eval do
              desc 'DB Archive'
              define 'db' do
                project.no_iml
                project.publish = BuildrPlus::Artifacts.db?
                Dbt.define_database_package(:default, :include_code => !BuildrPlus::Dbt.library?)
              end
            end
          end
        end
      end
    end
  end
end
