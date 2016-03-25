module Buildr
  module IntellijIdea
    class IdeaProject
      def add_less_compiler_component(project, options = {})
        source_dir = options[:source_dir] || project._(:source, :main, :webapp, :less).to_s
        source_pattern = options[:pattern] || '*.less'
        exclude_pattern = options[:exclude_pattern] || '_*.less'
        target_subdir = options[:target_subdir] || 'css'
        target_dir = options[:target_dir] || project._(:artifacts, project.name)

        add_component('LessManager') do |component|
          component.option :name => 'lessProfiles' do |outer_option|
            outer_option.map do |map|
              map.entry :key => project.name do |entry|
                entry.value do |value|
                  value.LessProfile do |profile|
                    profile.option :name => 'cssDirectories' do |option|
                      option.list do |list|
                        list.CssDirectory do |css_dir|
                          css_dir.option :name => 'path', :value => "#{target_dir}#{target_subdir.nil? ? '' : "/#{target_subdir}"}"
                        end
                      end
                    end
                    profile.option :name => 'includePattern', :value => source_pattern
                    profile.option :name => 'excludePattern', :value => exclude_pattern
                    profile.option :name => 'lessDirPath', :value => source_dir
                    profile.option :name => 'name', :value => project.name
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
