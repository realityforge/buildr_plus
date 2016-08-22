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
    def jenkins_build_scripts
      (@jenkins_build_scripts ||= standard_build_scripts).dup
    end

    def publish_task_type=(publish_task_type)
      raise "Can not set publish task type to #{publish_task_type.inspect} as not one of expected values" unless [:oss, :external, :none].include?(publish_task_type)
      @publish_task_type = publish_task_type
    end

    def publish_task_type
      return @publish_task_type unless @publish_task_type.nil?
      return :oss if BuildrPlus::FeatureManager.activated?(:oss)
      :none
    end

    private

    def standard_build_scripts
      scripts =
        {
          'Jenkinsfile' => jenkinsfile_content,
          '.jenkins/main.groovy' => main_content(Buildr.projects[0].root_project),
        }
      scripts['.jenkins/publish_oss.groovy'] = publish_content(self.publish_task_type == :oss) unless self.publish_task_type == :none
      scripts
    end

    def publish_content(oss)
      pre_script = <<PRE
export DOWNLOAD_REPO=${env.UPLOAD_REPO}
export UPLOAD_REPO=${env.EXTERNAL_#{oss ? 'OSS_' : ''}UPLOAD_REPO}
export UPLOAD_USER=${env.EXTERNAL_#{oss ? 'OSS_' : ''}UPLOAD_USER}
export UPLOAD_PASSWORD=${env.EXTERNAL_#{oss ? 'OSS_' : ''}UPLOAD_PASSWORD}
PRE
      content = <<CONTENT
  stage 'Publish'
  checkout scm
  #{buildr_command('ci:publish', :pre_script => pre_script)}
CONTENT
      inside_node(inside_docker_image(content))
    end

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

      if BuildrPlus::FeatureManager.activated?(:db) && BuildrPlus::Db.is_multi_database_project?
        content += <<CONTENT

  stage 'Package Pg'
  #{buildr_command('ci:package', :pre_script => "export DB_TYPE=pg\nexport TEST=no")}
CONTENT
      end

      if BuildrPlus::FeatureManager.activated?(:dbt) && BuildrPlus::Dbt.database_import?(:default)
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

    def buildr_command(args, options = {})
      shell_command("xvfb-run -a bundle exec buildr #{args}", options)
    end

    def shell_command(command, options = {})
      pre_script = options[:pre_script] ? "#{options[:pre_script]}\n" : ''
      "sh \"\"\"\n#{standard_command_env}\n#{pre_script}#{command}\n\"\"\""
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
        BuildrPlus::Jenkins.jenkins_build_scripts.each_pair do |filename, content|
          full_filename = "#{base_directory}/#{filename}"
          if !File.exist?(full_filename) || IO.read(full_filename) != content
            raise "The jenkins configuration file #{full_filename} does not exist or is not up to date. Please run \"buildr jenkins:fix\" and commit changes."
          end
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

    task 'jenkins:fix' do
      if BuildrPlus::FeatureManager.activated?(:jenkins)
        base_directory = File.dirname(Buildr.application.buildfile.to_s)
        BuildrPlus::Jenkins.jenkins_build_scripts.each_pair do |filename, content|
          full_filename = "#{base_directory}/#{filename}"
          FileUtils.mkdir_p File.dirname(full_filename)
          File.open(full_filename, 'wb') do |file|
            file.write content
          end
        end
      end
    end
  end
end
