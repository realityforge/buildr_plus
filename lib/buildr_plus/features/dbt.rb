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

    attr_writer :library

    # Is the db jar created meant to be a library jar?
    def library?
      @library.nil? ? false : @library
    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'dbt'

      Dbt::Config.driver = 'postgres' if BuildrPlus::Db.pgsql?
      if Dbt.repository.database_for_key?(:default)
        database = Dbt.repository.database_for_key(:default)
        database.search_dirs = %w(database) if !database.search_dirs? && !BuildrPlus::FeatureManager.activated?(:domgen)
      end
    end

    after_define do |buildr_project|
      if buildr_project.ipr?
        # Make sure all the data sources in the configuration file are mapped to idea project
        Dbt::Buildr.add_idea_data_sources_from_configuration_file(buildr_project)

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
