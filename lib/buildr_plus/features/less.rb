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
  end

  f.enhance(:ProjectExtension) do
    attr_writer :less_options

    def less_options
      @less_options || {}
    end

    def less_path
      less_options[:source_dir] || project._(BuildrPlus::Less.default_less_path)
    end

    def lessc_required?
      File.exist?(project._(project.less_path))
    end

    first_time do
      require 'buildr_plus/patches/idea_less_extension'
      require 'buildr_plus/patches/lessc'
    end

    after_define do |project|
      if project.lessc_required?
        define_lessc_task(project, project.less_options)
        task(':domgen:all').enhance(["#{project.name}:lessc"])
      end

      if project.ipr?
        p = if BuildrPlus::Roles.project_with_role?(:server)
          project.project(BuildrPlus::Roles.project_with_role(:server).name)
        elsif project.lessc_required?
          project
        else
          nil
        end
        project.ipr.add_less_compiler_component(project, :source_dir => p.less_path) if p
      end
    end
  end
end
