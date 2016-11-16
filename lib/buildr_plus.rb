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

expected_versions = %w(1.4.25 1.5.0)
unless expected_versions.include?(Buildr::VERSION.to_s)
  raise "buildr_plus expected one of the Buildr versions #{expected_versions.join(', ')} but actual version is #{Buildr::VERSION}"
end

bundler_version = '1.12.5'
unless Bundler::VERSION >= bundler_version || defined?(JRUBY_VERSION)
  raise "buildr_plus expected Bundler version #{bundler_version} but actual version is #{Bundler::VERSION}"
end

# Try ensure stdout is always emitted sychronously.
# This is particularly important when running in buffering Jenkins instance.
STDOUT.sync=true

require 'yaml'
require 'resolv'
require 'socket'

require 'buildr_plus/core'
require 'buildr_plus/naming'
require 'buildr_plus/extension_registry'
require 'buildr_plus/feature_manager'
require 'buildr_plus/util'

# Patches that should always be applied
require 'buildr_plus/patches/group_project_patch'

require 'buildr_plus/features/appcache'
require 'buildr_plus/features/appconfig'
require 'buildr_plus/features/artifact_assets'
require 'buildr_plus/features/artifacts'
require 'buildr_plus/features/braid'
require 'buildr_plus/features/calendar_date_select'
require 'buildr_plus/features/checks'
require 'buildr_plus/features/checkstyle'
require 'buildr_plus/features/ci'
require 'buildr_plus/features/compile_options'
require 'buildr_plus/features/config'
require 'buildr_plus/features/db'
require 'buildr_plus/features/dbt'
require 'buildr_plus/features/deps'
require 'buildr_plus/features/dev_checks'
require 'buildr_plus/features/dialect_mapping'
require 'buildr_plus/features/docker'
require 'buildr_plus/features/domgen'
require 'buildr_plus/features/ejb'
require 'buildr_plus/features/findbugs'
require 'buildr_plus/features/gems'
require 'buildr_plus/features/geolatte'
require 'buildr_plus/features/geotools'
require 'buildr_plus/features/github'
require 'buildr_plus/features/gitignore'
require 'buildr_plus/features/gitattributes'
require 'buildr_plus/features/glassfish'
require 'buildr_plus/features/guiceyloops'
require 'buildr_plus/features/gwt'
require 'buildr_plus/features/gwt_cache_filter'
require 'buildr_plus/features/idea'
require 'buildr_plus/features/idea_codestyle'
require 'buildr_plus/features/itest'
require 'buildr_plus/features/jackson'
require 'buildr_plus/features/java'
require 'buildr_plus/features/jaxrs'
require 'buildr_plus/features/jdepend'
require 'buildr_plus/features/jenkins'
require 'buildr_plus/features/jms'
require 'buildr_plus/features/keycloak'
require 'buildr_plus/features/less'
require 'buildr_plus/features/libs'
require 'buildr_plus/features/mail'
require 'buildr_plus/features/oss'
require 'buildr_plus/features/pmd'
require 'buildr_plus/features/product_version'
require 'buildr_plus/features/publish'
require 'buildr_plus/features/rails'
require 'buildr_plus/features/redfish'
require 'buildr_plus/features/replicant'
require 'buildr_plus/features/repositories'
require 'buildr_plus/features/roles'
require 'buildr_plus/features/rptman'
require 'buildr_plus/features/ruby'
require 'buildr_plus/features/sass'
require 'buildr_plus/features/selenium'
require 'buildr_plus/features/soap'
require 'buildr_plus/features/sync'
require 'buildr_plus/features/syncrecord'
require 'buildr_plus/features/testng'
require 'buildr_plus/features/timerstatus'
require 'buildr_plus/features/travis'
require 'buildr_plus/features/whitespace'
require 'buildr_plus/features/xml'

require 'buildr_plus/roles/shared'
require 'buildr_plus/roles/model'
require 'buildr_plus/roles/model_qa_support'
require 'buildr_plus/roles/model_qa'
require 'buildr_plus/roles/server'
require 'buildr_plus/roles/soap_client'
require 'buildr_plus/roles/soap_qa_support'
require 'buildr_plus/roles/integration_qa_support'
require 'buildr_plus/roles/integration_tests'
require 'buildr_plus/roles/selenium_tests'
require 'buildr_plus/roles/gwt'
require 'buildr_plus/roles/gwt_qa_support'
require 'buildr_plus/roles/gwt_qa'
require 'buildr_plus/roles/container'
require 'buildr_plus/roles/sync_model'
require 'buildr_plus/roles/user_experience'
require 'buildr_plus/roles/all_in_one'
require 'buildr_plus/roles/all_in_one_library'
require 'buildr_plus/roles/library'
require 'buildr_plus/roles/library_qa_support'
require 'buildr_plus/roles/replicant_shared'
require 'buildr_plus/roles/replicant_qa_support'
require 'buildr_plus/roles/replicant_qa'
require 'buildr_plus/roles/replicant_ee_client'

require 'buildr_plus/config/application'
require 'buildr_plus/config/environment'
require 'buildr_plus/config/database'
require 'buildr_plus/config/ssrs'
require 'buildr_plus/config/broker'
require 'buildr_plus/config/keycloak'
