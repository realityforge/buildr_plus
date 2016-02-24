module BuildrPlus
  module CompileOptionsExtension
    module ProjectExtension
      include Extension

      before_define do |project|
        project.compile.options.source = '1.7'
        project.compile.options.target = '1.7'
        project.compile.options.lint = 'all'
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::CompileOptionsExtension::ProjectExtension
end
