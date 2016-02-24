module BuildrPlus
  class CheckstyleConfig
    class << self
      def default_checkstyle_rules
        'au.com.stocksoftware.checkstyle:checkstyle:xml:1.7'
      end

      def checkstyle_rules
        @checkstyle_rules || self.default_checkstyle_rules
      end

      def checkstyle_rules=(checkstyle_rules)
        @checkstyle_rules = checkstyle_rules
      end
    end
  end
  module CheckstyleExtension
    module ProjectExtension
      include Extension

      before_define do |project|
        checkstyle_dir = project._('etc/checkstyle')
        if ::File.exist?(checkstyle_dir)
          project.checkstyle.config_directory = checkstyle_dir
          project.checkstyle.configuration_artifact = CheckstyleConfig.checkstyle_rules
        end
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::CheckstyleExtension::ProjectExtension
end


