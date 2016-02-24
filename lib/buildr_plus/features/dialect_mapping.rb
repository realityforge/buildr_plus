module BuildrPlus
  module DialectMappingExtension
    module ProjectExtension
      include Extension

      after_define do |project|
        if project.ipr?
          project.ipr.mssql_dialect_mapping if BuildrPlus::DbConfig.mssql?
          project.ipr.postgres_dialect_mapping if BuildrPlus::DbConfig.pgsql?
        end
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::DialectMappingExtension::ProjectExtension
end
