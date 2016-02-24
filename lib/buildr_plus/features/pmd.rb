module BuildrPlus
  class PmdConfig
    class << self
      def default_pmd_rules
        'au.com.stocksoftware.pmd:pmd:xml:1.2'
      end

      def pmd_rules
        @pmd_rules || self.default_pmd_rules
      end

      def pmd_rules=(pmd_rules)
        @pmd_rules = pmd_rules
      end
    end
  end
  module CheckstyleExtension
    module ProjectExtension
      include Extension

      after_define do |project|
        project.pmd.rule_set_artifacts << PmdConfig.pmd_rules if project.pmd.enabled?
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::CheckstyleExtension::ProjectExtension
end
