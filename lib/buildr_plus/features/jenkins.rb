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
BuildrPlus::FeatureManager.feature(:jenkins => [:kinjen]) do |f|
  f.enhance(:Config) do
    attr_writer :auto_deploy

    def auto_deploy?
      @auto_deploy.nil? ? (BuildrPlus::Artifacts.war? || (BuildrPlus::Artifacts.db? && !BuildrPlus::Dbt.library?)) : !!@auto_deploy
    end

    attr_writer :auto_zim

    def auto_zim?
      @auto_zim.nil? ? BuildrPlus::Artifacts.library? : !!@auto_zim
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
      self.pre_package_stages << buildr_stage_content(label, buildr_task, options)
    end

    def add_post_package_buildr_stage(label, buildr_task, options = {})
      self.post_package_stages << buildr_stage_content(label, buildr_task, options)
    end

    def add_post_import_buildr_stage(label, buildr_task, options = {})
      self.post_import_stages << buildr_stage_content(label, buildr_task, options)
    end

    def pre_package_stages
      @pre_package_stages ||= []
    end

    def post_package_stages
      @post_package_stages ||= []
    end

    def post_import_stages
      @post_import_stages ||= []
    end

    def import_variant_stage(variant)
      return '' if skip_stage?("DB #{variant} Import")
      "        kinjen.import_variant_stage( this, '#{variant}' )\n"
    end

    private

    def buildr_stage_content(label, buildr_task, options = {})
      docker = options[:docker].nil? ? true : !!options[:docker]
      suffix = options[:additional_steps].nil? ? '' : "\n          #{options[:additional_steps]}"

      <<-CONTENT
        stage('#{label}') {
          sh '#{docker ? docker_setup : ''}#{buildr_command(buildr_task, options)}'#{suffix}
        }
      CONTENT
    end

    def skip_stage_list
      @skip_stages ||= []
    end

    def additional_tasks
      @additional_scripts ||= {}
    end

    def standard_build_scripts
      scripts = { 'Jenkinsfile' => jenkinsfile_content }
      scripts['.jenkins/publish.groovy'] = publish_content(self.publish_task_type == :oss) unless self.publish_task_type == :none
      scripts.merge!(additional_tasks)
      scripts
    end

    def publish_content(oss)
      content = "#{prepare_content(:exclude_artifacts => true)}\n        kinjen.publish_stage( this#{oss ? ", 'OSS_'" : ''} )\n"
      task_content(content, :always_run => true)
    end

    def buildr_task_content(label, task, options = {})
      pre_script = options[:pre_script]
      quote = pre_script.to_s.include?("\n") ? '"""' : '"'
      separator = pre_script.to_s != '' && !(pre_script.to_s =~ /\n$/) ? ';' : ''

      artifacts = options[:artifacts].nil? ? false : !!options[:artifacts]
      docker = options[:docker].nil? ? false : !!options[:docker]
      suffix = options[:additional_steps].nil? ? '' : "\n          #{options[:additional_steps]}"
      content = <<CONTENT
#{prepare_content(:exclude_artifacts => !artifacts)}
        stage('#{label}') {
          sh #{quote}#{pre_script}#{separator}#{docker ? docker_setup : ''}#{buildr_command(task, options)}#{quote}#{suffix}
        }
CONTENT

      task_content(content, options)
    end

    def config_git
      "      kinjen.config_git( this )\n"
    end

    def task_content(content, options = {})
      email = options[:email].nil? ? true : !!options[:email]
      always_run = options[:always_run].nil? ? false : !!options[:always_run]
      hash_bang(inside_node(inside_docker_image(config_git + inside_try_catch(content, false, email, false, always_run))))
    end

    def automerge_prelude
      <<CONTENT
      env.AUTO_MERGE_TARGET_BRANCH = kinjen.extract_auto_merge_target( this )
CONTENT
    end

    def automerge_prepare
      <<CONTENT
        if ( '' != env.AUTO_MERGE_TARGET_BRANCH )
        {
          kinjen.prepare_auto_merge( this, env.AUTO_MERGE_TARGET_BRANCH )
        }
CONTENT
    end

    def jenkinsfile_content
      hash_bang(inside_node(<<CONTENT))
#{main_content(Buildr.projects[0].root_project)}
CONTENT
    end

    def prepare_content(options = {})
      params = {}
      params['buildr'] = 'false' if options[:exclude_artifacts]
      params['node'] = 'true' if options[:include_node]
      params['yarn'] = 'false' if options[:include_node] && options[:exclude_yarn]
      "        kinjen.prepare_stage( this#{params.empty? ? '' : ", [#{params.collect{|k,v| "#{k}: #{v}"}.join(', ')}]"} )\n"
    end

    def main_content(root_project)
      content = automerge_prepare

      content += prepare_content(:include_node => BuildrPlus::FeatureManager.activated?(:node),
                                 :exclude_yarn => !BuildrPlus::Node.root_package_json_present?)

      content += commit_stage(root_project)

      pre_package_stages.each do |stage_content|
        content += stage_content
      end

      content += package_stage

      if BuildrPlus::FeatureManager.activated?(:db) && BuildrPlus::Db.is_multi_database_project?
        content += package_pg_stage
      end

      post_package_stages.each do |stage_content|
        content += stage_content
      end

      if BuildrPlus::FeatureManager.activated?(:dbt) &&
        !BuildrPlus::Dbt.library? &&
        ::Dbt.database_for_key?(:default) &&
        BuildrPlus::Dbt.database_import?(:default)
        content += import_stage
      end

      post_import_stages.each do |stage_content|
        content += stage_content
      end

      content = automerge_prelude + inside_try_catch(content, true, true, true, false)

      if BuildrPlus::Jenkins.auto_deploy? || BuildrPlus::Jenkins.auto_zim?
        content += <<-CONTENT
      kinjen.complete_build( this ) {
        CONTENT
      else
        content += <<-CONTENT
      kinjen.complete_build( this )
        CONTENT
      end
      if BuildrPlus::Jenkins.auto_deploy?
        content += deploy_stage(root_project)
      end

      if BuildrPlus::Jenkins.auto_zim?
        content += zim_stage(root_project)
      end
      if BuildrPlus::Jenkins.auto_deploy? || BuildrPlus::Jenkins.auto_zim?
        content += <<-CONTENT
      }
        CONTENT
      end
      inside_docker_image(config_git + content)
    end

    def deploy_stage(root_project)
      <<-DEPLOY_STEP
        kinjen.deploy_stage( this, '#{root_project.name}', '#{deployment_environment}' )
      DEPLOY_STEP
    end

    def zim_stage(root_project)
      return '' if skip_stage?('Zim')
      dependencies = []
      ([root_project] + root_project.projects).each do |p|
        p.packages.each do |pkg|
          spec = pkg.to_hash
          group = spec[:group].to_s.gsub(/\.pg$/, '')
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

      name = root_project.group.to_s.gsub(/\.pg$/, '')

      <<-ZIM_STEP
        kinjen.zim_stage( this, '#{name}', '#{dependencies}' )
      ZIM_STEP
    end

    def commit_stage(root_project)
      return '' if skip_stage?('Commit')
      options = {}
      options[:checkstyle] = true if BuildrPlus::FeatureManager.activated?(:checkstyle)
      options[:findbugs] = true if BuildrPlus::FeatureManager.activated?(:findbugs)
      options[:pmd] = true if BuildrPlus::FeatureManager.activated?(:pmd)
      options[:jdepend] = true if BuildrPlus::FeatureManager.activated?(:jdepend)
      option_string = options.empty? ? '' : ", [#{options.collect { |k, v| "#{k}: #{v}" }.join(', ')}]"
      "        kinjen.commit_stage( this, '#{root_project.name}'#{option_string} )\n"
    end

    def import_stage
      return '' if skip_stage?('DB Import')
      "        kinjen.import_stage( this )\n"
    end

    def package_pg_stage
      return '' if skip_stage?('Pg Package')
      "        kinjen.pg_package_stage( this )\n"
    end

    def package_stage
      return '' if skip_stage?('Package')
      options = {}
      options[:testng] = true if BuildrPlus::FeatureManager.activated?(:findbugs)
      option_string = options.empty? ? '' : ", [#{options.collect { |k, v| "#{k}: #{v}" }.join(', ')}]"
      "        kinjen.package_stage( this#{option_string} )\n"
    end

    def docker_setup
      BuildrPlus::FeatureManager.activated?(:docker) ? 'export DOCKER_HOST=${env.DOCKER_HOST}; export DOCKER_TLS_VERIFY=${env.DOCKER_TLS_VERIFY}; ' : ''
    end

    def buildr_command(args, options = {})
      xvfb = options[:xvfb].nil? ? true : !!options[:xvfb]
      "#{xvfb ? 'xvfb-run -a ' : ''}#{bundle_command("buildr #{args}")}"
    end

    def bundle_command(command)
      "bundle exec #{command}"
    end

    def inside_node(content)
      <<CONTENT
timestamps {
  node {
    checkout scm
    kinjen = load 'vendor/tools/kinjen/lib/kinjen.groovy'
#{content}  }
}
CONTENT
    end

    def inside_try_catch(content, update_status, send_email, auto_merge, always_run)
      options = {}
      options[:notify_github] = false unless update_status
      options[:email] = false unless send_email
      options[:always_run] = true if always_run
      options[:lock_name] = 'env.AUTO_MERGE_TARGET_BRANCH' if auto_merge
      option_string = options.empty? ? '' : ", [#{options.collect { |k, v| "#{k}: #{v}" }.join(', ')}]"
      <<CONTENT
      kinjen.guard_build( this#{option_string} ) {
#{content}      }
CONTENT
    end

    def hash_bang(content)
      "#!/usr/bin/env groovy\n/* DO NOT EDIT: File is auto-generated */\n\n#{content}".gsub(/\n\n/, "\n")
    end

    def inside_docker_image(content)
      c = content
      if BuildrPlus::FeatureManager.activated?(:docker)
        c = <<CONTENT
docker.withServer("${env.DOCKER_HOST}", 'docker') {
#{content}}
CONTENT
      end

      result = <<CONTENT
    kinjen.run_in_container( this, 'stocksoftware/build' ) {
#{c}
    }
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
