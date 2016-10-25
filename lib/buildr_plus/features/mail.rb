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

BuildrPlus::FeatureManager.feature(:mail) do |f|
  f.enhance(:Config) do
    attr_writer :include_db_artifact

    def include_db_artifact?
      @include_db_artifact.nil? ? true : !!@include_db_artifact
    end

    def mail_db
      pg_suffix? ? :mail_db_pg : :mail_db
    end

    def mail_server
      pg_suffix? ? :mail_server_pg : :mail_server
    end

    def mail_qa
      pg_suffix? ? :mail_qa_pg : :mail_qa
    end

    def pg_suffix?
      BuildrPlus::Db.is_multi_database_project? && BuildrPlus::Db.pgsql?
    end
  end
end
