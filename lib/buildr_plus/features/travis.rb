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

# Enable this feature if the code is tested using travis
BuildrPlus::FeatureManager.feature(:travis => [:oss]) do |f|
  f.enhance(:Config) do

    def travis_content
      rv = BuildrPlus::Ruby.ruby_version
      docker_active = BuildrPlus::FeatureManager.activated?(:docker)

      content = <<CONTENT
language: ruby
jdk:
  - oraclejdk7
sudo: #{docker_active ? 'required' : 'false'}
rvm:
  - #{rv}
CONTENT
      if docker_active
        content += <<CONTENT
services:
  - docker
CONTENT
      end
      content += <<CONTENT
addons:
  apt:
    packages:
CONTENT
      if BuildrPlus::Db.tiny_tds_defined?
        content += <<CONTENT
    - freetds-dev
CONTENT
      end
      if docker_active
        content += <<CONTENT
    - socat
CONTENT
      end
      content += <<CONTENT
install:
  - rvm use #{rv}
  - gem install bundler
  - bundle install
CONTENT

      if BuildrPlus::Db.is_multi_database_project? || BuildrPlus::Db.pg_defined?
        content += <<CONTENT
  - export DB_TYPE=pg
  - export DB_SERVER_USERNAME=postgres
  - export DB_SERVER_PASSWORD=postgres
CONTENT
        if docker_active
          # We need to introduce a local port proxy and expose it on public ip so that
          # any code inside the container can access the postgres server
          content += <<CONTENT
  - export HOST_IP_ADDRESS=`ifconfig eth0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\\.){3}[0-9]*).*/\\2/p'`
  - socat TCP-LISTEN:10000,fork TCP:127.0.0.1:5432 &
  - export DB_SERVER_HOST=${HOST_IP_ADDRESS}
  - export DB_SERVER_PORT=10000
CONTENT
        else
          content += <<CONTENT
  - export DB_SERVER_HOST=127.0.0.1
CONTENT
        end
      end

      content += <<CONTENT
script: buildr ci:pull_request
git:
  depth: 10
CONTENT

      content
    end

  end
  f.enhance(:ProjectExtension) do
    task 'travis:check' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.travis.yml"
      if !File.exist?(filename) || IO.read(filename) != BuildrPlus::Travis.travis_content
        raise 'The .travis.yml configuration file does not exist or is not up to date. Please run "buildr travis:fix" and commit changes.'
      end
    end

    task 'travis:fix' do
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      filename = "#{base_directory}/.travis.yml"
      File.open(filename, 'wb') do |file|
        file.write BuildrPlus::Travis.travis_content
      end
    end
  end
end
