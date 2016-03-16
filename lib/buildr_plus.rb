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

expected_version = '1.4.23'
if Buildr::VERSION != expected_version
  raise "buildr_plus expected Buidlr version #{expected_version} but Buildrs actual version is #{Buildr::VERSION}"
end

require 'buildr_plus/core'
require 'buildr_plus/naming'
require 'buildr_plus/extension_registry'
require 'buildr_plus/feature_manager'
require 'buildr_plus/util'

# Patches that should always be applied
require 'buildr_plus/patches/activate_jruby_facet'
require 'buildr_plus/patches/idea_patch'
require 'buildr_plus/patches/projects_patch'

require 'buildr_plus/features/calendar_date_select'
require 'buildr_plus/features/checkstyle'
require 'buildr_plus/features/ci'
require 'buildr_plus/features/compile_options'
require 'buildr_plus/features/db'
require 'buildr_plus/features/dbt'
require 'buildr_plus/features/dev_checks'
require 'buildr_plus/features/dialect_mapping'
require 'buildr_plus/features/domgen'
require 'buildr_plus/features/findbugs'
require 'buildr_plus/features/gitignore'
require 'buildr_plus/features/guiceyloops'
require 'buildr_plus/features/gwt'
require 'buildr_plus/features/idea_codestyle'
require 'buildr_plus/features/itest'
require 'buildr_plus/features/jdepend'
require 'buildr_plus/features/libs'
require 'buildr_plus/features/pmd'
require 'buildr_plus/features/product_version'
require 'buildr_plus/features/publish'
require 'buildr_plus/features/rails'
require 'buildr_plus/features/repositories'
require 'buildr_plus/features/rptman'
require 'buildr_plus/features/sass'
require 'buildr_plus/features/testng'
require 'buildr_plus/features/whitespace'
