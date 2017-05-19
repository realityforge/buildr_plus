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

BuildrPlus::FeatureManager.feature(:repositories) do |f|
  f.enhance(:ProjectExtension) do
    first_time do
      Buildr.repositories.remote.unshift(ENV['DOWNLOAD_REPO']) if ENV['DOWNLOAD_REPO']
      Buildr.repositories.remote.unshift('https://stocksoftware.artifactoryonline.com/stocksoftware/public')
      Buildr.repositories.remote.unshift('http://central.maven.org/maven2')
      Buildr.repositories.remote.unshift('https://stocksoftware.artifactoryonline.com/stocksoftware/oss')
      if BuildrPlus::FeatureManager.activated?(:geolatte)
        Buildr.repositories.remote.unshift('http://download.osgeo.org/webdav/geotools')
      end
      unless BuildrPlus::FeatureManager.activated?(:github)
        Buildr.repositories.remote.unshift('http://repo.ffm.vic.gov.au/repository/ffm')
      end
    end
  end
end
