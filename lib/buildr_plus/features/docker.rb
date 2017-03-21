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
BuildrPlus::FeatureManager.feature(:docker) do |f|
  f.enhance(:Config) do
    attr_writer :push_image

    def push_image?
      @push_image.nil? ? false : @push_image
    end

    def organisation=(organisation)
      @organisation = organisation
      self.push_image = true
    end

    def organisation
      @organisation.nil? ? 'stocksoftware' : @organisation
    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      desc 'Delete all dangling images'
      task 'docker:delete_dangling_images' do
        unless `docker images -q -f dangling=true`.empty?
          sh('docker rmi $(docker images -q -f dangling=true)')
        end
      end

      desc 'Kill all running containers'
      task 'docker:kill_running_containers' do
        unless `docker ps -q`.empty?
          sh('docker kill $(docker ps -q)')
        end
      end

      desc 'Delete all stopped containers'
      task 'docker:delete_stopped_containers' do
        unless `docker ps -a -q -f status=exited`.empty?
          sh('docker rm -v $(docker ps -a -q -f status=exited)')
        end
      end
    end
  end
end
