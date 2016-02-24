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

require 'buildr_plus/extension_registry'

# Patches that should always be applied
require 'buildr_plus/patches/activate_jruby_facet'
require 'buildr_plus/patches/checkstyle_patch'
require 'buildr_plus/patches/idea_patch'

# Only patch gwt if gwt addon already included
require 'buildr_plus/patches/gwt_patch' if $LOADED_FEATURES.any?{|f| f =~ /\/addon\/buildr\/gwt\.rb$/}

# May not always be required
require 'buildr_plus/dev'
require 'buildr_plus/publish'
