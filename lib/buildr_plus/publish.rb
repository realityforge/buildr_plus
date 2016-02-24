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
