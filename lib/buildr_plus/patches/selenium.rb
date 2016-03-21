# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements. See the NOTICE file distributed with this
# work for additional information regarding copyright ownership. The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

module Buildr #nodoc
  module Selenium #nodoc
    class << self

      # Return the set of dependencies required to run selenium tests
      def dependencies
        %w{
          cglib:cglib-nodep:jar:2.1_3
          com.google.guava:guava:jar:15.0
          commons-codec:commons-codec:jar:1.6
          commons-io:commons-io:jar:2.2
          commons-logging:commons-logging:jar:1.1.3
          net.java.dev.jna:jna:jar:3.4.0
          net.java.dev.jna:platform:jar:3.4.0
          org.apache.commons:commons-exec:jar:1.1
          org.apache.httpcomponents:httpclient:jar:4.3
          org.apache.httpcomponents:httpcore:jar:4.3
          org.json:json:jar:20080701
          org.seleniumhq.selenium:selenium-api:jar:2.37.1
          org.seleniumhq.selenium:selenium-chrome-driver:jar:2.37.1
          org.seleniumhq.selenium:selenium-firefox-driver:jar:2.37.1
          org.seleniumhq.selenium:selenium-remote-driver:jar:2.37.1
          org.seleniumhq.selenium:selenium-support:jar:2.37.1
          com.github.detro.ghostdriver:phantomjsdriver:jar:1.0.1
        }
      end

      # the version of the chrome driver
      def chrome_driver_version
        '2.7'
      end

      def configure_chromium_driver(project)
        variant =
          if Buildr::Util.win_os?
            'win32'
          elsif RbConfig::CONFIG['target_os'] == 'darwin'
            'mac'
          else
            RbConfig::CONFIG['host_cpu'] == 'x86_64' ? 'linux64' : 'linux32'
          end
        target_dir = download_variant(project, variant)
        exe = "#{target_dir}/chromedriver#{Buildr::Util.win_os? ? '.exe' : ''}"
        project.test.enhance([project.file(target_dir)])
        project.test.options[:properties].merge!('webdriver.chrome.driver' => exe)
        project
      end

      # Define a task for downloading the chrome selenium driver into the directory target/chromedriver/<variant>
      # where variant is one of (win, mac, linux32, linux64) that is appropriate to the current platform
      #
      def download_variant(project, variant)
        desc 'Download chromium driver'
        project.task('download_chromium_driver')

        spec = "org.chromium.chromedriver:chromedriver-#{variant}:zip:#{chrome_driver_version}"
        artifact = Buildr.artifact(spec)
        artifact.from(Buildr.download("downloads/chromedriver_#{variant}_#{chrome_driver_version}.zip" =>
                                        "http://chromedriver.storage.googleapis.com/#{chrome_driver_version}/chromedriver_#{variant}.zip"))
        project.task('download_chromium_driver').enhance([artifact])

        target_dir = File.expand_path("target/chromedriver/#{variant}")
        project.file(target_dir) do
          artifact.invoke
          Buildr.unzip(target_dir => artifact)
        end
        project.task('download_chromium_driver').enhance([target_dir])
        target_dir
      end
    end
  end
end
