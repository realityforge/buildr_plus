module BuildrPlus
  class IdeaCodeStyle
    class << self
      def default_codestyle
        'au.com.stocksoftware.idea.codestyle:idea-codestyle:xml:1.3'
      end

      def codestyle
        @codestyle || self.default_codestyle
      end

      def codestyle=(codestyle)
        @codestyle = codestyle
      end
    end
  end
  module CodestyleExtension
    module ProjectExtension
      include Extension

      after_define do |project|
        project.ipr.add_component_from_artifact(IdeaCodeStyle.codestyle) if project.ipr?
      end
    end
  end
end

class Buildr::Project
  include BuildrPlus::CodestyleExtension::ProjectExtension
end


