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

module Buildr
  # Provides the ability to publish selected artifacts to a secondary repository
  module Publish

    module ProjectExtension
      include Extension

      attr_writer :publish

      def publish?
        @publish.nil? ? true : @publish
      end

      after_define do |project|
        desc 'Publish artifacts of version PUBLISH_VERSION to repository'
        project.task('publish') do
          publish_version = ENV['PUBLISH_VERSION'] || (raise 'Must specify PUBLISH_VERSION environment variable to use publish task')
          project.packages.each do |pkg|
            a = Buildr.artifact(pkg.to_hash.merge(:version => publish_version))
            a.invoke
            a.upload
          end
        end if project.publish?
      end
    end
  end
end

class Buildr::Project
  include Buildr::Publish::ProjectExtension
end

desc 'Publish all specified artifacts '
task 'publish' do
  Buildr.projects.each do |project|
    project.task('publish').invoke if project.publish?
  end
end
