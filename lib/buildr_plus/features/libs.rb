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

    def glassfish_embedded
      %w(fish.payara.extras:payara-embedded-all:jar:5.2022.5) + self.eclipse_persistence_core
    end

    def eclipse_persistence_core
      %w(org.eclipse.persistence:org.eclipse.persistence.core:jar:2.7.11)
    end

    def mockito
      # TODO: hamcrest only seems to be used by AbstractDatabaseTest across systems so we just decouple the dependency
      %w(
        org.mockito:mockito-core:jar:5.2.0
        net.bytebuddy:byte-buddy:jar:1.17.7
        net.bytebuddy:byte-buddy-agent:jar:1.17.7
        org.objenesis:objenesis:jar:3.2
        org.hamcrest:hamcrest:jar:2.2
      )
    end

    def gwt_user
      %w(
        org.gwtproject:gwt-user:jar:2.11.0
        org.w3c.css:sac:jar:1.3
        org.realityforge.javaemul.internal.annotations:javaemul.internal.annotations:jar:0.01
      )
    end

    def gwt_dev
      'org.gwtproject:gwt-dev:jar:2.11.0'
    end

    def testng_version
      '7.4.0'
    end

    def testng
      %W(org.testng:testng:jar:#{testng_version} com.beust:jcommander:jar:1.78 org.webjars:jquery:jar:3.5.1)
    end

    def guiceyloops
      self.mockito +
      self.testng +
        %w(
          org.realityforge.guiceyloops:guiceyloops:jar:0.119
          aopalliance:aopalliance:jar:1.0
          org.ow2.asm:asm:jar:9.2
          com.google.inject:guice:jar:5.1.0
        ) + self.glassfish_embedded
    end

    def glassfish_timers_domain
      %W(org.realityforge.glassfish.timers:glassfish-timers-domain:json:#{glassfish_timers_version})
    end

    def glassfish_timers_db
      %W(org.realityforge.glassfish.timers:glassfish-timers-db:jar:#{glassfish_timers_version})
    end

    def glassfish_timers_version
      8 == BuildrPlus::Java.version ? '0.7' : '0.8'
    end

    def jtds
      %w(net.sourceforge.jtds:jtds:jar:1.3.1)
    end

    def db_drivers
      return self.jtds
    end
  end
end
