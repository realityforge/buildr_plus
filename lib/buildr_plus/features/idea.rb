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

BuildrPlus::FeatureManager.feature(:idea) do |f|
  f.enhance(:Config) do
    attr_writer :peer_projects

    def peer_projects
      @peer_projects ||= []
    end
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|
      if project.ipr?
        project.iml.excluded_directories << project._(:artifacts)

        BuildrPlus::Idea.peer_projects.each do |project_name|
          if File.exist?(project._("../#{project_name}"))
            Dir["#{project._("../#{project_name}")}/**/*.iml"].each do |filename|
              project.ipr.extra_modules << Buildr::Util.relative_path(filename, project._('.'))
            end
          end
        end
      end
    end
  end
end
