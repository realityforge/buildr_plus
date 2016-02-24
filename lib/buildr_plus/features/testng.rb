module BuildrPlus
  module TestNGExtension
    module ProjectExtension
      include Extension

      after_define do |project|
        project.test.using :testng
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::TestNGExtension::ProjectExtension
end
