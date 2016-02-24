module BuildrPlus
  module MssqlDialectMappingExtension
    module ProjectExtension
      include Extension

      after_define do |project|
        project.ipr.mssql_dialect_mapping if project.ipr? && defined?(:TinyTds)
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::MssqlDialectMappingExtension::ProjectExtension
end


