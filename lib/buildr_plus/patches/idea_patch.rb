raise 'Patch applied in latest release of buildr' if Buildr::VERSION > '1.4.23'

module Buildr #:nodoc:
  module IntellijIdea
    class IdeaModule < IdeaFile
      def main_dependencies
        @main_dependencies ||= buildr_project.compile.dependencies.dup
      end

      def test_dependencies
        @test_dependencies ||= buildr_project.test.compile.dependencies.dup
      end

      def main_source_directories
        @main_source_directories ||= [buildr_project.compile.sources].flatten.compact
      end

      def main_resource_directories
        @main_resource_directories ||= [buildr_project.resources.sources].flatten.compact
      end

      def main_generated_source_directories
        @main_generated_source_directories ||= []
      end

      def main_generated_resource_directories
        @main_generated_resource_directories ||= []
      end

      def test_source_directories
        @test_source_directories ||= [buildr_project.test.compile.sources].flatten.compact
      end

      def test_resource_directories
        @test_resource_directories ||= [buildr_project.test.resources.sources].flatten.compact
      end

      def test_generated_source_directories
        @test_generated_source_directories ||= []
      end

      def test_generated_resource_directories
        @test_generated_resource_directories ||= []
      end

      def generate_content(xml)
        xml.content(:url => 'file://$MODULE_DIR$') do
          # Source folders
          [
            {:dirs => (self.main_source_directories.dup - self.main_generated_source_directories)},
            {:dirs => self.main_generated_source_directories, :generated => true},
            {:type => 'resource', :dirs => (self.main_resource_directories.dup - self.main_generated_resource_directories)},
            {:type => 'resource', :dirs => self.main_generated_resource_directories, :generated => true},
            {:test => true, :dirs => (self.test_source_directories - self.test_generated_source_directories)},
            {:test => true, :dirs => self.test_generated_source_directories, :generated => true},
            {:test => true, :type => 'resource', :dirs => (self.test_resource_directories - self.test_generated_resource_directories)},
            {:test => true, :type => 'resource', :dirs => self.test_generated_resource_directories, :generated => true},
          ].each do |content|
            content[:dirs].map { |dir| dir.to_s }.compact.sort.uniq.each do |dir|
              options = {}
              options[:url] = file_path(dir)
              options[:isTestSource] = (content[:test] ? 'true' : 'false') if content[:type] != 'resource'
              options[:type] = 'java-resource' if content[:type] == 'resource' && !content[:test]
              options[:type] = 'java-test-resource' if content[:type] == 'resource' && content[:test]
              options[:generated] = 'true' if content[:generated]
              xml.sourceFolder options
            end
          end

          # Exclude target directories
          self.net_excluded_directories.
            collect { |dir| file_path(dir) }.
            select { |dir| relative_dir_inside_dir?(dir) }.
            sort.each do |dir|
            xml.excludeFolder :url => dir
          end
        end
      end
    end
  end
end
