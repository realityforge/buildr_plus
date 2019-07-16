raise "Patch applied upstream " if Buildr::VERSION.to_s > '1.5.8'

if Buildr::VERSION.to_s == '1.5.8'
  class Buildr::IntellijIdea::IdeaModule

    protected

    def main_dependency_details
      target_dir = buildr_project.compile.target.to_s
      main_dependencies.select {|d| d.to_s != target_dir}.collect do |d|
        dependency_path = d.to_s
        export = true
        source_path = nil
        annotations_path = nil
        if d.is_a?(Buildr::Artifact)
          source_spec = d.to_spec_hash.merge(:classifier => 'sources')
          source_path = Buildr.artifact(source_spec).to_s
          source_path = nil unless File.exist?(source_path)
        end
        if d.is_a?(Buildr::Artifact)
          annotations_spec = d.to_spec_hash.merge(:classifier => 'annotations')
          annotations_path = Buildr.artifact(annotations_spec).to_s
          annotations_path = nil unless File.exist?(annotations_path)
        end
        [dependency_path, export, source_path, annotations_path]
      end
    end

    def test_dependency_details
      main_dependencies_paths = main_dependencies.map(&:to_s)
      target_dir = buildr_project.compile.target.to_s
      test_dependencies.select {|d| d.to_s != target_dir}.collect do |d|
        dependency_path = d.to_s
        export = main_dependencies_paths.include?(dependency_path)
        source_path = nil
        annotations_path = nil
        if d.is_a?(Buildr::Artifact)
          source_spec = d.to_spec_hash.merge(:classifier => 'sources')
          source_path = Buildr.artifact(source_spec).to_s
          source_path = nil unless File.exist?(source_path)
        end
        if d.is_a?(Buildr::Artifact)
          annotations_spec = d.to_spec_hash.merge(:classifier => 'annotations')
          annotations_path = Buildr.artifact(annotations_spec).to_s
          annotations_path = nil unless File.exist?(annotations_path)
        end
        [dependency_path, export, source_path, annotations_path]
      end
    end
  end
end
