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

# Enable this feature if the code is tested using jenkins
BuildrPlus::FeatureManager.feature(:jenkins) do |f|
  f.enhance(:Config) do
    attr_writer :auto_deploy

    def auto_deploy?
      @auto_deploy.nil? ? (BuildrPlus::Artifacts.war? || (BuildrPlus::Artifacts.db? && !BuildrPlus::Dbt.library?)) : !!@auto_deploy
    end

    attr_writer :auto_zim

    def auto_zim?
      @auto_zim.nil? ? (BuildrPlus::Artifacts.model? || BuildrPlus::Dbt.library? || BuildrPlus::Artifacts.gwt? || BuildrPlus::Artifacts.replicant_client? || BuildrPlus::Artifacts.replicant_ee_client? || BuildrPlus::Artifacts.db? || BuildrPlus::Artifacts.war?) : !!@auto_zim
    end

    attr_writer :deployment_environment

    def deployment_environment
      @deployment_environment || 'development'
    end

    attr_writer :manual_configuration

    def manual_configuration?
      !!@manual_configuration
    end

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

    def skip_stage?(stage)
      skip_stage_list.include?(stage)
    end

    def skip_stage!(stage)
      skip_stage_list << stage
    end

    def skip_stages
      skip_stage_list.dup
    end

    def add_ci_task(key, label, task, options = {})
      additional_tasks[".jenkins/#{key}.groovy"] = buildr_task_content(label, task, options)
    end

    def add_pre_package_buildr_stage(label, buildr_task, options = {})
      pre_package_stages[label] = buildr_stage_content(buildr_task, options)
    end

    def add_post_package_buildr_stage(label, buildr_task, options = {})
      post_package_stages[label] = buildr_stage_content(buildr_task, options)
    end

    def add_post_import_buildr_stage(label, buildr_task, options = {})
      post_import_stages[label] = buildr_stage_content(buildr_task, options)
    end

    private

    def buildr_stage_content(buildr_task, options = {})
      docker = options[:docker].nil? ? true : !!options[:docker]
      suffix = options[:additional_steps].nil? ? '' : "\n  #{options[:additional_steps]}"
      "  sh '#{docker ? docker_setup : ''}#{buildr_command(buildr_task, options)}'#{suffix}"
    end


    def skip_stage_list
      @skip_stages ||= []
    end

    def pre_package_stages
      @pre_package_stages ||= {}
    end

    def post_package_stages
      @post_package_stages ||= {}
    end

    def post_import_stages
      @post_import_stages ||= {}
    end

    def additional_tasks
      @additional_scripts ||= {}
    end

    def standard_build_scripts
      scripts =
        {
          'Jenkinsfile' => jenkinsfile_content,
          '.jenkins/main.groovy' => main_content(Buildr.projects[0].root_project),
        }
      scripts['.jenkins/publish.groovy'] = publish_content(self.publish_task_type == :oss) unless self.publish_task_type == :none
      scripts.merge!(additional_tasks)
      scripts
    end

    def publish_content(oss)
      pre_script = <<PRE
export DOWNLOAD_REPO=${env.UPLOAD_REPO}
export UPLOAD_REPO=${env.EXTERNAL_#{oss ? 'OSS_' : ''}UPLOAD_REPO}
export UPLOAD_USER=${env.EXTERNAL_#{oss ? 'OSS_' : ''}UPLOAD_USER}
export UPLOAD_PASSWORD=${env.EXTERNAL_#{oss ? 'OSS_' : ''}UPLOAD_PASSWORD}
export PUBLISH_VERSION=${PUBLISH_VERSION}
PRE
      buildr_task_content('Publish', 'ci:publish', :pre_script => pre_script, :xvfb => false, :docker => false)
    end

    def buildr_task_content(label, task, options = {})
      pre_script = options[:pre_script]
      quote = pre_script.to_s.include?("\n") ? '"""' : '"'
      separator = pre_script.to_s != '' && !(pre_script.to_s =~ /\n$/) ? ';' : ''

      artifacts = options[:artifacts].nil? ? false : !!options[:artifacts]
      docker = options[:docker].nil? ? false : !!options[:docker]
      content = <<CONTENT
#{prepare_content(artifacts)}
  stage('#{label}') {
  sh #{quote}#{pre_script}#{separator}#{docker ? docker_setup : ''}#{buildr_command(task, options)}#{quote}
  }
CONTENT
      inner_content = inside_docker_image(content)
      email = options[:email].nil? ? true : !!options[:email]
      outer_content = email ? inside_try_catch(inner_content, standard_exception_handling, false) : inner_content
      hash_bang(inside_node(outer_content))
    end

    def jenkinsfile_content
      hash_bang(inside_node(<<CONTENT))
  checkout scm
  if (env.BRANCH_NAME ==~ /^AM_.*/) {
    env.LOCAL_GIT_COMMIT = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
    env.LOCAL_MASTER_GIT_COMMIT = sh(script: 'git show-ref --hash refs/remotes/origin/master', returnStdout: true).trim()
    echo "Automerge branch ${env.BRANCH_NAME} detected. Merging master."
    sh("git config --global user.email \\"${env.BUILD_NOTIFICATION_EMAIL}\\"")
    sh('git config --global user.name "Build Tool"')
    sh('git merge origin/master')
  }
  load '.jenkins/main.groovy'
CONTENT
    end

    def prepare_content(include_artifacts)
      stage('Prepare') do
        content = <<-CONTENT
  env.BUILD_NUMBER = "${env.BUILD_NUMBER}"
  env.GEM_HOME = '/home/buildbot/.gems'
  env.GEM_PATH = '/home/buildbot/.gems'
  env.PATH = "#{is_old_jruby? ? '' : '/home/buildbot/.gems/bin:'}/home/buildbot/.rbenv/bin:/home/buildbot/.rbenv/shims:${sh(script: 'echo $PATH', returnStdout: true).trim()}"
  sh 'git reset --hard'
  sh 'git clean -ffdx'
  env.PRODUCT_VERSION = sh(script: 'echo $BUILD_NUMBER-`git rev-parse --short HEAD`', returnStdout: true).trim()
  sh 'echo "gem: --no-ri --no-rdoc" > ~/.gemrc'
        CONTENT
        if is_old_jruby?
          content += <<-CONTENT
  retry(8) { sh 'rbenv exec gem install jruby-openssl --version 0.8.2; rbenv rehash' }
  retry(8) { sh 'rbenv exec gem install bundler --version 1.3.1; rbenv rehash' }
          CONTENT
        else
          content += <<-CONTENT
  retry(8) { sh 'gem install bundler; rbenv rehash' }
          CONTENT
        end
        content += <<CONTENT
  retry(8) { sh '#{is_old_jruby? ? 'rbenv exec ' : ''}bundle install --deployment; rbenv rehash' }
CONTENT
        if include_artifacts
          content += <<CONTENT
  retry(8) { sh '#{is_old_jruby? ? 'rbenv exec ' : ''}bundle exec buildr artifacts' }
CONTENT
        end
        content
      end
    end

    def main_content(root_project)
      content = prepare_content(true)

      content += commit_stage(root_project)

      pre_package_stages.each do |label, stage_content|
        content += stage(label) do
          stage_content
        end
      end

      content += package_stage

      if BuildrPlus::FeatureManager.activated?(:db) && BuildrPlus::Db.is_multi_database_project?
        content += package_pg_stage
      end

      post_package_stages.each do |label, stage_content|
        content += stage(label) do
          stage_content
        end
      end

      if BuildrPlus::FeatureManager.activated?(:dbt) &&
        !BuildrPlus::Dbt.library? &&
        ::Dbt.database_for_key?(:default) &&
        BuildrPlus::Dbt.database_import?(:default)
        content += import_stage
      end

      post_import_stages.each do |label, stage_content|
        content += stage(label) do
          stage_content
        end
      end

      if BuildrPlus::Jenkins.auto_deploy?
        content += deploy_stage(root_project)
      end

      if BuildrPlus::Jenkins.auto_zim?
        content += zim_stage(root_project)
      end

      docker_content = inside_docker_image(content)

      docker_content += <<CONTENT
  if (env.BRANCH_NAME ==~ /^AM_.*/ && currentBuild.result == 'SUCCESS') {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'stock-hudson', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
      sh "echo \\"machine github.com login ${GIT_USERNAME} password ${GIT_PASSWORD}\\" > ~/.netrc"
      sh("git fetch --prune")
      env.LATEST_REMOTE_MASTER_GIT_COMMIT = sh(script: 'git show-ref --hash refs/remotes/origin/master', returnStdout: true).trim()
      env.LATEST_REMOTE_GIT_COMMIT = sh(script: "git show-ref --hash refs/remotes/origin/${env.BRANCH_NAME}", returnStdout: true).trim()
      if (env.LOCAL_MASTER_GIT_COMMIT != env.LATEST_REMOTE_MASTER_GIT_COMMIT) {
        if (env.LOCAL_GIT_COMMIT == env.LATEST_REMOTE_GIT_COMMIT)
        {
          echo('Merging changes from master to kick off another build cycle.')
          sh('git merge origin/master')
          echo('Changes merged.')
          sh("git push origin HEAD:${env.BRANCH_NAME}")
          sh("git checkout ${env.LOCAL_GIT_COMMIT}")
        }
      } else {
        echo "Pushing automerge branch ${env.BRANCH_NAME}."
        sh("git push origin HEAD:master")
        if (env.LOCAL_GIT_COMMIT == env.LATEST_REMOTE_GIT_COMMIT) {
          sh("git push origin :${env.BRANCH_NAME}")
        }
      }
    }
  }
CONTENT
      hash_bang(inside_try_catch(docker_content, standard_exception_handling, true))
    end

    def deploy_stage(root_project)
      content = stage('Deploy') do
        "  build job: '#{root_project.name}/deploy-to-#{deployment_environment}', parameters: [string(name: 'PRODUCT_ENVIRONMENT', value: '#{deployment_environment}'), string(name: 'PRODUCT_NAME', value: '#{root_project.name}'), string(name: 'PRODUCT_VERSION', value: \"${env.PRODUCT_VERSION}\")], wait: false"
      end
      <<-DEPLOY_STEP
if (env.BRANCH_NAME == 'master' && currentBuild.result == 'SUCCESS') {
#{content}
}
      DEPLOY_STEP
    end

    def zim_stage(root_project)
      dependencies = []
      root_project.projects.each do |p|
        p.packages.each do |pkg|
          spec = pkg.to_hash
          group = spec[:group].to_s.gsub(/\.pg$/,'')
          if BuildrPlus::Db.pg_defined?
            dependencies << "#{group}.pg:#{spec[:id]}:#{spec[:type]}"
          end
          if BuildrPlus::Db.tiny_tds_defined?
            dependencies << "#{group}:#{spec[:id]}:#{spec[:type]}"
          end
          if !BuildrPlus::Db.pg_defined? && !BuildrPlus::Db.tiny_tds_defined?
            dependencies << "#{group}:#{spec[:id]}:#{spec[:type]}"
          end
        end
      end

      dependencies = dependencies.sort.uniq.join(',')

      content = stage('zim') do
        "  build job: 'zim/upgrade_dependency', parameters: [string(name: 'DEPENDENCIES', value: '#{dependencies}'), string(name: 'VERSION', value: \"${env.PRODUCT_VERSION}\")], wait: false"
      end
      <<-ZIM_STEP
if (env.BRANCH_NAME == 'master' && currentBuild.result == 'SUCCESS') {
#{content}
}
      ZIM_STEP
    end

    def commit_stage(root_project)
      stage('Commit') do
        stage = "  sh \"#{docker_setup}#{buildr_command('ci:commit')}\"\n"

        analysis = false
        if BuildrPlus::FeatureManager.activated?(:checkstyle)
          analysis = true
          stage += <<CONTENT
  step([$class: 'hudson.plugins.checkstyle.CheckStylePublisher', pattern: 'reports/#{root_project.name}/checkstyle/checkstyle.xml', unstableTotalAll: '1', failedTotalAll: '1'])
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/checkstyle', reportFiles: 'checkstyle.html', reportName: 'Checkstyle issues'])
CONTENT
        end
        if BuildrPlus::FeatureManager.activated?(:findbugs)
          analysis = true
          stage += <<CONTENT
  step([$class: 'FindBugsPublisher', pattern: 'reports/#{root_project.name}/findbugs/findbugs.xml', unstableTotalAll: '1', failedTotalAll: '1', isRankActivated: true, canComputeNew: true, shouldDetectModules: false, useDeltaValues: false, canRunOnFailed: false, thresholdLimit: 'low'])
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/findbugs', reportFiles: 'findbugs.html', reportName: 'Findbugs issues'])
CONTENT
        end
        if BuildrPlus::FeatureManager.activated?(:pmd)
          analysis = true
          stage += <<CONTENT
  step([$class: 'PmdPublisher', pattern: 'reports/#{root_project.name}/pmd/pmd.xml', unstableTotalAll: '1', failedTotalAll: '1'])
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/pmd/', reportFiles: 'pmd.html', reportName: 'PMD Issues'])
CONTENT
        end
        if BuildrPlus::FeatureManager.activated?(:jdepend)
          analysis = true
          stage += <<CONTENT
  publishHTML(target: [allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'reports/#{root_project.name}/jdepend', reportFiles: 'jdepend.html', reportName: 'JDepend Report'])
CONTENT
        end
        if analysis
          stage += <<CONTENT
  step([$class: 'AnalysisPublisher', unstableTotalAll: '1', failedTotalAll: '1'])
CONTENT
        end

          stage += <<CONTENT
  if ( currentBuild.result != 'SUCCESS' ) {
    error("Build failed commit stage")
  }
CONTENT

        stage
      end
    end

    def import_stage
      stage('DB Import') do
        "  sh \"#{docker_setup}#{buildr_command('ci:import')}\"\n"
      end
    end

    def import_variant_stage(import_variant)
      stage("DB #{import_variant} Import") do
        "  sh \"#{docker_setup}#{buildr_command("ci:import:#{import_variant}")}\"\n"
      end
    end

    def package_pg_stage
      stage('Package Pg') do
        "  sh \"#{docker_setup}#{buildr_command('clean')}; export DB_TYPE=pg; #{buildr_command('ci:package_no_test')}\"\n"
      end
    end

    def package_stage
      stage('Package') do
        stage = "  sh \"#{is_old_jruby? ? 'TZ=Australia/Melbourne ' : ''}#{docker_setup}#{buildr_command('ci:package')}\"\n"
        if BuildrPlus::FeatureManager.activated?(:rails)
          stage += <<CONTENT
  step([$class: 'JUnitResultArchiver', testResults: 'reports/**/TEST-*.xml'])
CONTENT
        end
        if BuildrPlus::FeatureManager.activated?(:testng)
          stage += <<CONTENT
  step([$class: 'hudson.plugins.testng.Publisher', reportFilenamePattern: 'reports/*/testng/testng-results.xml', failureOnFailedTestConfig: true, unstableFails: 0, unstableSkips: 0])
CONTENT
        end
        stage
      end
    end

    def docker_setup
      BuildrPlus::FeatureManager.activated?(:docker) ? 'export DOCKER_HOST=${env.DOCKER_HOST}; export DOCKER_TLS_VERIFY=${env.DOCKER_TLS_VERIFY}; ' : ''
    end

    def stage(name)
      return '' if skip_stage?(name)
      <<CONTENT
  stage('#{name}'){
#{yield}
  }
CONTENT
    end

    def buildr_command(args, options = {})
      xvfb = options[:xvfb].nil? ? true : !!options[:xvfb]
      "#{xvfb ? 'xvfb-run -a ' : ''}#{bundle_command("buildr #{args}")}"
    end

    def bundle_command(command)
      rbenv_command("bundle exec #{command}")
    end

    def rbenv_command(command)
      "#{is_old_jruby? ? 'rbenv exec ' : ''}#{command}"
    end

    def inside_node(content)
      <<CONTENT
timestamps {
node {
#{content}
}
}
CONTENT
    end

    def inside_try_catch(content, handler_content, update_status)
      <<CONTENT
def err = null

try {

currentBuild.result = 'SUCCESS'
#{update_status ? "step([$class: 'GitHubSetCommitStatusBuilder'])" : ''}

#{content}
} catch (exception) {
   currentBuild.result = "FAILURE"
   err = exception;
} finally {
#{update_status ? "  step([$class: 'GitHubCommitNotifier', resultOnFailure: 'FAILURE'])" : ''}
#{handler_content}
   if (err) {
     throw err
   }
}
CONTENT
    end

    def is_old_jruby?
      BuildrPlus::Ruby.ruby_version =~ /jruby/
    end

    def standard_exception_handling
      <<CONTENT
  if (currentBuild.result == 'SUCCESS' && currentBuild.rawBuild.previousBuild != null && currentBuild.rawBuild.previousBuild.result.toString() != 'SUCCESS') {
    echo "Emailing SUCCESS notification to ${env.BUILD_NOTIFICATION_EMAIL}"

    emailext body: "<p>Check console output at <a href=\\"${env.BUILD_URL}\\">${env.BUILD_URL}</a> to view the results.</p>",
             mimeType: 'text/html',
             replyTo: "${env.BUILD_NOTIFICATION_EMAIL}",
             subject: "\\ud83d\\udc4d ${env.JOB_NAME.replaceAll('%2F','/')} - \#${env.BUILD_NUMBER} - SUCCESS",
             to: "${env.BUILD_NOTIFICATION_EMAIL}"
  }

  if (currentBuild.result != 'SUCCESS') {
    emailBody = """
<title>${env.JOB_NAME.replaceAll('%2F','/')} - \#${env.BUILD_NUMBER} - ${currentBuild.result}</title>
<BODY>
    <div style="font:normal normal 100% Georgia, Serif; background: #ffffff; border: dotted 1px #666; margin: 2px; content: 2px; padding: 2px;">
      <table style="width: 100%">
        <tr style="background-color:#f0f0f0;">
          <th colspan=2 valign="center"><b style="font-size: 200%;">BUILD ${currentBuild.result}</b></th>
        </tr>
        <tr>
          <th align="right"><b>Build URL</b></th>
          <td>
            <a href="${env.BUILD_URL}">${env.BUILD_URL}</a>
          </td>
        </tr>
        <tr>
          <th align="right"><b>Job</b></th>
          <td>${env.JOB_NAME.replaceAll('%2F','/')}</td>
        </tr>
        <tr>
          <td align="right"><b>Build Number</b></td>
          <td>${env.BUILD_NUMBER}</td>
        </tr>
        <tr>
          <td align="right"><b>Branch</b></td>
          <td>${env.BRANCH_NAME}</td>
        </tr>
 """
    if (null != env.CHANGE_ID) {
      emailBody += """
       <tr>
          <td align="right"><b>Change</b></td>
          <td><a href="${env.CHANGE_URL}">${env.CHANGE_ID} - ${env.CHANGE_TITLE}</a></td>
        </tr>
"""
        }

        emailBody += """
      </table>
    </div>

    <div style="background: lightyellow; border: dotted 1px #666; margin: 2px; content: 2px; padding: 2px;">
"""
    for (String line : currentBuild.rawBuild.getLog(1000)) {
      emailBody += "${line}<br/>"
    }
    emailBody += """
    </div>
</BODY>
"""
    echo "Emailing FAILED notification to ${env.BUILD_NOTIFICATION_EMAIL}"
    emailext body: emailBody,
             mimeType: 'text/html',
             replyTo: "${env.BUILD_NOTIFICATION_EMAIL}",
             subject: "\\ud83d\\udca3 ${env.JOB_NAME.replaceAll('%2F','/')} - \#${env.BUILD_NUMBER} - FAILED",
             to: "${env.BUILD_NOTIFICATION_EMAIL}"
  }
CONTENT
    end

    def hash_bang(content)
      "#!/usr/bin/env groovy\n/* DO NOT EDIT: File is auto-generated */\n\n#{content}"
    end

    def inside_docker_image(content)
      java_version = BuildrPlus::Java.version == 7 ? 'java-7.80.15' : 'java-8.92.14'
      ruby_version = "#{BuildrPlus::Ruby.ruby_version =~ /jruby/ ? '' : 'ruby-'}#{BuildrPlus::Ruby.ruby_version}"

      c = content
      if BuildrPlus::FeatureManager.activated?(:docker)
        c = <<CONTENT
docker.withServer("${env.DOCKER_HOST}", 'docker') {
#{content}}
CONTENT
      end

      result = <<CONTENT
docker.image('stocksoftware/build:#{java_version}_#{ruby_version}').inside("--name '${env.JOB_NAME.replaceAll(/[\\\\/-]/, '_').replaceAll('%2F','_')}_${env.BUILD_NUMBER}'") {
#{c}}
CONTENT
      result
    end
  end
  f.enhance(:ProjectExtension) do
    task 'jenkins:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      if BuildrPlus::FeatureManager.activated?(:jenkins)
        unless BuildrPlus::Jenkins.manual_configuration?
          existing = File.exist?("#{base_directory}/.jenkins") ? Dir["#{base_directory}/.jenkins/*.groovy"] : []
          BuildrPlus::Jenkins.jenkins_build_scripts.each_pair do |filename, content|
            full_filename = "#{base_directory}/#{filename}"
            existing.delete(full_filename)
            if content.nil?
              if File.exist?(full_filename)
                raise "The jenkins configuration file #{full_filename} exists when not expected. Please run \"buildr jenkins:fix\" and commit changes."
              end
            else
              if !File.exist?(full_filename) || IO.read(full_filename) != content
                raise "The jenkins configuration file #{full_filename} does not exist or is not up to date. Please run \"buildr jenkins:fix\" and commit changes."
              end
            end
          end
          unless existing.empty?
            raise "The following jenkins configuration file(s) exist but are not expected. Please run \"buildr jenkins:fix\" and commit changes.\n#{existing.collect { |e| "\t* #{e}" }.join("\n")}"
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

    desc 'Recreate the Jenkinsfile and associated groovy scripts'
    task 'jenkins:fix' do
      if BuildrPlus::FeatureManager.activated?(:jenkins) && !BuildrPlus::Jenkins.manual_configuration?
        base_directory = File.dirname(Buildr.application.buildfile.to_s)
        existing = File.exist?("#{base_directory}/.jenkins") ? Dir["#{base_directory}/.jenkins/*.groovy"] : []
        BuildrPlus::Jenkins.jenkins_build_scripts.each_pair do |filename, content|
          full_filename = "#{base_directory}/#{filename}"
          existing.delete(full_filename)
          if content.nil?
            FileUtils.rm_f full_filename
          else
            FileUtils.mkdir_p File.dirname(full_filename)
            File.open(full_filename, 'wb') do |file|
              file.write content
            end
          end
        end
        existing.each do |filename|
          FileUtils.rm_f filename
        end
      end
    end
  end
end
