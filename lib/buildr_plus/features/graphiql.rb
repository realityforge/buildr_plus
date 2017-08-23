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

BuildrPlus::FeatureManager.feature(:graphiql => [:graphql, :gwt_cache_filter]) do |f|
  f.enhance(:Config) do
    def setup_graphiql(assets_dir)
      directory = "#{assets_dir}/graphiql"
      begin
        FileUtils.mkdir_p directory
        graphiql_assets.each_pair do |key, url|
          artifact = Buildr.artifact(key)
          Buildr.download(artifact => url)
          artifact.invoke
          target_file = "#{directory}/#{spec_to_filename(artifact)}"
          FileUtils.cp artifact.to_s, target_file
          sh("gzip -9 -k -f #{target_file}")
        end
        filename = generate_index(directory)
        sh("gzip -9 -k -f #{filename}")
      rescue => e
        FileUtils.rm_rf assets_dir
        raise e
      end
    end

    private

    def graphiql_assets
      {
        'net.jsdelivr:es6-promise:js:4.0.5' => 'http://cdn.jsdelivr.net/es6-promise/4.0.5/es6-promise.auto.min.js',
        'net.jsdelivr:fetch:js:0.9.0' => 'http://cdn.jsdelivr.net/fetch/0.9.0/fetch.min.js',
        'net.jsdelivr:react:js:15.4.2' => 'http://cdn.jsdelivr.net/react/15.4.2/react.min.js',
        'net.jsdelivr:react-dom:js:15.4.2' => 'http://cdn.jsdelivr.net/react/15.4.2/react-dom.min.js',
        'net.jsdelivr:graphiql:css:0.11.2' => 'http://cdn.jsdelivr.net/npm/graphiql@0.11.2/graphiql.css',
        'net.jsdelivr:graphiql:js:0.11.2' => 'http://cdn.jsdelivr.net/npm/graphiql@0.11.2/graphiql.min.js',
      }
    end

    def spec_to_filename(spec)
      "#{spec.id}-#{spec.version}.cache.#{spec.type}"
    end

    def generate_index(directory)
      filename = "#{directory}/index.html"
      IO.write(filename, <<CONTENT)
<!DOCTYPE html>
<html>
<head>
  <title>#{Reality::Naming.humanize(root_project.name)} API</title>
  <style>
    body {
      height: 100%;
      margin: 0;
      width: 100%;
      overflow: hidden;
    }

    #graphiql {
      height: 100vh;
    }
  </style>
#{graphiql_assets.keys.collect do |key|
        artifact = Buildr.artifact(key)
        artifact.type.to_s == 'js' ? "  <script src=\"#{spec_to_filename(artifact)}\" charset=\"UTF-8\"></script>" : "  <link rel=\"stylesheet\" href=\"#{spec_to_filename(artifact)}\"/>"
      end.join("\n")}
</head>
<body>
<div id="graphiql">Loading...</div>
<script>

  function graphQLFetcher(graphQLParams) {
    return fetch('../graphql', {
      method: 'post',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(graphQLParams),
      credentials: 'include'
    }).then(function(response) {
      return response.text();
    }).then(function(responseBody) {
      try {
        return JSON.parse(responseBody);
      } catch (error) {
        return responseBody;
      }
    });
  }

  var element = React.createElement(GraphiQL, { fetcher: graphQLFetcher }, React.createElement(GraphiQL.Logo, {}, '#{Reality::Naming.humanize(root_project.name)} API'));
  ReactDOM.render(element, document.getElementById('graphiql'));
</script>
</body>
</html>
CONTENT
      filename
    end
  end
end


