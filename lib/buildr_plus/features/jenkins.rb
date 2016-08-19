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
    def jenkins_content(root_project)
      docker_active = BuildrPlus::FeatureManager.activated?(:docker)

      java_version = BuildrPlus::Java.version == 7 ? 'java-7.80.15' : 'java-8.92.14'
      ruby_version = "#{BuildrPlus::Ruby.ruby_version =~ /jruby/ ? '' : 'ruby-'}#{BuildrPlus::Ruby.ruby_version}"

      content = <<CONTENT
node {
  docker.image('stocksoftware/build:#{java_version}_#{ruby_version}').
      inside {

        stage 'Prepare'
        checkout scm
        retry(8) {
          sh """
#{standard_command_env}
gem install bundler
"""
        }
        retry(8) {
          sh """
#{standard_command_env}
bundle install --deployment
"""
        }
        retry(8) {
          sh """
#{standard_command_env}
xvfb-run -a bundle exec buildr artifacts
"""
        }

        stage 'Commit'
          sh """
#{standard_command_env}
xvfb-run -a bundle exec buildr ci:commit
"""
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
          sh """
#{standard_command_env}
xvfb-run -a bundle exec buildr ci:package
"""
CONTENT
      if BuildrPlus::FeatureManager.activated?(:testng)
        content += <<CONTENT

        step([$class: 'hudson.plugins.testng.Publisher', reportFilenamePattern: 'reports/*/testng/testng-results.xml'])
CONTENT
      end

      if BuildrPlus::FeatureManager.activated?(:dbt)
        content += <<CONTENT

        stage 'DB Import'
          sh """
#{standard_command_env}
xvfb-run -a bundle exec buildr ci:import
"""
CONTENT
        #TODO: Collect tests for iris that runs tests after import
        if BuildrPlus::FeatureManager.activated?(:testng) && false
          content += <<CONTENT

        step([$class: 'hudson.plugins.testng.Publisher', reportFilenamePattern: 'reports/*/testng/testng-results.xml'])
CONTENT
        end

        BuildrPlus::Ci.additional_import_tasks.each do |import_variant|
          # ci:import:#{import_variant}
        content += <<CONTENT

        stage 'DB #{import_variant} Import'
          sh """
#{standard_command_env}
xvfb-run -a bundle exec buildr ci:#{import_variant}
"""
CONTENT
        end
      end

      content += <<CONTENT
      }
}
CONTENT

      content
    end

    private

    def standard_command_env
      <<-SH
export GEM_HOME=`pwd`/.gems;
export GEM_PATH=`pwd`/.gems;
export M2_REPO=`pwd`/.repo;
export PATH=\\${PATH}:\\${GEM_PATH}/bin;
export DOCKER_TLS_VERIFY=${env.DOCKER_TLS_VERIFY};
export DOCKER_HOST=${env.DOCKER_HOST}
export DOCKER_CERT_PATH=${env.DOCKER_CERT_PATH}
export PRODUCT_VERSION=${env.BUILD_NUMBER}-`git rev-parse --short HEAD`
      SH
    end
  end
  f.enhance(:ProjectExtension) do
    task 'jenkins:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/Jenkinsfile"
      if !File.exist?(filename) || IO.read(filename) != BuildrPlus::Jenkins.jenkins_content(Buildr.projects[0].root_project)
        raise 'The Jenkinsfile configuration file does not exist or is not up to date. Please run "buildr jenkins:fix" and commit changes.'
      end
    end

    task 'jenkins:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/Jenkinsfile"
      File.open(filename, 'wb') do |file|
        file.write BuildrPlus::Jenkins.jenkins_content(Buildr.projects[0].root_project)
      end
    end
  end
end
