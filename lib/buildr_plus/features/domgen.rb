begin
  require 'domgen'
rescue LoadError
  # Ignored
end

if defined?(:Domgen)
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
      end
    end

    module DomgenExtension
      module ProjectExtension
        include Extension

        first_time do
          base_directory = File.dirname(Buildr.application.buildfile.to_s)
          candidate_file = File.expand_path("#{base_directory}/architecture.rb")

          Domgen::Build.define_load_task if ::File.exist?(candidate_file)

          Domgen::Build.define_generate_task(BuildrPlus::DomgenConfig.db_generators, :key => :sql, :target_dir => 'database/generated')
        end
      end
    end
  end

  class Buildr::Project
    include BuildrPlus::DomgenExtension::ProjectExtension
  end
end
