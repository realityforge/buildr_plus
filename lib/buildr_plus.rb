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

require 'buildr_plus/features/artifact_assets'
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
require 'buildr_plus/features/dev_checks'
require 'buildr_plus/features/domgen'
require 'buildr_plus/features/ejb'
require 'buildr_plus/features/generate'
require 'buildr_plus/features/generated_files'
require 'buildr_plus/features/glassfish'
require 'buildr_plus/features/gwt'
require 'buildr_plus/features/idea'
require 'buildr_plus/features/idea_codestyle'
require 'buildr_plus/features/java'
require 'buildr_plus/features/jaxrs'
require 'buildr_plus/features/jms'
require 'buildr_plus/features/keycloak'
require 'buildr_plus/features/libs'
require 'buildr_plus/features/product_version'
require 'buildr_plus/features/publish'
require 'buildr_plus/features/redfish'
require 'buildr_plus/features/sql_analysis'
require 'buildr_plus/features/sting'
require 'buildr_plus/features/testng'
require 'buildr_plus/features/timers'
require 'buildr_plus/features/timeservice'
require 'buildr_plus/features/xml'

require 'buildr_plus/config/application'
require 'buildr_plus/config/environment'
require 'buildr_plus/config/database'
require 'buildr_plus/config/broker'
require 'buildr_plus/config/keycloak'
