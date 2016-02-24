begin
  require 'dbt'
rescue LoadError
  # Ignored
end

if Object.const_defined?('Dbt')
  module BuildrPlus
    module DbtExtension
      module ProjectExtension
        include Extension

        after_define do |project|
          # Make sure all the data sources in the configuration file are mapped to idea project
          Dbt::Buildr.add_idea_data_sources_from_configuration_file(project) if project.ipr?
        end
      end
    end
  end

  class Buildr::Project
    include BuildrPlus::DbtExtension::ProjectExtension
  end
end
