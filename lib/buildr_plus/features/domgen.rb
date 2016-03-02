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

begin
  require 'domgen'
rescue LoadError
  # Ignored
end

if Object.const_defined?('Domgen')
  module BuildrPlus
    class DomgenConfig
      class << self
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
          BuildrPlus::DbConfig.mssql? ? self.mssql_generators : BuildrPlus::DbConfig.pgsql? ? pgsql_generators : []
        end

        def database_target_dir
          @database_target_dir || 'database/generated'
        end

        def database_target_dir=(database_target_dir)
          @database_target_dir = database_target_dir
        end
      end
    end

    module DomgenExtension
      module ProjectExtension
        include Extension
        BuildrPlus::ExtensionRegistry.register(self)

        first_time do
          base_directory = File.dirname(Buildr.application.buildfile.to_s)
          candidate_file = File.expand_path("#{base_directory}/architecture.rb")

          Domgen::Build.define_load_task if ::File.exist?(candidate_file)

          Domgen::Build.define_generate_xmi_task

          if Object.const_defined?('Dbt')
            if Dbt.repository.database_for_key?(:default)
              Domgen::Build.define_generate_task(BuildrPlus::DomgenConfig.db_generators, :key => :sql, :target_dir => BuildrPlus::DomgenConfig.database_target_dir)

              database = Dbt.repository.database_for_key(:default)
              database.search_dirs = %W(#{BuildrPlus::DomgenConfig.database_target_dir} database)
              database.enable_domgen
            end
          end
        end
      end
    end
  end
end
