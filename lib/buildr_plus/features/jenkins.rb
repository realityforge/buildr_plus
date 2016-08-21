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

# Enable this feature if the code is tested using travis
BuildrPlus::FeatureManager.feature(:jenkins) do |f|
  f.enhance(:Config) do
    def jenkinsfile_content
      inside_node("  checkout scm\n  load '.jenkins/main.groovy'")
    end

    def main_content(root_project)
      content = <<CONTENT
  stage 'Prepare'
  checkout scm
  retry(8) {
    #{shell_command('gem install bundler')}
  }
  retry(8) {
    #{shell_command('bundle install --deployment')}
  }
  retry(8) {
    #{buildr_command('artifacts')}
  }

  stage 'Commit'
  #{buildr_command('ci:commit')}
CONTENT

      if BuildrPlus::FeatureManager.activated?(:checkstyle)
        content += <<CONTENT
  step([$class: 'hudson.plugins.checkstyle.CheckStylePublisher', pattern: 'reports/#{root_project.name}/checkstyle/checkstyle.xml'])
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/checkstyle', reportFiles: 'checkstyle.html', reportName: 'Checkstyle issues'])
CONTENT
      end
      if BuildrPlus::FeatureManager.activated?(:findbugs)
        content += <<CONTENT
  step([$class: 'FindBugsPublisher', pattern: 'reports/#{root_project.name}/findbugs/findbugs.xml', unstableTotalAll: '1', failedTotalAll: '1', isRankActivated: true, canComputeNew: true, shouldDetectModules: false, useDeltaValues: false, canRunOnFailed: false, thresholdLimit: 'low'])
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/findbugs', reportFiles: 'findbugs.html', reportName: 'Findbugs issues'])
CONTENT
      end
      if BuildrPlus::FeatureManager.activated?(:pmd)
        content += <<CONTENT
  step([$class: 'PmdPublisher', pattern: 'reports/#{root_project.name}/pmd/pmd.xml'])
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/pmd/', reportFiles: 'pmd.html', reportName: 'PMD Issues'])
CONTENT
      end
      if BuildrPlus::FeatureManager.activated?(:jdepend)
        content += <<CONTENT
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/jdepend', reportFiles: 'jdepend.html', reportName: 'JDepend Report'])
CONTENT
      end

      content += <<CONTENT

  stage 'Package'
  #{buildr_command('ci:package')}
CONTENT
      if BuildrPlus::FeatureManager.activated?(:testng)
        content += <<CONTENT

  step([$class: 'hudson.plugins.testng.Publisher', reportFilenamePattern: 'reports/*/testng/testng-results.xml'])
CONTENT
      end

      if BuildrPlus::FeatureManager.activated?(:dbt)
        content += <<CONTENT

  stage 'DB Import'
  #{shell_command('xvfb-run -a bundle exec buildr ci:import')}
CONTENT
        #TODO: Collect tests for iris that runs tests after import
        if BuildrPlus::FeatureManager.activated?(:testng) && false
          content += <<CONTENT

  step([$class: 'hudson.plugins.testng.Publisher', reportFilenamePattern: 'reports/*/testng/testng-results.xml'])
CONTENT
        end

        BuildrPlus::Ci.additional_import_tasks.each do |import_variant|
          content += <<CONTENT

  stage 'DB #{import_variant} Import'
  #{buildr_command("ci:import:#{import_variant}")}
CONTENT
        end
      end

      inside_docker_image(content)
    end

    private

    def buildr_command(args)
      shell_command("xvfb-run -a bundle exec buildr #{args}")
    end

    def shell_command(command)
      "sh \"\"\"\n#{standard_command_env}\n#{command}\n\"\"\""
    end

    def inside_node(content)
      <<CONTENT
node {
#{content}
}
CONTENT
    end

    def inside_docker_image(content)
      java_version = BuildrPlus::Java.version == 7 ? 'java-7.80.15' : 'java-8.92.14'
      ruby_version = "#{BuildrPlus::Ruby.ruby_version =~ /jruby/ ? '' : 'ruby-'}#{BuildrPlus::Ruby.ruby_version}"

      <<CONTENT
docker.image('stocksoftware/build:#{java_version}_#{ruby_version}').inside {
#{content}
}
CONTENT
    end

    def standard_command_env
      env = <<-SH
export PRODUCT_VERSION=${env.BUILD_NUMBER}-`git rev-parse --short HEAD`
export GEM_HOME=`pwd`/.gems;
export GEM_PATH=`pwd`/.gems;
export M2_REPO=`pwd`/.repo;
export PATH=\\${PATH}:\\${GEM_PATH}/bin;
      SH
      if BuildrPlus::FeatureManager.activated?(:docker)
        env += <<-SH
export DOCKER_TLS_VERIFY=${env.DOCKER_TLS_VERIFY};
export DOCKER_HOST=${env.DOCKER_HOST}
export DOCKER_CERT_PATH=${env.DOCKER_CERT_PATH}
        SH
      end
      env
    end
  end
  f.enhance(:ProjectExtension) do
    task 'jenkins:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      if BuildrPlus::FeatureManager.activated?(:jenkins)
        filename = "#{base_directory}/Jenkinsfile"
        if !File.exist?(filename) || IO.read(filename) != BuildrPlus::Jenkins.jenkinsfile_content
          raise 'The Jenkinsfile configuration file does not exist or is not up to date. Please run "buildr jenkins:fix" and commit changes.'
        end
        filename = "#{base_directory}/.jenkins/main.groovy"
        if !File.exist?(filename) || IO.read(filename) != BuildrPlus::Jenkins.main_content(Buildr.projects[0].root_project)
          raise 'The .jenkins/main.groovy configuration file does not exist or is not up to date. Please run "buildr jenkins:fix" and commit changes.'
        end
      else
        if File.exist?("#{base_directory}/Jenkinsfile")
          raise 'The Jenkinsfile configuration file exists but the project does not have the jenkins facet enabled.'
        end
        if File.exist?("#{base_directory}/.jenkins")
          raise 'The .jenkins directory exists but the project does not have the jenkins facet enabled.'
        end
      end
    end

    if BuildrPlus::FeatureManager.activated?(:jenkins)
      task 'jenkins:fix' do
        base_directory = File.dirname(Buildr.application.buildfile.to_s)
        filename = "#{base_directory}/Jenkinsfile"
        File.open(filename, 'wb') do |file|
          file.write BuildrPlus::Jenkins.jenkinsfile_content
        end
        filename = "#{base_directory}/.jenkins/main.groovy"
        FileUtils.mkdir_p File.dirname(filename)
        File.open(filename, 'wb') do |file|
          file.write BuildrPlus::Jenkins.main_content(Buildr.projects[0].root_project)
        end
      end
    end
  end
end
