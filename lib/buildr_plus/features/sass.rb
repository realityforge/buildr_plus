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
  end

  f.enhance(:ProjectExtension) do
    first_time do
      require 'sass'
    end

    after_define do |project|
      sass_paths = BuildrPlus::Sass.sass_paths.collect { |p| project._(p) }.select { |p| File.exist?(p) }
      if sass_paths.size > 0
        project.iml.excluded_directories << project._('.sass-cache')
        project.clean { rm_rf project._('.sass-cache') }

        desc "Precompile assets for #{project.name}"
        t = project.task('assets:precompile') do

          sass_paths.each do |sass_path|
            Dir["#{sass_path}/**/*.sass"].each do |sass|
              File.open(sass.gsub(/sass$/, 'css').gsub(/\/sass/, ''), 'w') do |f|
                f.write(Sass::Engine.new(File.read(sass), :load_paths => [File.dirname(sass)]).render)
              end
            end
          end
        end

        project.clean do
          sass_paths.each do |sass_path|
            Dir["#{sass_path}/**/*.sass"].each do |sass|
              file = sass.gsub(/sass$/, 'css').gsub(/\/sass/, '')
              FileUtils.rm_f(file)
            end
          end
        end

        desc 'Precompile all assets'
        project.task(':assets:precompile' => t.name)
      end
    end
  end
end
