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
BuildrPlus::FeatureManager.feature(:generate) do |f|
  f.enhance(:Config) do
    attr_writer :commit_generated_files

    def commit_generated_files?
      @commit_generated_files.nil? ? false : !!@commit_generated_files
    end

    def clean_generated_files?
      !commit_generated_files?
    end

    def generated_directories
      @generated_directories ||= []
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Generate the source code and pre-compile artifacts required to build application'
    task 'generate:all' do
      task('domgen:all').invoke if BuildrPlus::FeatureManager.activated?(:domgen)
      task('resgen:all').invoke if BuildrPlus::FeatureManager.activated?(:resgen)
    end

    desc 'Check generated source files are committed in source control'
    task 'generate:check_generated_source_code_committed' do
      unless BuildrPlus::Generate.generated_directories.empty?
        status_output = `git status --porcelain #{BuildrPlus::Generate.generated_directories.join(' ')} 2>&1`.strip
        raise "Uncommitted changes in generated source trees but BuildrPlus::Generate.commit_generated_files? returns true. Commit the files or change the setting.\n-----\n#{status_output}\n-----\n" if 0 != status_output.size
      end
    end
  end
end
