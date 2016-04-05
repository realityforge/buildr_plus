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

BuildrPlus::FeatureManager.feature(:sass) do |f|
  f.enhance(:Config) do
    def default_sass_paths
      BuildrPlus::FeatureManager.activated?(:rails) ? %w(public/stylesheets/sass) : %w(src/main/webapp/sass)
    end

    def target_css_files(project)
      project.sass_paths.select { |p| File.directory?(p) }.collect do |sass_path|
        Dir["#{sass_path}/**/[^_]*.s[ac]ss"].collect do |sass_file|
          project.to_target_file(sass_path, sass_file)
        end
      end.flatten
    end
  end

  f.enhance(:ProjectExtension) do
    attr_writer :sass_paths

    def sass_paths
      @sass_paths || BuildrPlus::Sass.default_sass_paths.collect { |p| _(p) }
    end

    def to_target_file(source_dir, sass_file)
      if BuildrPlus::FeatureManager.activated?(:rails)
        sass_file.gsub(/\.s[ac]ss$/, '.css').gsub(/\/s[ac]ss\//, '/')
      else
        target_dir = _(:generated, :sass, :main, :webapp)
        "#{target_dir}/css/#{Buildr::Util.relative_path(sass_file, source_dir)[0...-5]}.css"
      end
    end

    first_time do
      require 'sass'
    end

    before_define do |project|
      p = project.root_project
      p.clean { rm_rf p._('.sass-cache') }
      p.iml.excluded_directories << p._('.sass-cache') if p.iml?

      desc "Precompile assets for #{project.name}"
      t = project.task('assets:precompile') do
        project.sass_paths.select { |p| File.directory?(p) }.collect do |sass_path|
          Dir["#{sass_path}/**/[^_]*.s[ac]ss"].each do |sass_file|
            target_file = project.to_target_file(sass_path, sass_file)
            FileUtils.mkdir_p File.dirname(target_file)
            syntax = sass_file =~ /.*\.sass$/ ? :sass : :scss
            File.open(target_file, 'w') do |out|
              input = File.read(sass_file)
              load_paths = [sass_path]
              out.write(Sass::Engine.new(input, :load_paths => load_paths, :syntax => syntax).render)
            end
          end
        end
      end

      project.clean do
        if BuildrPlus::FeatureManager.activated?(:rails)
          project.sass_paths.select { |sass_path| File.directory?(sass_path) }.each do |sass_path|
            Dir["#{sass_path}/**/[^_]*.s[ac]ss"].each do |sass_file|
              FileUtils.rm_f project.to_target_file(sass_path, sass_file)
            end
          end
        else
          FileUtils.rm_rf project._(:generated, :sass, :main, :webapp)
        end
      end

      project.assets.enhance([t.name])

      unless BuildrPlus::FeatureManager.activated?(:rails)
        webapp_dir = project._(:generated, :sass, :main, :webapp)

        project.assets.paths << file(webapp_dir => [t.name]) do
          mkdir_p webapp_dir
        end
      end

      desc 'Precompile all assets'
      project.task(':assets:precompile' => t.name)

      project.task(':domgen:all' => t.name)
    end
  end
end
