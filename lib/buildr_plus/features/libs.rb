module BuildrPlus
  class Libs
    class << self

      def findbugs_provided
        %w(com.google.code.findbugs:jsr305:jar:3.0.0 com.google.code.findbugs:annotations:jar:3.0.0)
      end

      def ee_provided
        %w(javax:javaee-api:jar:7.0) + self.findbugs_provided
      end

      def glassfish_embedded
        %w(fish.payara.extras:payara-embedded-all:jar:4.1.1.154)
      end

      def mockito
        %w(org.mockito:mockito-all:jar:1.9.5)
      end

      def guice
        %w(aopalliance:aopalliance:jar:1.0 com.google.inject:guice:jar:3.0 com.google.inject.extensions:guice-assistedinject:jar:3.0)
      end

      def guiceyloops
        %w(org.realityforge.guiceyloops:guiceyloops:jar:0.65) + self.mockito + self.guice + self.glassfish_embedded
      end

      def jtds
        %w(net.sourceforge.jtds:jtds:jar:1.3.1)
      end

      def postgresql
        %w(org.postgresql:postgresql:jar:9.2-1003-jdbc4)
      end

      def db_drivers
        (BuildrPlus::DbConfig.tiny_tds_defined? ? self.jtds : []) + (BuildrPlus::DbConfig.pg_defined? ? self.postgresql : [])
      end
    end
  end
end
