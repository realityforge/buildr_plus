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

BuildrPlus::FeatureManager.feature(:publish) do |f|
  f.enhance(:ProjectExtension) do
    attr_writer :publish

    def publish?
      @publish.nil? ? true : @publish
    end

    first_time do
      desc 'Publish all specified artifacts'
      task 'publish' do
        Buildr.projects.each do |project|
          project.task('publish').invoke if project.publish?
        end
      end

      desc 'List artifacts that will be published'
      task 'list_published' do
        Buildr.projects.each do |project|
          if project.publish?
            project.packages.each do |a|
              puts a.to_spec
            end
          end
        end
      end

      desc 'Upload all specified artifacts'
      task 'upload_published' do
        Buildr.projects.each do |project|
          project.task('upload_published').invoke if project.publish?
        end
      end
    end

    after_define do |project|
      desc 'Download and then upload publishable artifacts to repository'
      project.task('publish') do
        publish_version = ENV['PUBLISH_VERSION'] || (raise 'Must specify PUBLISH_VERSION environment variable to use publish task')
        project.packages.each do |pkg|
          a = Buildr.artifact(pkg.to_hash.merge(:version => publish_version))
          a.invoke
          a.upload

          if BuildrPlus::Db.is_multi_database_project?
            # Assume this is run with DB_TYPE as mssql or unset
            group = "#{pkg.to_hash[:group]}#{BuildrPlus::Db.artifact_suffix(:pgsql)}"
            a = Buildr.artifact(pkg.to_hash.merge(:version => publish_version, :group => group))
            a.invoke
            a.upload
          end
        end
      end if project.publish?

      desc 'Upload artifacts marked as published to repository'
      task 'upload_published' do
        project.packages.each do |pkg|
          pkg.upload
        end
      end if project.publish?
    end
  end
end
