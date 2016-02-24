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

require 'buildr/checkstyle'

module Buildr::Checkstyle
  class << self
    # The specs for requirements
    def dependencies
      %w(
          com.puppycrawl.tools:checkstyle:jar:6.12.1
          org.antlr:antlr4-runtime:jar:4.5.1-1
          antlr:antlr:jar:2.7.7
          com.google.guava:guava:jar:18.0 org.apache.commons:commons-lang3:jar:3.4
          org.abego.treelayout:org.abego.treelayout.core:jar:1.0.1
          commons-cli:commons-cli:jar:1.3
          commons-beanutils:commons-beanutils-core:jar:1.8.3
          commons-logging:commons-logging:jar:1.1.1
        )
    end

    def checkstyle(configuration_file, format, output_file, source_paths, options = {})
      dependencies = self.dependencies + (options[:dependencies] || [])
      cp = Buildr.artifacts(dependencies).each { |a| a.invoke if a.respond_to?(:invoke) }.map(&:to_s)

      args = []
      if options[:properties_file]
        args << '-p'
        args << options[:properties_file]
      end
      args << '-c'
      args << configuration_file
      args << '-f'
      args << format
      args << '-o'
      args << output_file
      args += source_paths.select { |p| File.exist?(p) }

      begin
        Java::Commands.java 'com.puppycrawl.tools.checkstyle.Main', *(args + [{:classpath => cp, :properties => options[:properties], :java_args => options[:java_args]}])
      rescue Exception => e
        raise e if options[:fail_on_error]
      end
    end
  end
end
