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

# Try ensure stdout is always emitted synchronously.
# This is particularly important when running in buffering Jenkins instance.
STDOUT.sync=true

require 'yaml'
require 'resolv'
require 'socket'
require 'reality/core'
require 'reality/naming'

require 'buildr_plus/core'
require 'buildr_plus/extension_registry'
require 'buildr_plus/feature_manager'
require 'buildr_plus/util'

# Patches that should always be applied
require 'buildr_plus/patches/group_project_patch'

require 'buildr_plus/features/action'
require 'buildr_plus/features/appconfig'
require 'buildr_plus/features/arez'
require 'buildr_plus/features/artifact_assets'
require 'buildr_plus/features/artifacts'
require 'buildr_plus/features/assets'
require 'buildr_plus/features/bazel'
require 'buildr_plus/features/braid'
require 'buildr_plus/features/checks'
require 'buildr_plus/features/checkstyle'
require 'buildr_plus/features/ci'
require 'buildr_plus/features/clean'
require 'buildr_plus/features/config'
require 'buildr_plus/features/db'
require 'buildr_plus/features/dbt'
require 'buildr_plus/features/deps'
require 'buildr_plus/features/dev_checks'
require 'buildr_plus/features/docker'
require 'buildr_plus/features/domgen'
require 'buildr_plus/features/ejb'
require 'buildr_plus/features/gems'
require 'buildr_plus/features/generate'
require 'buildr_plus/features/generated_files'
require 'buildr_plus/features/geolatte'
require 'buildr_plus/features/geotools'
require 'buildr_plus/features/gitignore'
require 'buildr_plus/features/glassfish'
require 'buildr_plus/features/gwt'
require 'buildr_plus/features/gwt_cache_filter'
require 'buildr_plus/features/idea'
require 'buildr_plus/features/idea_codestyle'
require 'buildr_plus/features/jackson'
require 'buildr_plus/features/java'
require 'buildr_plus/features/jaxrs'
require 'buildr_plus/features/jenkins'
require 'buildr_plus/features/jms'
require 'buildr_plus/features/keycloak'
require 'buildr_plus/features/less'
require 'buildr_plus/features/libs'
require 'buildr_plus/features/node'
require 'buildr_plus/features/product_version'
require 'buildr_plus/features/publish'
require 'buildr_plus/features/react4j'
require 'buildr_plus/features/redfish'
require 'buildr_plus/features/replicant'
require 'buildr_plus/features/repositories'
require 'buildr_plus/features/roles'
require 'buildr_plus/features/ruby'
require 'buildr_plus/features/sass'
require 'buildr_plus/features/serviceworker'
require 'buildr_plus/features/soap'
require 'buildr_plus/features/sql_analysis'
require 'buildr_plus/features/sting'
require 'buildr_plus/features/syncrecord'
require 'buildr_plus/features/testng'
require 'buildr_plus/features/timers'
require 'buildr_plus/features/timeservice'
require 'buildr_plus/features/xml'
require 'buildr_plus/features/zapwhite'

require 'buildr_plus/roles/shared'
require 'buildr_plus/roles/model'
require 'buildr_plus/roles/model_qa_support'
require 'buildr_plus/roles/model_qa'
require 'buildr_plus/roles/server'
require 'buildr_plus/roles/soap_client'
require 'buildr_plus/roles/gwt'
require 'buildr_plus/roles/gwt_qa_support'
require 'buildr_plus/roles/gwt_qa'
require 'buildr_plus/roles/container'
require 'buildr_plus/roles/user_experience'
require 'buildr_plus/roles/library'
require 'buildr_plus/roles/library_qa_support'

require 'buildr_plus/config/application'
require 'buildr_plus/config/environment'
require 'buildr_plus/config/database'
require 'buildr_plus/config/broker'
require 'buildr_plus/config/keycloak'
