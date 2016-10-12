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

BuildrPlus::FeatureManager.feature(:deps => [:libs]) do |f|
  f.enhance(:Config) do

    def model_deps
      dependencies = []

      if BuildrPlus::FeatureManager.activated?(:geolatte)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geolatte_geom)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geolatte_support)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geotools_for_geolatte) if BuildrPlus::FeatureManager.activated?(:geotools)
        dependencies << Buildr.artifacts(BuildrPlus::Libs.geolatte_geom_jpa) if BuildrPlus::FeatureManager.activated?(:db)
      end
      dependencies << Buildr.artifacts([BuildrPlus::Libs.gwt_datatypes]) if BuildrPlus::FeatureManager.activated?(:gwt)
      dependencies << Buildr.artifacts([BuildrPlus::Libs.jackson_gwt_support]) if BuildrPlus::FeatureManager.activated?(:jackson)

      dependencies.flatten
    end

    def model_qa_support_deps
      dependencies = []

      dependencies << Buildr.artifacts([BuildrPlus::Mail.mail_server, BuildrPlus::Mail.mail_qa, BuildrPlus::Libs.mustache, BuildrPlus::Libs.greenmail]) if BuildrPlus::FeatureManager.activated?(:mail)
      dependencies << Buildr.artifacts([BuildrPlus::Appconfig.appconfig_server, BuildrPlus::Appconfig.appconfig_qa, BuildrPlus::Libs.field_filter]) if BuildrPlus::FeatureManager.activated?(:appconfig)
      dependencies << Buildr.artifacts([BuildrPlus::Syncrecord.syncrecord_server, BuildrPlus::Syncrecord.syncrecord_qa]) if BuildrPlus::FeatureManager.activated?(:syncrecord)

      dependencies.flatten
    end

    def server_deps
      dependencies = []

      dependencies << Buildr.artifacts([BuildrPlus::Libs.gwt_cache_filter]) if BuildrPlus::FeatureManager.activated?(:gwt_cache_filter)
      dependencies << Buildr.artifacts([BuildrPlus::Timerstatus.timerstatus, BuildrPlus::Libs.field_filter]) if BuildrPlus::FeatureManager.activated?(:timerstatus)
      dependencies << Buildr.artifacts([BuildrPlus::Mail.mail_server, BuildrPlus::Libs.mustache]) if BuildrPlus::FeatureManager.activated?(:mail)
      dependencies << Buildr.artifacts([BuildrPlus::Appconfig.appconfig_server, BuildrPlus::Libs.field_filter]) if BuildrPlus::FeatureManager.activated?(:appconfig)
      dependencies << Buildr.artifacts([BuildrPlus::Syncrecord.syncrecord_server, BuildrPlus::Syncrecord.syncrecord_rest_client]) if BuildrPlus::FeatureManager.activated?(:syncrecord)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.gwt_rpc) if BuildrPlus::FeatureManager.activated?(:gwt)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.replicant_server) if BuildrPlus::FeatureManager.activated?(:replicant)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.gwt_appcache_server) if BuildrPlus::FeatureManager.activated?(:appcache)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.keycloak) if BuildrPlus::FeatureManager.activated?(:keycloak)
      dependencies << Buildr.artifacts(BuildrPlus::Libs.proxy_servlet) if BuildrPlus::FeatureManager.activated?(:keycloak) && BuildrPlus::FeatureManager.activated?(:gwt)

      dependencies.flatten
    end

    def user_experience_deps
      dependencies = []

      dependencies << Buildr.artifacts([BuildrPlus::Libs.gwt_appcache_client, BuildrPlus::Libs.gwt_appcache_server]) if BuildrPlus::FeatureManager.activated?(:appcache)

      dependencies.flatten
    end
  end
end
