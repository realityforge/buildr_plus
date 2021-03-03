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

BuildrPlus::FeatureManager.feature(:less) do |f|
  f.enhance(:Config) do
    def default_less_path
      'src/main/webapp/less'
    end

    attr_writer :options

    def options
      @options ||= {}
    end

    def less_path
      options[:source_dir] || BuildrPlus::Less.default_less_path
    end

    def define_lessc_task(project, options = {})
      params = {
        :js => false,
        :strict_math => true,
        :optimize => true,
        :strict_units => true,
        :target_dir => project._(:generated, :less, :main, :webapp),
        :target_subdir => 'css',
        :source_dir => BuildrPlus::Less.default_less_path,
        :source_pattern => '**/[^_]*.less'
      }.merge(options)

      source_dir = project._(params[:source_dir])
      source_pattern = params[:source_pattern]
      target_dir = params[:target_dir]

      files = FileList["#{source_dir}/#{source_pattern}"]

      if files.size > 0
        desc 'Preprocess Less files'
        compile_task = project.task('lessc' => [files]) do
          command = []
          command << 'yarn'
          command << 'run'
          command << 'lessc'
          command << '--'
          command << '--no-js' unless params[:js]
          command << "--strict-math=#{!!params[:strict_math] ? 'on' : 'off'}"
          command << "--strict-units=#{!!params[:strict_units] ? 'on' : 'off'}"

          if params[:optimize]
            command << '--compress'
            command << '--clean-css'
          end

          target_subdir = params[:target_subdir].nil? ? '' : "#{params[:target_subdir]}/"

          puts 'Compiling Less'
          files.each do |f|
            sh "#{command.join(' ')} #{f} #{target_dir}/#{target_subdir}#{Buildr::Util.relative_path(f, source_dir)[0...-5]}.css"
          end
          touch target_dir
        end

        project.task(':generate:all' => [compile_task])

        project.assets.paths << project.file(target_dir => [compile_task])
        target_dir
      else
        nil
      end
    end
  end

  f.enhance(:ProjectExtension) do
    def less_path
      project._(BuildrPlus::Less.less_path)
    end

    def lessc_required?
      File.exist?(less_path)
    end

    before_define do |project|
      if project.lessc_required?
        BuildrPlus::Less.define_lessc_task(project, BuildrPlus::Less.options)
        task(':domgen:all').enhance(["#{project.name}:lessc"])
        if project.ipr?
          p = if BuildrPlus::Roles.project_with_role?(:server)
            project.project(BuildrPlus::Roles.project_with_role(:server).name)
          else
            project
          end
          project.ipr.add_less_compiler_component(project, :source_dir => p.less_path)
        end
      end
    end
  end
end
