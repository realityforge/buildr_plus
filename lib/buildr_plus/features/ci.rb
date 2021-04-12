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

BuildrPlus::FeatureManager.feature(:ci) do |f|
  f.enhance(:Config) do
    def additional_pull_request_actions
      @additional_pull_request_actions ||= []
    end

    attr_writer :additional_pull_request_actions

    def additional_commit_actions
      @additional_commit_actions ||= []
    end

    attr_writer :additional_commit_actions

    def pre_import_actions
      @pre_import_actions ||= []
    end

    attr_writer :pre_import_actions

    def additional_import_actions
      @additional_import_actions ||= []
    end

    attr_writer :additional_import_actions

    def additional_import_tasks
      @additional_import_tasks ||= []
    end

    attr_writer :additional_import_tasks

    attr_writer :perform_publish

    def perform_publish?
      @perform_publish.nil? ? true : !!@perform_publish
    end
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|
      if project.ipr?
        project.task ':ci:common_setup' do
          if ENV['UPLOAD_REPO']
            repo_suffix = ENV['GIT_PROJECT'] && ENV['UPLOAD_REPO'].include?('github') ? '/' + ENV['GIT_PROJECT'] : ''
            Buildr.repositories.release_to[:url] = ENV['UPLOAD_REPO'] + repo_suffix
          end
          Buildr.repositories.release_to[:username] = ENV['UPLOAD_USER']
          Buildr.repositories.release_to[:password] = ENV['UPLOAD_PASSWORD']
          ENV['TEST'] ||= 'all'
          Dbt::Config.environment = 'test' if BuildrPlus::FeatureManager.activated?(:dbt)
          SSRS::Config.environment = 'test' if BuildrPlus::FeatureManager.activated?(:rptman)
          BuildrPlus::Config.environment = 'test' if BuildrPlus::FeatureManager.activated?(:config)
        end

        project.task ':ci:test_configure' do
          if BuildrPlus::FeatureManager.activated?(:dbt)
            BuildrPlus::Config.reload_application_config! if BuildrPlus::FeatureManager.activated?(:config)
            Dbt.repository.load_configuration_data

            Dbt.database_keys.each do |database_key|
              next if BuildrPlus::Dbt.manual_testing_only_database?(database_key)

              prefix = Dbt::Config.default_database?(database_key) ? '' : "#{database_key}."
              jdbc_url = Dbt.configuration_for_key(database_key).build_jdbc_url(:credentials_inline => true)
              catalog_name = Dbt.configuration_for_key(database_key).catalog_name
              Buildr.projects.each do |p|
                p.test.options[:properties].merge!("#{prefix}test.db.url" => jdbc_url)
                p.test.options[:properties].merge!("#{prefix}test.db.name" => catalog_name)
              end
            end
          end
        end

        project.task ':ci:import:setup' => %w(ci:common_setup) do
          Dbt::Config.environment = 'import_test' if BuildrPlus::FeatureManager.activated?(:dbt)
          project.task('ci:test_configure').invoke
        end

        desc 'Setup test environment'
        project.task ':ci:setup' => %w(ci:common_setup) do
          task('ci:test_configure').invoke
        end

        project.task ':ci:no_test_setup' => %w(ci:setup) do
          ENV['TEST'] = 'no'
        end

        if BuildrPlus::FeatureManager.activated?(:dbt)
          import_actions = []
          import_actions << 'ci:import:setup'

          import_actions.concat(BuildrPlus::Ci.pre_import_actions)
          import_actions.concat(%w(dbt:create_by_import dbt:verify_constraints))
          import_actions.concat(BuildrPlus::Ci.additional_import_actions)
          import_actions << 'dbt:drop'

          desc 'Test the import process'
          project.task ':ci:import' => import_actions

          BuildrPlus::Ci.additional_import_tasks.each do |import_variant|
            desc "Test the import #{import_variant} process"
            project.task ":ci:import:#{import_variant}" => %W(ci:import:setup dbt:create_by_import:#{import_variant} dbt:verify_constraints dbt:drop)
          end
        end

        desc 'Publish artifacts to repository'
        project.task ':ci:publish' => %w(ci:setup publish)

        desc 'Publish artifacts to repository'
        project.task ':ci:upload' => %w(ci:setup upload_published)

        commit_actions = %w(ci:no_test_setup)
        pull_request_actions = %w(ci:setup)
        package_actions = %w(ci:setup)
        package_no_test_actions = %w(ci:no_test_setup)

        if BuildrPlus::FeatureManager.activated?(:checks)
          commit_actions << 'checks:check'
          pull_request_actions << 'checks:check'
        end

        if BuildrPlus::FeatureManager.activated?(:redfish) && BuildrPlus::FeatureManager.activated?(:docker)
          Redfish.domains.each do |domain|
            next unless domain.enable_rake_integration?
            next unless domain.dockerize?
            taskname = "#{domain.task_prefix}:docker:rm_all"
            pull_request_actions << taskname
            package_actions << taskname
            package_no_test_actions << taskname
          end
        end

        if BuildrPlus::FeatureManager.activated?(:domgen)
          commit_actions << 'domgen:all'
          pull_request_actions << 'domgen:all'
          package_actions << 'domgen:all'
          package_no_test_actions << 'domgen:all'
        end

        database_drops = []

        if BuildrPlus::FeatureManager.activated?(:dbt)
          Dbt.database_keys.each do |database_key|
            database = Dbt.database_for_key(database_key)
            next unless database.enable_rake_integration? || database.packaged? || database.managed?
            next if BuildrPlus::Dbt.manual_testing_only_database?(database_key)

            prefix = Dbt::Config.default_database?(database_key) ? '' : ":#{database_key}"

            module_group = BuildrPlus::Dbt.non_standalone_database_module_groups[database.key]

            create = "dbt#{prefix}:#{module_group ? "#{database.packaged? ? '' : "#{module_group}:"}up#{!database.packaged? ? '' : ":#{module_group}"}" : 'create'}"
            drop = "dbt#{prefix}:#{module_group ? "#{database.packaged? ? '' : "#{module_group}:"}down#{!database.packaged? ? '' : ":#{module_group}"}" : 'drop'}"

            commit_actions << create
            pull_request_actions << create
            package_actions << create
            database_drops << drop

            database.datasets.each do |dataset_name|
              desc "Test the create_with_dataset:#{dataset_name} process"
              project.task ":ci:create_with_dataset:#{dataset_name}" => %W(ci:common_setup dbt:create_with_dataset:#{dataset_name} dbt:verify_constraints dbt:drop)

              if BuildrPlus::FeatureManager.activated?(:jenkins)
                BuildrPlus::Jenkins.add_pre_package_buildr_stage("Dataset #{dataset_name}", "ci:create_with_dataset:#{dataset_name}")
              end
            end
          end
        end

        if BuildrPlus::FeatureManager.activated?(:rptman) && ENV['RPTMAN'] != 'no'
          commit_actions << 'rptman:ssrs:upload'
          pull_request_actions << 'rptman:ssrs:upload'
        end

        if BuildrPlus::FeatureManager.activated?(:keycloak)
          package_actions << 'keycloak:create'
        end

        project.task ':ci:source_code_analysis'

        commit_actions << 'ci:source_code_analysis'
        commit_actions.concat(BuildrPlus::Ci.additional_commit_actions)

        pull_request_actions << 'ci:source_code_analysis'

        package_actions << 'test'
        pull_request_actions << 'test'
        package_no_test_actions << 'test'

        package_actions << 'package'
        pull_request_actions << 'package'
        package_no_test_actions << 'package'

        pull_request_actions.concat(BuildrPlus::Ci.additional_pull_request_actions)

        if BuildrPlus::FeatureManager.activated?(:redfish) && BuildrPlus::FeatureManager.activated?(:docker)
          if BuildrPlus::FeatureManager.activated?(:jms)
            package_actions << 'openmq:start'
          end

          Redfish.domains.each do |domain|
            next unless domain.enable_rake_integration?
            next unless domain.dockerize?
            taskname = "#{domain.task_prefix}:docker:build"
            pull_request_actions << taskname
            package_actions << taskname
            package_no_test_actions << taskname
          end

          if BuildrPlus::FeatureManager.activated?(:jms)
            package_actions << 'openmq:stop'
          end
        end

        if BuildrPlus::FeatureManager.activated?(:keycloak)
          package_actions << 'keycloak:destroy'
        end

        if BuildrPlus::FeatureManager.activated?(:rptman) && ENV['RPTMAN'] != 'no'
          commit_actions << 'rptman:ssrs:delete'
          pull_request_actions << 'rptman:ssrs:delete'
        end

        database_drops = database_drops.reverse

        commit_actions.concat(database_drops)
        pull_request_actions.concat(database_drops)
        package_actions.concat(database_drops)

        if BuildrPlus::Ci.perform_publish?
          package_actions << 'ci:upload'
          package_no_test_actions << 'ci:upload'
        end

        if BuildrPlus::FeatureManager.activated?(:redfish) && BuildrPlus::FeatureManager.activated?(:docker)
          Redfish.domains.each do |domain|
            next unless domain.enable_rake_integration?
            next unless domain.dockerize?
            taskname = "#{domain.task_prefix}:docker:rm"
            pull_request_actions << taskname
            package_actions << taskname
            package_no_test_actions << taskname
          end
        end

        desc 'Perform pre-commit checks and source code analysis'
        project.task ':ci:commit' => commit_actions

        desc 'Perform pre-merge checks for pull requests'
        project.task ':ci:pull_request' => pull_request_actions

        desc 'Build the package(s) and run tests'
        project.task ':ci:package' => package_actions

        desc 'Build the package(s) but do not run tests'
        project.task ':ci:package_no_test' => package_no_test_actions
      end

      project.task(':ci:source_code_analysis') do
        if project.respond_to?(:spotbugs) && project.spotbugs.enabled?
          task("#{project.name}:spotbugs:xml").invoke
          task("#{project.name}:spotbugs:html").invoke
        end
        if project.respond_to?(:pmd) && project.pmd.enabled?
          task("#{project.name}:pmd:html").invoke
          task("#{project.name}:pmd:xml").invoke
        end
        if project.respond_to?(:checkstyle) && project.checkstyle.enabled?
          task("#{project.name}:checkstyle:xml").invoke
          task("#{project.name}:checkstyle:html").invoke
        end
      end
    end
  end
end
