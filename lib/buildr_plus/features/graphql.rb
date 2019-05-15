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

BuildrPlus::FeatureManager.feature(:graphql) do |f|
  f.enhance(:ProjectExtension) do
    after_define do |buildr_project|
      if buildr_project.ipr?

        desc 'GraphQL Schema'
        define :graphqls do
          project.no_iml

          [:graphqls, :graphqls_sources].each do |type|
            package(type).enhance do |t|
              project.task(':domgen:all').invoke
              mkdir_p File.dirname(t.to_s)
              content = IO.read(root_project._("server/generated/domgen/server/main/java/#{project.group.gsub('.', '/')}/server/#{root_project.name}.graphqls"))
              Dir["#{root_project._("server/src/main/java/#{project.group.gsub('.', '/')}")}/**/*.graphqls"].each do |f|
                content += IO.read(f)
              end

              IO.write(t.to_s, content)
            end
          end
        end
      end
    end
  end
end

class Buildr::Project
  def package_as_graphqls(file_name)
    file(file_name)
  end

  def package_as_graphqls_sources_spec(spec)
    spec.merge(:type => :graphqls, :classifier => :sources)
  end

  def package_as_graphqls_sources(file_name)
    file(file_name)
  end
end
