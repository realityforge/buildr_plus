module BuildrPlus
  module ProductVersionExtension
    module ProjectExtension
      include Extension

      before_define do |project|
        project.version = ENV['PRODUCT_VERSION'] if ENV['PRODUCT_VERSION']
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::ProductVersionExtension::ProjectExtension
end
