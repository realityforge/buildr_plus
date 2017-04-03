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

BuildrPlus::FeatureManager.feature(:libs) do |f|
  f.enhance(:Config) do

    def mustache
      %w(com.github.spullara.mustache.java:compiler:jar:0.8.15)
    end

    def javacsv
      %w(net.sourceforge.javacsv:javacsv:jar:2.1)
    end

    def geotools_for_geolatte
      %w(org.geotools:gt-main:jar:9.4 org.geotools:gt-metadata:jar:9.4 org.geotools:gt-api:jar:9.4 org.geotools:gt-epsg-wkt:jar:9.4 org.geotools:gt-opengis:jar:9.4 org.geotools:gt-transform:jar:9.4 org.geotools:gt-geometry:jar:9.4 org.geotools:gt-jts-wrapper:jar:9.4 org.geotools:gt-referencing:jar:9.4 net.java.dev.jsr-275:jsr-275:jar:1.0-beta-2 java3d:vecmath:jar:1.3.2 javax.media:jai_core:jar:1.1.3)
    end

    def jts
      %w(com.vividsolutions:jts:jar:1.13)
    end

    # Support geo libraries for geolatte
    def geolatte_support
      self.jts + self.slf4j
    end

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
      %w(fish.payara.extras:payara-embedded-all:jar:4.1.1.171.1)
    end

    def eclipselink
      'org.eclipse.persistence:eclipselink:jar:2.6.0'
    end

    def mockito
      %w(org.mockito:mockito-all:jar:1.10.19)
    end

    def objenesis
      %w(org.objenesis:objenesis:jar:2.5.1)
    end

    def powermock_version
      '1.6.6'
    end

    def powermock_javaagent
      "org.powermock:powermock-module-javaagent:jar:#{powermock_version}"
    end

    def powermock
      %W(
        org.powermock:powermock-core:jar:#{powermock_version}
        org.powermock:powermock-reflect:jar:#{powermock_version}
        org.powermock:powermock-module-testng-common:jar:#{powermock_version}
        org.powermock:powermock-module-testng:jar:#{powermock_version}
        org.powermock:powermock-api-mockito:jar:#{powermock_version}
        org.powermock:powermock-api-mockito-common:jar:#{powermock_version}
        org.powermock:powermock-api-support:jar:#{powermock_version}
        org.javassist:javassist:jar:3.21.0-GA
        org.powermock:powermock-module-testng-agent:jar:#{powermock_version}
        #{powermock_javaagent}
      ) + self.objenesis
    end

    def jackson_annotations
      %w(com.fasterxml.jackson.core:jackson-annotations:jar:2.5.4)
    end

    def jackson_core
      %w(com.fasterxml.jackson.core:jackson-core:jar:2.5.4)
    end

    def jackson_databind
      %w(com.fasterxml.jackson.core:jackson-databind:jar:2.5.4)
    end

    def jackson_gwt_support
      self.jackson_core + self.jackson_databind + self.jackson_annotations
    end

    def jsinterop
      %w(com.google.jsinterop:jsinterop-annotations:jar:1.0.1 com.google.jsinterop:jsinterop-annotations:jar:sources:1.0.1)
    end

    def gwt_user
      %w(com.google.gwt:gwt-user:jar:2.8.0 org.w3c.css:sac:jar:1.3) + self.jsinterop
    end

    def gwt_servlet
      %w(com.google.gwt:gwt-servlet:jar:2.8.0)
    end

    def gwt_dev
      'com.google.gwt:gwt-dev:jar:2.8.0'
    end

    def javax_inject
      %w(javax.inject:javax.inject:jar:1)
    end

    def gwt_gin
      %w(com.google.gwt.inject:gin:jar:2.1.2) + self.javax_inject + self.guice + self.gwt_user
    end

    def gwt_property_source
      %w(org.realityforge.gwt.property-source:gwt-property-source:jar:0.2)
    end

    def gwt_webpoller
      %w(org.realityforge.gwt.webpoller:gwt-webpoller:jar:0.9.3)
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
      %w(org.realityforge.gwt.lognice:gwt-lognice:jar:0.4)
    end

    def gwt_appcache_client
      %w(org.realityforge.gwt.appcache:gwt-appcache-client:jar:1.0.9 org.realityforge.gwt.appcache:gwt-appcache-linker:jar:1.0.9)
    end

    def gwt_appcache_server
      %w(org.realityforge.gwt.appcache:gwt-appcache-server:jar:1.0.9)
    end

    # The appcache code required to exist on gwt path during compilation
    def gwt_appcache
      self.gwt_appcache_client + self.gwt_appcache_server
    end

    def gwt_cache_filter
      %w(org.realityforge.gwt.cache-filter:gwt-cache-filter:jar:0.7)
    end

    def simple_session_filter
      %w(org.realityforge.ssf:simple-session-filter:jar:0.7)
    end

    def field_filter
      %w(org.realityforge.rest.field_filter:rest-field-filter:jar:0.4)
    end

    def rest_criteria
      %w(org.realityforge.rest.criteria:rest-criteria:jar:0.9.5 org.antlr:antlr4-runtime:jar:4.3 org.antlr:antlr4-annotations:jar:4.3) + self.field_filter
    end

    def commons_logging
      %w(commons-logging:commons-logging:jar:1.2)
    end

    def commons_codec
      %w(commons-codec:commons-codec:jar:1.9)
    end

    def bouncycastle
      %w(org.bouncycastle:bcprov-jdk15on:jar:1.52 org.bouncycastle:bcpkix-jdk15on:jar:1.52)
    end

    def proxy_servlet
      self.httpclient + %w(org.realityforge.proxy-servlet:proxy-servlet:jar:0.2.0)
    end

    def httpclient
      %w(org.apache.httpcomponents:httpclient:jar:4.5 org.apache.httpcomponents:httpcore:jar:4.4.1) +
        self.commons_logging + self.commons_codec
    end

    def failsafe
      %w(net.jodah:failsafe:jar:1.0.3)
    end

    def keycloak_gwt
      %w(org.realityforge.gwt.keycloak:gwt-keycloak:jar:0.1)
    end

    def keycloak_domgen_support
      %w(org.realityforge.keycloak.domgen:keycloak-domgen-support:jar:1.3)
    end

    def jboss_logging
      %w(org.jboss.logging:jboss-logging:jar:3.3.0.Final)
    end

    def keycloak_core
      %w(
        org.keycloak:keycloak-core:jar:2.0.0.Final
        org.keycloak:keycloak-common:jar:2.0.0.Final
      ) + self.bouncycastle
    end

    def keycloak
      %w(
        org.keycloak:keycloak-servlet-filter-adapter:jar:2.0.0.Final
        org.keycloak:keycloak-adapter-spi:jar:2.0.0.Final
        org.keycloak:keycloak-adapter-core:jar:2.0.0.Final
        org.realityforge.org.keycloak:keycloak-servlet-adapter-spi:jar:2.0.0.Final
      ) + self.keycloak_core + self.keycloak_domgen_support + self.httpclient + self.jboss_logging
    end

    def replicant_version
      '0.5.78'
    end

    def replicant_shared
      %W(org.realityforge.replicant:replicant-shared:jar:#{replicant_version})
    end

    def replicant_client_common
      %W(org.realityforge.replicant:replicant-client-common:jar:#{replicant_version}) + self.replicant_shared + self.gwt_webpoller + self.gwt_datatypes
    end

    def replicant_client_qa_support
      %W(org.realityforge.replicant:replicant-client-qa-support:jar:#{replicant_version}) + self.guiceyloops_gwt
    end

    def replicant_ee_client
      %W(org.realityforge.replicant:replicant-client-ee:jar:#{replicant_version}) + self.replicant_client_common
    end

    def replicant_gwt_client
      %W(org.realityforge.replicant:replicant-client-gwt:jar:#{replicant_version}) + self.replicant_client_common + self.gwt_property_source
    end

    def replicant_server
      %W(org.realityforge.replicant:replicant-server:jar:#{replicant_version}) + self.replicant_shared + self.simple_session_filter + self.gwt_rpc + self.field_filter
    end

    def gwt_rpc
      self.gwt_datatypes + self.jackson_gwt_support + self.gwt_servlet
    end

    def guice
      %w(aopalliance:aopalliance:jar:1.0 com.google.inject:guice:jar:3.0 com.google.inject.extensions:guice-assistedinject:jar:3.0)
    end

    def awaitility
      %w(org.awaitility:awaitility:jar:2.0.0)
    end

    def testng_version
      '6.11'
    end

    def testng
      %W(org.testng:testng:jar:#{testng_version})
    end

    def jndikit
      %w(org.realityforge.jndikit:jndikit:jar:1.4)
    end

    def guiceyloops
      self.guiceyloops_gwt + self.glassfish_embedded
    end

    def guiceyloops_lib
      'org.realityforge.guiceyloops:guiceyloops:jar:0.87'
    end

    def guiceyloops_gwt
      [guiceyloops_lib] + self.mockito + self.guice + self.testng
    end

    def glassfish_timers_domain
      %W(org.realityforge.glassfish.timers#{BuildrPlus::Db.pgsql? ? '.pg' : ''}:glassfish-timers-domain:json:0.6)
    end

    def glassfish_timers_db
      %W(org.realityforge.glassfish.timers#{BuildrPlus::Db.pgsql? ? '.pg' : ''}:glassfish-timers-db:jar:0.6)
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

    def postgis
      %w(org.postgis:postgis-jdbc:jar:1.3.3)
    end

    def db_drivers
      return self.jtds if BuildrPlus::Db.mssql?
      return self.postgresql + (BuildrPlus::FeatureManager.activated?(:geolatte) ? self.postgis : []) if BuildrPlus::Db.pgsql?
      []
    end
  end
end
