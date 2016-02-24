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

require 'buildr_plus'

# Addons present in all of the "standard" projects
require 'buildr/pmd'
require 'buildr/checkstyle'
require 'buildr/single_intermediate_layout'
require 'buildr/findbugs'
require 'buildr/jdepend'
require 'buildr/git_auto_version'
require 'buildr/jacoco'
require 'buildr/top_level_generate_dir'

require 'buildr_plus/features/db'
require 'buildr_plus/features/compile_options'
require 'buildr_plus/features/product_version'
require 'buildr_plus/features/codestyle'
require 'buildr_plus/features/libs'
require 'buildr_plus/features/testng'
require 'buildr_plus/features/source_code_analysis'
require 'buildr_plus/features/ci'
require 'buildr_plus/features/guiceyloops'

# Enable features if the corresponding libraries are loaded
require 'buildr_plus/features/dbt'
require 'buildr_plus/features/domgen'
require 'buildr_plus/features/dialect_mapping'
require 'buildr_plus/features/checkstyle'
require 'buildr_plus/features/pmd'
require 'buildr_plus/features/rptman'
