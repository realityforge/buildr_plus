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

    def ruby_version
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      IO.read("#{base_directory}/.ruby-version").strip
    end

    def travis_content
      rv = ruby_version
      content = <<CONTENT
language: ruby
jdk:
  - oraclejdk7
sudo: false
rvm:
  - #{rv}
CONTENT

      if BuildrPlus::Db.tiny_tds_defined?
        content += <<CONTENT
addons:
  apt:
    packages:
    - freetds-dev
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
  - export DB_SERVER_PASSWORD=
  - export DB_SERVER_HOST=127.0.0.1
CONTENT
      end

      content += <<CONTENT
script: buildr ci:pull_request --trace
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
