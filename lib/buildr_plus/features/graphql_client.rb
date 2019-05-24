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

BuildrPlus::FeatureManager.feature(:graphql_client) do |f|
  f.enhance(:Config) do
    def endpoint(graphql_schema_name, graphql_schema_artifact)
      @graphql_schema_name = graphql_schema_name
      @graphql_schema_artifact = graphql_schema_artifact
    end

    attr_reader :graphql_schema_name
    attr_reader :graphql_schema_artifact

    def generate
      <<JSON
{
  "name": "#{Reality::Naming.pascal_case(self.graphql_schema_name)} GraphQL Schema",
  "schemaPath": "generated/graphql_client/schema.graphql",
  "extensions": {
    "endpoints": {
      "Default GraphQL Endpoint": {
        "url": "http://localhost:8080/#{self.graphql_schema_name}/graphql",
        "headers": {
          "user-agent": "JS GraphQL"
        },
        "introspect": false
      }
    }
  }
}
JSON
    end
  end
  f.enhance(:ProjectExtension) do
    task 'graphql_client:get_schema' do
      if BuildrPlus::FeatureManager.activated?(:graphql_client) && !BuildrPlus::GraphqlClient.graphql_schema_artifact.nil?
        dir = "#{File.dirname(Buildr.application.buildfile.to_s)}/generated/graphql_client"
        mkdir_p dir
        a = Buildr.artifact(BuildrPlus::GraphqlClient.graphql_schema_artifact)
        a.invoke
        cp a.to_s, "#{dir}/schema.graphql"
      end
    end

    task('domgen:all').enhance(['graphql_client:get_schema'])

    desc 'Recreate the .graphqlconfig file'
    task 'graphql_client:check' do
      filename = "#{File.dirname(Buildr.application.buildfile.to_s)}/.graphqlconfig"
      if BuildrPlus::FeatureManager.activated?(:graphql_client) && !BuildrPlus::GraphqlClient.graphql_schema_name
        raise 'The graphql_client feature is enabled but no client has been configured. Please add BuildrPlus::GraphqlClient.endpoint(:myclient, :myclient_schema) to the buildfile and commit changes.'
      elsif BuildrPlus::FeatureManager.activated?(:graphql_client)
        if !File.exist?(filename)
          raise 'The .graphqlconfig file does not exists but the project has the graphql_client facet enabled. Please run \"buildr graphql_client:fix\" and commit changes.'
        elsif IO.read(filename) != BuildrPlus::GraphqlClient.generate
          raise 'The .graphqlconfig file is out of date with the configuration. Please run \"buildr graphql_client:fix\" and commit changes.'
        end
      elsif File.exist?(filename)
        raise 'The .graphqlconfig file exists but the project does not have the graphql_client facet enabled.'
      end
      File.write(filename, BuildrPlus::GraphqlClient.generate)
      sh "git add #{filename}"
    end

    desc 'Recreate the .graphqlconfig file'
    task 'graphql_client:fix' do
      if BuildrPlus::FeatureManager.activated?(:graphql_client) && !BuildrPlus::GraphqlClient.graphql_schema_name
        raise 'The graphql_client feature is enabled but no client has been configured. Please add BuildrPlus::GraphqlClient.endpoint(:myclient, :myclient_schema) to the buildfile and commit changes.'
      elsif BuildrPlus::FeatureManager.activated?(:graphql_client) && BuildrPlus::GraphqlClient.graphql_schema_name
        filename = "#{File.dirname(Buildr.application.buildfile.to_s)}/.graphqlconfig"
        IO.write(filename, BuildrPlus::GraphqlClient.generate)
        sh "git add #{filename}"
      end
    end
  end
end
