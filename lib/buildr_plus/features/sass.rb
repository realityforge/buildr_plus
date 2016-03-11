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
      BuildrPlus::FeatureManager.activated?(:rails) ? %w(public/stylesheets/sass) : []
    end

    attr_writer :sass_paths

    def sass_paths
      @sass_paths || self.default_sass_paths
    end

    def active_sass_paths(buildr_project)
      BuildrPlus::Sass.sass_paths.collect { |p| buildr_project._(p) }.select { |p| File.exist?(p) }
    end

    def sass_files(buildr_project)
      active_sass_paths(buildr_project).collect do |sass_path|
        Dir["#{sass_path}/**/*.sass"]
      end.flatten
    end

    def target_css_files(buildr_project)
      sass_files(buildr_project).collect{|sass_file|to_target_file(sass_file)}
    end

    def to_target_file(sass_file)
      sass_file.gsub(/\.sass$/, '.css').gsub(/\/sass/, '')
    end
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'sass'
    end

    after_define do |project|
      sass_files = BuildrPlus::Sass.sass_files(project)
      if sass_files.size > 0
        project.iml.excluded_directories << project._('.sass-cache')
        project.clean { rm_rf project._('.sass-cache') }

        desc "Precompile assets for #{project.name}"
        t = project.task('assets:precompile') do

          sass_files.each do |sass_file|
            target_file = BuildrPlus::Sass.to_target_file(sass_file)
            File.open(target_file, 'w') do |out|
              input = File.read(sass_file)
              load_paths = [File.dirname(sass_file)]
              out.write(Sass::Engine.new(input, :load_paths => load_paths).render)
            end
          end
        end

        project.clean do
          BuildrPlus::Sass.target_css_files(project).each do |css_file|
            FileUtils.rm_f(css_file)
          end
        end

        desc 'Precompile all assets'
        project.task(':assets:precompile' => t.name)
      end
    end
  end
end
