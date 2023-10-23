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

    # Patterns for files to match to keep in generated directories
    def keep_file_patterns
      @keep_file_patterns ||= []
    end
  end

  f.enhance(:ProjectExtension) do

    attr_writer :inline_generated_source

    def inline_generated_source?
      @inline_generated_source.nil? ? false : !!@inline_generated_source
    end

    def keep_file_patterns
      @keep_file_patterns ||= []
    end

    def all_keep_file_patterns
      BuildrPlus::Generate.keep_file_patterns + self.keep_file_patterns
    end

    def keep_file_names
      if File.exist?(keep_filename_registry)
        base = File.expand_path(project._('src'))
        IO.read(keep_filename_registry).split("\n").collect{|f|"#{base}/#{f}"}
      else
        []
      end
    end

    def keep_filename_registry
      File.expand_path(project._('src')) + "/keep_files.txt"
    end

    before_define do |project|
      desc 'Collect the files that will be kept and not cleaned by resgen/domgen clean processes'
      t = project.task 'collect_keep_files' do
        if project.inline_generated_source?
          target_dir = File.expand_path(project._('src'))
          files = []
          Dir["#{target_dir}/**/*"].each do |file_name|
            if !File.directory?(file_name) && !IO.read(file_name).include?('DO NOT EDIT: File is auto-generated')
              files << ::Buildr::Util.relative_path(file_name, target_dir)
            end
          end
          IO.write("#{target_dir}/keep_files.txt", files.sort.join("\n") + "\n")
        end
      end

      project.task(':domgen:load').enhance([t.name])
    end

    desc 'Generate the source code and pre-compile artifacts required to build application'
    task 'generate:all' do
      task('domgen:all').invoke if BuildrPlus::FeatureManager.activated?(:domgen)
      task('resgen:all').invoke if BuildrPlus::FeatureManager.activated?(:resgen)
    end

    desc 'Check generated source files are committed in source control'
    task 'generate:check_generated_source_code_committed' do
      unless BuildrPlus::Generate.generated_directories.empty?
        status_output = `git status --porcelain #{BuildrPlus::Generate.generated_directories.join(' ')} 2>&1`.strip
        raise "Uncommitted changes in generated source trees but BuildrPlus::Generate.commit_generated_files? returns true. Commit the files or change the setting.\n-----\n#{status_output}\n-----\n#{`git status #{BuildrPlus::Generate.generated_directories.join(' ')} 2>&1`}" if 0 != status_output.size
      end
    end
  end
end
