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

    def giggle
      'org.realityforge.giggle:giggle-compiler:jar:all:0.13'
    end

    def mustache
      %w(com.github.spullara.mustache.java:compiler:jar:0.9.6) + self.guava
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

    def jetbrains_annotations
      %w(org.realityforge.org.jetbrains.annotations:org.jetbrains.annotations:jar:1.6.0)
    end

    def javax_annotations
      %w(org.realityforge.javax.annotation:javax.annotation:jar:1.0.1)
    end

    def spotbugs_provided
      %w(com.github.spotbugs:spotbugs-annotations:jar:3.1.5 net.jcip:jcip-annotations:jar:1.0) + self.javax_annotations
    end

    def ee_provided
      %w(javax:javaee-api:jar:8.0.1) + self.spotbugs_provided + self.jetbrains_annotations
    end

    def glassfish_embedded
      %w(fish.payara.extras:payara-embedded-all:jar:5.2020.3)
    end

    def eclipselink
      'org.eclipse.persistence:eclipselink:jar:2.7.4'
    end

    def mockito
      %w(org.mockito:mockito-all:jar:1.10.19)
    end

    def jackson_annotations
      %w(com.fasterxml.jackson.core:jackson-annotations:jar:2.10.4)
    end

    def jackson_core
      %w(com.fasterxml.jackson.core:jackson-core:jar:2.10.4)
    end

    def jackson_databind
      %w(com.fasterxml.jackson.core:jackson-databind:jar:2.10.4) + self.jackson_core + self.jackson_annotations
    end

    def jackson_datatype_jdk8
      %w(com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.9.9)
    end

    def jackson_datatype_jsr310
      %w(com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.9.9)
    end

    def braincheck
      %w(org.realityforge.braincheck:braincheck:jar:1.29.0)
    end

    def jsinterop
      %w(com.google.jsinterop:jsinterop-annotations:jar:2.0.0)
    end

    def jsinterop_base
      %w(com.google.jsinterop:base:jar:1.0.0) + self.jsinterop
    end

    def elemental2_version
      '2.27'
    end

    def elemental2_group_id
      'org.realityforge.com.google.elemental2'
    end

    def elemental2_core
      %W(#{elemental2_group_id}:elemental2-core:jar:#{elemental2_version}) + self.jsinterop_base
    end

    def elemental2_dom
      %W(#{elemental2_group_id}:elemental2-dom:jar:#{elemental2_version}) + self.elemental2_promise
    end

    def elemental2_promise
      %W(#{elemental2_group_id}:elemental2-promise:jar:#{elemental2_version}) + self.elemental2_core
    end

    def elemental2_webstorage
      %W(#{elemental2_group_id}:elemental2-webstorage:jar:#{elemental2_version}) + self.elemental2_dom
    end

    def gwt_user
      %w(com.google.gwt:gwt-user:jar:2.9.0 org.w3c.css:sac:jar:1.3) + self.jsinterop
    end

    def gwt_servlet
      %w(com.google.gwt:gwt-servlet:jar:2.9.0)
    end

    def gwt_dev
      'com.google.gwt:gwt-dev:jar:2.9.0'
    end

    def javax_inject
      %w(javax.inject:javax.inject:jar:1)
    end

    def javax_inject_gwt
      %w(javax.inject:javax.inject:jar:sources:1) + self.javax_inject
    end

    def gwt_serviceworker
      %w(org.realityforge.gwt.serviceworker:gwt-serviceworker-linker:jar:0.02)
    end

    def gwt_cache_filter
      %w(org.realityforge.gwt.cache-filter:gwt-cache-filter:jar:0.9)
    end

    def field_filter
      %w(org.realityforge.rest.field_filter:rest-field-filter:jar:0.4)
    end

    def timeservice
      %w(org.realityforge.timeservice:timeservice:jar:0.02)
    end

    def graphql_java
      %w(com.graphql-java:graphql-java:jar:13.0) + self.slf4j + self.antlr4_runtime + self.graphql_java_dataloader
    end

    def graphql_java_dataloader
      %w(com.graphql-java:java-dataloader:jar:2.1.1 org.reactivestreams:reactive-streams:jar:1.0.2)
    end

    def graphql_java_servlet
      %w(com.graphql-java-kickstart:graphql-java-servlet:jar:8.0.0) +
        self.graphql_java +
        self.jackson_annotations +
        self.jackson_core +
        self.jackson_databind +
        self.jackson_datatype_jdk8 +
        self.guava # Expected 24.1.1-jre
    end

    def graphql_java_scalars
      %w(org.realityforge.graphql.scalars:graphql-java-scalars:jar:0.01)
    end

    def antlr4_runtime
      %w(org.antlr:antlr4-runtime:jar:4.7.2)
    end

    def rest_criteria
      %w(org.realityforge.rest.criteria:rest-criteria:jar:0.9.6) +
        self.antlr4_runtime +
        self.field_filter
    end

    def commons_logging
      %w(commons-logging:commons-logging:jar:1.2)
    end

    def commons_codec
      %w(commons-codec:commons-codec:jar:1.11)
    end

    def commons_io
      %w(commons-io:commons-io:jar:1.3.1)
    end

    def bouncycastle
      %w(org.bouncycastle:bcprov-jdk15on:jar:1.65 org.bouncycastle:bcpkix-jdk15on:jar:1.65)
    end

    def proxy_servlet
      self.httpclient + %w(org.realityforge.proxy-servlet:proxy-servlet:jar:0.3.0)
    end

    def httpclient
      %w(org.apache.httpcomponents:httpclient:jar:4.5.12 org.apache.httpcomponents:httpcore:jar:4.4.13) +
        self.commons_logging + self.commons_codec
    end

    def failsafe
      %w(net.jodah:failsafe:jar:1.0.3)
    end

    def keycloak_gwt
      %w(org.realityforge.gwt.keycloak:gwt-keycloak:jar:0.9) + self.elemental2_webstorage
    end

    def keycloak_domgen_support
      %w(org.realityforge.keycloak.domgen:keycloak-domgen-support:jar:1.5)
    end

    def keycloak_authfilter
      %w(org.realityforge.keycloak.client.authfilter:keycloak-jaxrs-client-authfilter:jar:1.04)
    end

    def jboss_logging
      %w(org.jboss.logging:jboss-logging:jar:3.4.1.Final)
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

    def keycloak_core_v11
      %w(
        org.keycloak:keycloak-core:jar:11.0.0
        org.keycloak:keycloak-common:jar:11.0.0
        com.sun.activation:jakarta.activation:jar:1.2.1
      ) + self.bouncycastle
    end

    def keycloak_v11
      %w(
        org.keycloak:keycloak-servlet-filter-adapter:jar:11.0.0
        org.keycloak:keycloak-adapter-spi:jar:11.0.0
        org.keycloak:keycloak-adapter-core:jar:11.0.0
        org.keycloak:keycloak-servlet-adapter-spi:jar:11.0.0
      ) + self.keycloak_core_v11 + self.keycloak_domgen_support + self.httpclient + self.jboss_logging
    end

    def simple_keycloak_service
      %w(org.realityforge.keycloak.sks:simple-keycloak-service:jar:0.2)
    end

    def guava
      %w(com.google.guava:guava:jar:27.1-jre)
    end

    def arez_version
      '0.192'
    end

    def arez
      %W(org.realityforge.arez:arez-core:jar:#{arez_version}) + self.braincheck + self.jetbrains_annotations + self.grim_annotations
    end

    def arez_processor
      %W(org.realityforge.arez:arez-processor:jar:#{arez_version})
    end

    def arez_spytools
      %w(org.realityforge.arez.spytools:arez-spytools:jar:0.120)
    end

    def arez_testng
      %w(org.realityforge.arez.testng:arez-testng:jar:0.24)
    end

    def arez_dom
      %w(org.realityforge.arez.dom:arez-dom:jar:0.80)
    end

    def arez_persist_version
      '0.21'
    end

    def arez_persist_core
      %W(org.realityforge.arez.persist:arez-persist-core:jar:#{arez_persist_version})
    end

    def arez_persist_processor
      %W(org.realityforge.arez.persist:arez-persist-processor:jar:#{arez_persist_version})
    end

    def grim_annotations
      %w(org.realityforge.grim:grim-annotations:jar:0.04)
    end

    def router_fu_version
      '0.31'
    end

    def router_fu
      %W(org.realityforge.router.fu:router-fu-core:jar:#{router_fu_version}) + self.braincheck
    end

    def router_fu_processor
      %W(org.realityforge.router.fu:router-fu-processor:jar:#{router_fu_version})
    end

    def sting_version
      '0.16'
    end

    def sting_core
      %W(org.realityforge.sting:sting-core:jar:#{sting_version})
    end

    def sting_processor
      %W(org.realityforge.sting:sting-processor:jar:#{sting_version})
    end

    def zemeckis_core
      %w(org.realityforge.zemeckis:zemeckis-core:jar:0.08) + self.braincheck + self.jetbrains_annotations + self.grim_annotations
    end

    def react4j_version
      '0.179'
    end

    def react4j
      %W(
        org.realityforge.react4j:react4j-core:jar:#{react4j_version}
        org.realityforge.react4j:react4j-dom:jar:#{react4j_version}
      ) + self.elemental2_dom + self.zemeckis_core
    end

    def react4j_processor
      %W(org.realityforge.react4j:react4j-processor:jar:#{react4j_version})
    end

    def replicant_version
      '6.105'
    end

    def replicant_client
      %W(org.realityforge.replicant:replicant-client:jar:#{replicant_version}) +
        self.elemental2_webstorage +
        self.zemeckis_core
    end

    def replicant_server
      %W(org.realityforge.replicant:replicant-server:jar:#{replicant_version}) + self.gwt_rpc
    end

    def gwt_rpc
      self.jackson_databind + self.gwt_servlet
    end

    def guice
      %w(aopalliance:aopalliance:jar:1.0 org.ow2.asm:asm:jar:7.1 au.com.stocksoftware.com.google.inject:guice:jar:4.1.1-stock)
    end

    def awaitility
      %w(org.awaitility:awaitility:jar:2.0.0)
    end

    def testng_version
      '6.14.3'
    end

    def testng
      %W(org.testng:testng:jar:#{testng_version} com.beust:jcommander:jar:1.72)
    end

    def jndikit
      %w(org.realityforge.jndikit:jndikit:jar:1.4)
    end

    def guiceyloops
      self.mockito + self.testng + %w(org.realityforge.guiceyloops:guiceyloops:jar:0.108) + self.guice + self.glassfish_embedded
    end

    def glassfish_timers_domain
      %W(org.realityforge.glassfish.timers#{BuildrPlus::Db.pgsql? ? '.pg' : ''}:glassfish-timers-domain:json:0.7)
    end

    def glassfish_timers_db
      %W(org.realityforge.glassfish.timers#{BuildrPlus::Db.pgsql? ? '.pg' : ''}:glassfish-timers-db:jar:0.7)
    end

    def slf4j
      %w(org.slf4j:slf4j-api:jar:1.7.25 org.slf4j:slf4j-jdk14:jar:1.7.25)
    end

    def json_schema_validator
      %w(
          com.networknt:json-schema-validator:jar:1.0.43
          org.apache.commons:commons-lang3:jar:3.5
          org.jruby.joni:joni:jar:2.1.31
          org.jruby.jcodings:jcodings:jar:1.0.46
      ) + self.jackson_databind + self.slf4j
    end

    def pdfbox
      %w(
        org.apache.pdfbox:pdfbox:jar:2.0.21
        org.apache.pdfbox:fontbox:jar:2.0.21
        org.apache.pdfbox:xmpbox:jar:2.0.21
      ) + self.commons_logging + self.bouncycastle
    end

    def openhtmltopdf
      %w(
        com.openhtmltopdf:openhtmltopdf-pdfbox:jar:1.0.4
        com.openhtmltopdf:openhtmltopdf-core:jar:1.0.4
        com.openhtmltopdf:openhtmltopdf-svg-support:jar:1.0.4
        de.rototor.pdfbox:graphics2d:jar:0.26
        com.openhtmltopdf:openhtmltopdf-core:jar:1.0.4
        com.openhtmltopdf:openhtmltopdf-svg-support:jar:1.0.4
      ) + BuildrPlus::Libs.xmlgraphics + BuildrPlus::Libs.pdfbox
    end

    def xmlgraphics
      %w(
        org.apache.xmlgraphics:batik-anim:jar:1.12
        org.apache.xmlgraphics:batik-awt-util:jar:1.12
        org.apache.xmlgraphics:batik-bridge:jar:1.12
        org.apache.xmlgraphics:batik-codec:jar:1.12
        org.apache.xmlgraphics:batik-constants:jar:1.12
        org.apache.xmlgraphics:batik-css:jar:1.12
        org.apache.xmlgraphics:batik-dom:jar:1.12
        org.apache.xmlgraphics:batik-ext:jar:1.12
        org.apache.xmlgraphics:batik-gvt:jar:1.12
        org.apache.xmlgraphics:batik-i18n:jar:1.12
        org.apache.xmlgraphics:batik-parser:jar:1.12
        org.apache.xmlgraphics:batik-script:jar:1.12
        org.apache.xmlgraphics:batik-svg-dom:jar:1.12
        org.apache.xmlgraphics:batik-svggen:jar:1.12
        org.apache.xmlgraphics:batik-transcoder:jar:1.12
        org.apache.xmlgraphics:batik-util:jar:1.12
        org.apache.xmlgraphics:batik-xml:jar:1.12
        org.apache.xmlgraphics:xmlgraphics-commons:jar:2.4
      ) + self.commons_io + self.xml_apis_ext
    end

    def xml_apis_ext
      %w(xml-apis:xml-apis-ext:jar:1.3.04)
    end

    def thymeleaf
      %w(
        org.thymeleaf:thymeleaf:jar:3.0.11.RELEASE
        ognl:ognl:jar:3.1.12
        org.javassist:javassist:jar:3.20.0-GA
        org.attoparser:attoparser:jar:2.0.5.RELEASE
        org.unbescape:unbescape:jar:1.1.6.RELEASE
        org.thymeleaf.extras:thymeleaf-extras-java8time:jar:3.0.4.RELEASE
      ) + self.commons_logging
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
