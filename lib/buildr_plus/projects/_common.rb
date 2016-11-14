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

require 'buildr/activate_jruby_facet'
require 'buildr/single_intermediate_layout'
require 'buildr/git_auto_version'
require 'buildr/top_level_generate_dir'

BuildrPlus::FeatureManager.activate_features([
                                               :checks,
                                               :repositories,
                                               :artifacts,
                                               :idea,
                                               :idea_codestyle,
                                               :roles,
                                               :product_version,
                                               :libs,
                                               :deps,
                                               :publish,
                                               :whitespace,
                                               :gitignore,
                                               :gitattributes,
                                               :artifact_assets,
                                               :ci,
                                               :gems,
                                               :config
                                             ])

BuildrPlus::FeatureManager.activate_feature(:dbt) if BuildrPlus::Util.is_dbt_gem_present?
BuildrPlus::FeatureManager.activate_feature(:dialect_mapping) if BuildrPlus::FeatureManager.activated?(:dbt)
BuildrPlus::FeatureManager.activate_feature(:domgen) if BuildrPlus::Util.is_domgen_gem_present?
BuildrPlus::FeatureManager.activate_feature(:rptman) if BuildrPlus::Util.is_rptman_gem_present?
BuildrPlus::FeatureManager.activate_feature(:sass) if BuildrPlus::Util.is_sass_gem_present?
BuildrPlus::FeatureManager.activate_feature(:redfish) if BuildrPlus::Util.is_redfish_gem_present?
BuildrPlus::FeatureManager.activate_feature(:braid) if BuildrPlus::Util.is_braid_gem_present?
