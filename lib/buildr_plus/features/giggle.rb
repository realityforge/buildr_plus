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

BuildrPlus::FeatureManager.feature(:giggle => [:generate]) do |f|
  f.enhance(:Config) do

    def generate_giggle_java_server(project)
      generated_dir = project._(:generated, 'giggle-server/src/java')
      generate_task = project.task(generated_dir => [project.task(':domgen:all')]) do
        type_mapping_file = project._("generated/domgen/server/main/resources/#{project.group.gsub('.', '/')}/server/types.mapping")
        schema_pkg = project.project('graphqls').package(:graphqls)
        schema_pkg.invoke
        jar = Buildr.artifact(BuildrPlus::Deps.giggle)
        jar.invoke
        Java::Commands.java %W(-jar #{jar} --package #{project.root_project.group}.server.graphql --schema #{schema_pkg} --type-mapping #{type_mapping_file} --output-directory #{generated_dir} --generator java-server)
      end

      link_giggle_task(project, generate_task, generated_dir)
    end

    def generate_giggle_java_client(project, options = {})
      schema = options[:schema] || :default
      dir = options[:dir] || "**"
      generated_dir = project._(:generated, "giggle-client-#{schema}/src/java")

      generate_task = project.task(generated_dir => [project.task(':domgen:all')]) do
        schema_pkg = Buildr.artifact(BuildrPlus::GraphqlClient.graphql_schema_artifact(schema))
        schema_pkg.invoke
        jar = Buildr.artifact(BuildrPlus::Deps.giggle)
        jar.invoke
        graphql_documents = Dir["#{project._(:source, :main, :java)}/#{dir}/*.graphql"].collect {|f| ['--document', f]}.flatten

        url_suffix = options[:url_suffix] || '/graphql'
        read_timeout = options[:read_timeout] || '10000'
        defines = []
        {
          'cdi.service.name' => "#{Reality::Naming.pascal_case(schema)}Service",
          'cdi.base_url.jndi_name' => "#{project.root_project.name}/env/#{schema}_url",
          'cdi.url.suffix' => url_suffix,
          'cdi.read_timeout' => read_timeout,
          'cdi.keycloak.client.name' => "#{Reality::Naming.pascal_case(schema)}.Keycloak",
        }.each_pair do |k, v|
          defines << "-D#{k}=#{v}"
        end

        Java::Commands.java %W(-jar #{jar} --package #{project.root_project.group}.server.api.#{schema} --schema #{schema_pkg} --output-directory #{generated_dir} --generator java-client --generator java-cdi-client) + defines + graphql_documents
      end

      link_giggle_task(project, generate_task, generated_dir)
    end

    private

    def link_giggle_task(project, task, generated_dir)
      desc 'Generate GraphQL support code'
      project.task('giggle:generate' => [task.name])
      project.task(':giggle:generate' => [task.name])

      project.iml.main_source_directories << generated_dir
      project.compile.enhance([task.name])
      project.compile.from(generated_dir)
      project.root_project.pmd.exclude_paths << generated_dir if BuildrPlus::FeatureManager.activated?(:pmd)
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Generate all of the GraphQL support code'
    task 'giggle:generate'
  end
end
