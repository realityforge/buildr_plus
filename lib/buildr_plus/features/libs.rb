#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module BuildrPlus
  class Libs
    class << self

      def geolatte_geom
        %w(org.geolatte:geolatte-geom:jar:0.13)
      end

      def geolatte_geom_jpa
        %w(org.realityforge.geolatte.jpa:geolatte-geom-jpa:jar:0.2)
      end

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

      def jackson_core
        %w(org.codehaus.jackson:jackson-core-asl:jar:1.9.13)
      end

      def jackson_mapper
        %w(org.codehaus.jackson:jackson-mapper-asl:jar:1.9.13)
      end

      def jackson_gwt_support
        self.jackson_core + self.jackson_mapper
      end

      def gwt_user
        %w(com.google.gwt:gwt-user:jar:2.7.0)
      end

      def gwt_servlet
        %w(com.google.gwt:gwt-servlet:jar:2.7.0)
      end

      def gwt_dev
        'com.google.gwt:gwt-dev:jar:2.7.0'
      end

      def gwt_gin
        %w(com.google.gwt.inject:gin:jar:2.1.2 javax.inject:javax.inject:jar:1) + self.guice + self.gwt_user
      end

      def replicant
        %w(org.realityforge.replicant:replicant:jar:0.5.54)
      end

      def gwt_property_source
        %w(org.realityforge.gwt.property-source:gwt-property-source:jar:0.2)
      end

      def gwt_webpoller
        %w(org.realityforge.gwt.webpoller:gwt-webpoller:jar:0.8)
      end

      def gwt_datatypes
        %w(org.realityforge.gwt.datatypes:gwt-datatypes:jar:0.8)
      end

      def gwt_ga
        %w(org.realityforge.gwt.ga:gwt-ga:jar:0.5)
      end

      def gwt_mmvp
        %w(org.realityforge.gwt.mmvp:gwt-mmvp:jar:0.5)
      end

      def gwt_lognice
        %w(org.realityforge.gwt.lognice:gwt-lognice:jar:0.2)
      end

      def gwt_appcache_client
        %w(org.realityforge.gwt.appcache:gwt-appcache-client:jar:1.0.8 org.realityforge.gwt.appcache:gwt-appcache-linker:jar:1.0.8)
      end

      def gwt_appcache_server
        %w(org.realityforge.gwt.appcache:gwt-appcache-server:jar:1.0.8)
      end

      # The appcache code required to exist on gwt path during compilation
      def gwt_appcache
        self.gwt_appcache_client + self.gwt_appcache_server
      end

      def gwt_cache_filter
        %w(org.realityforge.gwt.cache-filter:gwt-cache-filter:jar:0.6)
      end

      def simple_session_filter
        %w(org.realityforge.ssf:simple-session-filter:jar:0.5)
      end

      def field_filter
        %w(org.realityforge.rest.field_filter:rest-field-filter:jar:0.4)
      end

      def rest_criteria
        %w(org.realityforge.rest.criteria:rest-criteria:jar:0.9.3 org.antlr:antlr4-runtime:jar:4.3 org.antlr:antlr4-annotations:jar:4.3) + self.field_filter
      end

      def replicant_client
        self.gwt_gin + self.replicant + self.gwt_property_source + self.gwt_datatypes + self.gwt_webpoller
      end

      def replicant_server
        self.replicant + self.simple_session_filter + self.gwt_datatypes + self.jackson_gwt_support + self.gwt_servlet + self.field_filter
      end

      def guice
        %w(aopalliance:aopalliance:jar:1.0 com.google.inject:guice:jar:3.0 com.google.inject.extensions:guice-assistedinject:jar:3.0)
      end

      def testng
        %w(org.testng:testng:jar:6.8)
      end

      def jndikit
        %w(org.realityforge.jndikit:jndikit:jar:1.4)
      end

      def guiceyloops
        self.glassfish_embedded + self.guiceyloops_gwt
      end

      def guiceyloops_gwt
        %w(org.realityforge.guiceyloops:guiceyloops:jar:0.65) + self.mockito + self.guice + self.testng
      end

      def slf4j
        %w(org.slf4j:slf4j-api:jar:1.6.6 org.slf4j:slf4j-jdk14:jar:1.6.6)
      end

      def greenmail
        %w(com.icegreen:greenmail:jar:1.4.1) + self.slf4j
      end

      def greenmail_server
        'com.icegreen:greenmail-webapp:war:1.4.1'
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
