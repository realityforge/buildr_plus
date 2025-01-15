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

    def bazel_depgen
      'org.realityforge.bazel.depgen:bazel-depgen:jar:all:0.19'
    end

    def mustache
      %w(com.github.jknack:handlebars:jar:4.3.1) + self.guava
    end

    def javacsv
      %w(net.sourceforge.javacsv:javacsv:jar:2.1)
    end

    def aws_s3
      %w(org.slf4j:slf4j-api:jar:2.0.9 software.amazon.awssdk:s3:jar:2.29.45 software.amazon.awssdk:third-party-jackson-core:jar:2.29.45 software.amazon.awssdk:json-utils:jar:2.29.45 software.amazon.awssdk:aws-json-protocol:jar:2.29.45 software.amazon.awssdk:checksums:jar:2.29.45 software.amazon.awssdk:checksums-spi:jar:2.29.45 software.amazon.awssdk:protocol-core:jar:2.29.45 software.amazon.awssdk:aws-xml-protocol:jar:2.29.45 software.amazon.awssdk:aws-query-protocol:jar:2.29.45 software.amazon.awssdk:metrics-spi:jar:2.29.45 software.amazon.awssdk:http-auth:jar:2.29.45 software.amazon.awssdk:apache-client:jar:2.29.45 software.amazon.awssdk:http-auth-spi:jar:2.29.45 software.amazon.awssdk:http-auth-aws:jar:2.29.45 software.amazon.awssdk:retries-spi:jar:2.29.45 software.amazon.awssdk:retries:jar:2.29.45 software.amazon.awssdk:endpoints-spi:jar:2.29.45 software.amazon.awssdk:profiles:jar:2.29.45 software.amazon.awssdk:identity-spi:jar:2.29.45 software.amazon.awssdk:utils:jar:2.29.45 software.amazon.awssdk:aws-core:jar:2.29.45 software.amazon.awssdk:sdk-core:jar:2.29.45 software.amazon.awssdk:auth:jar:2.29.45 software.amazon.awssdk:http-client-spi:jar:2.29.45 software.amazon.awssdk:regions:jar:2.29.45)
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
      %w(org.realityforge.org.jetbrains.annotations:org.jetbrains.annotations:jar:1.7.0)
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

    def jakarta_xml_bind_api
      %w(jakarta.xml.bind:jakarta.xml.bind-api:jar:2.3.3)
    end

    def com_sun_xml_bind_jaxb_impl
      %w(com.sun.xml.bind:jaxb-impl:jar:2.3.3)
    end

    def jakarta_xml_ws
      %w(
         jakarta.xml.ws:jakarta.xml.ws-api:jar:2.3.3
         jakarta.jws:jakarta.jws-api:jar:2.1.0
         jakarta.xml.soap:jakarta.xml.soap-api:jar:1.4.2
        ) +
        self.jakarta_xml_bind_api +
        self.com_sun_xml_bind_jaxb_impl +
        self.jakarta_xml_ws_runtime
    end

    def jakarta_xml_ws_runtime
      %w(com.sun.xml.ws:jaxws-rt:jar:2.3.3)
    end

    def glassfish_embedded
      %w(fish.payara.extras:payara-embedded-all:jar:5.2022.5) + self.eclipse_persistence_core
    end

    def eclipse_persistence_core
      %w(org.eclipse.persistence:org.eclipse.persistence.core:jar:2.7.11)
    end

    def mockito
      # TODO: hamcrest only seems to be used by AbstractDatabaseTest across systems so we just decouple the dependency
      %w(
        org.mockito:mockito-core:jar:4.5.1
        net.bytebuddy:byte-buddy:jar:1.12.9
        org.objenesis:objenesis:jar:3.2
        org.hamcrest:hamcrest:jar:2.2
      )
    end

    def jackson_annotations
      %w(com.fasterxml.jackson.core:jackson-annotations:jar:2.17.2)
    end

    def jackson_core
      %w(com.fasterxml.jackson.core:jackson-core:jar:2.17.2)
    end

    def jackson_databind
      %w(com.fasterxml.jackson.core:jackson-databind:jar:2.17.2) + self.jackson_core + self.jackson_annotations
    end

    def jackson_datatype_jdk8
      %w(com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.17.2)
    end

    def jackson_datatype_jsr310
      %w(com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.17.2)
    end

    def jackson_dataformat_yaml
      %w(com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:jar:2.17.2) + self.jackson_databind + self.snakeyaml
    end

    def snakeyaml
      %w(org.yaml:snakeyaml:jar:2.2)
    end

    def braincheck
      %w(org.realityforge.braincheck:braincheck-core:jar:1.31.0)
    end

    def jsinterop
      %w(com.google.jsinterop:jsinterop-annotations:jar:2.1.0)
    end

    def jsinterop_base
      %w(com.google.jsinterop:base:jar:1.0.0) + self.jsinterop
    end

    def gwt_user
      %w(org.gwtproject:gwt-user:jar:2.11.0 org.w3c.css:sac:jar:1.3) + self.jsinterop
    end

    def gwt_servlet
      %w(org.gwtproject:gwt-servlet:jar:2.11.0)
    end

    def gwt_dev
      'org.gwtproject:gwt-dev:jar:2.11.0'
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
      %w(org.realityforge.gwt.keycloak:gwt-keycloak:jar:0.14) + self.akasha
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
        org.keycloak:keycloak-core:jar:11.0.0
        org.keycloak:keycloak-common:jar:11.0.0
        com.sun.activation:jakarta.activation:jar:1.2.1
      ) + self.bouncycastle
    end

    def keycloak
      %w(
        org.keycloak:keycloak-servlet-filter-adapter:jar:11.0.0
        org.keycloak:keycloak-adapter-spi:jar:11.0.0
        org.keycloak:keycloak-adapter-core:jar:11.0.0
        org.keycloak:keycloak-servlet-adapter-spi:jar:11.0.0
      ) + self.keycloak_core + self.keycloak_domgen_support + self.httpclient + self.jboss_logging
    end

    def simple_keycloak_service
      %w(org.realityforge.keycloak.sks:simple-keycloak-service:jar:0.2)
    end

    def guava
      %w(com.google.guava:guava:jar:30.1-jre com.google.guava:failureaccess:jar:1.0.1)
    end

    def arez_version
      '0.214'
    end

    def arez
      %W(org.realityforge.arez:arez-core:jar:#{arez_version}) + self.braincheck + self.jetbrains_annotations + self.grim_annotations
    end

    def arez_processor
      %W(org.realityforge.arez:arez-processor:jar:#{arez_version})
    end

    def arez_spytools
      %W(org.realityforge.arez:arez-extras-spytools:jar:#{arez_version})
    end

    def arez_testng
      %W(org.realityforge.arez:arez-extras-testng:jar:#{arez_version})
    end

    def arez_dom
      %W(org.realityforge.arez:arez-extras-dom:jar:#{arez_version})
    end

    def arez_persist_version
      '0.49'
    end

    def arez_persist_core
      %W(org.realityforge.arez.persist:arez-persist-core:jar:#{arez_persist_version})
    end

    def arez_persist_processor
      %W(org.realityforge.arez.persist:arez-persist-processor:jar:#{arez_persist_version})
    end

    def grim_annotations
      %w(org.realityforge.grim:grim-annotations:jar:0.09)
    end

    def router_fu_version
      'fb129f5'
    end

    def router_fu
      %W(org.realityforge.router.fu:router-fu-core:jar:#{router_fu_version}) + self.braincheck
    end

    def router_fu_processor
      %W(org.realityforge.router.fu:router-fu-processor:jar:#{router_fu_version})
    end

    def sting_version
      '0.27'
    end

    def sting_core
      %W(org.realityforge.sting:sting-core:jar:#{sting_version})
    end

    def sting_processor
      %W(org.realityforge.sting:sting-processor:jar:#{sting_version})
    end

    def zemeckis_core
      %w(org.realityforge.zemeckis:zemeckis-core:jar:0.14) + self.braincheck + self.jetbrains_annotations + self.grim_annotations
    end

    def akasha
      %w(org.realityforge.akasha:akasha-gwt:jar:0.30)
    end

    def react4j_version
      '0.196'
    end

    def react4j
      %W(
        org.realityforge.react4j:react4j-core:jar:#{react4j_version}
        org.realityforge.react4j:react4j-dom:jar:#{react4j_version}
      ) + self.akasha + self.zemeckis_core + self.jsinterop_base
    end

    def react4j_processor
      %W(org.realityforge.react4j:react4j-processor:jar:#{react4j_version})
    end

    def replicant_version
      '6.137'
    end

    def replicant_client
      %W(org.realityforge.replicant:replicant-client:jar:#{replicant_version}) +
        self.akasha +
        self.zemeckis_core
    end

    def replicant_server
      %W(org.realityforge.replicant:replicant-server:jar:#{replicant_version}) + self.gwt_rpc
    end

    def gwt_rpc
      self.jackson_databind + self.gwt_servlet
    end

    def guice
      %w(aopalliance:aopalliance:jar:1.0 org.ow2.asm:asm:jar:9.2 com.google.inject:guice:jar:5.1.0)
    end

    def awaitility
      %w(org.awaitility:awaitility:jar:2.0.0)
    end

    def testng_version
      '7.4.0'
    end

    def testng
      %W(org.testng:testng:jar:#{testng_version} com.beust:jcommander:jar:1.78 org.webjars:jquery:jar:3.5.1)
    end

    def jndikit
      %w(org.realityforge.jndikit:jndikit:jar:1.5)
    end

    def guiceyloops
      self.mockito + self.testng + %w(org.realityforge.guiceyloops:guiceyloops:jar:0.113) + self.guice + self.glassfish_embedded + self.guava
    end

    def glassfish_timers_domain
      %W(org.realityforge.glassfish.timers#{BuildrPlus::Db.pgsql? ? '.pg' : ''}:glassfish-timers-domain:json:#{glassfish_timers_version})
    end

    def glassfish_timers_db
      %W(org.realityforge.glassfish.timers#{BuildrPlus::Db.pgsql? ? '.pg' : ''}:glassfish-timers-db:jar:#{glassfish_timers_version})
    end

    def glassfish_timers_version
      8 == BuildrPlus::Java.version ? '0.7' : '0.8'
    end

    def slf4j
      %w(org.slf4j:slf4j-api:jar:1.7.25 org.slf4j:slf4j-jdk14:jar:1.7.25)
    end

    def json_schema_validator
      %w(
          com.ethlo.time:itu:jar:1.10.2
          com.networknt:json-schema-validator:jar:1.5.0
          org.jruby.joni:joni:jar:2.2.1
          org.jruby.jcodings:jcodings:jar:1.0.46
      ) + self.jackson_dataformat_yaml + self.slf4j
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
