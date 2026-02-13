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
    def generated_directories
      @generated_directories ||= []
    end

    # Patterns for files to match to keep in generated directories
    def keep_file_patterns
      @keep_file_patterns ||= []
    end
  end

  f.enhance(:ProjectExtension) do

    attr_writer :contains_generated_code

    def contains_generated_code?
      @contains_generated_code.nil? ? false : !!@contains_generated_code
    end

    attr_writer :generated_source_bases

    def generated_source_bases
      @generated_source_bases ||= [File.expand_path(project._('src'))]
    end

    def extra_keep_file_names
      @extra_keep_file_names ||= []
    end

    def keep_file_patterns
      @keep_file_patterns ||= []
    end

    def all_keep_file_patterns
      BuildrPlus::Generate.keep_file_patterns + self.keep_file_patterns
    end

    def keep_file_names
      results = []
      generated_source_bases.collect do |base|
        keep_filename_registry = base + "/keep_files.txt"
        if File.exist?(keep_filename_registry)
          results << IO.read(keep_filename_registry).split("\n").collect { |f| "#{base}/#{f}" }
        end
      end
      results.flatten
    end

    first_time do
      namespace 'domgen' do
        task 'pre_generate' do
        end
      end
    end

    before_define do |project|
      desc 'Collect the files that will be kept and not cleaned by domgen clean processes'
      t = project.task 'collect_keep_files' do
        keep_files_regenerated = false

        if project.contains_generated_code?
          project.generated_source_bases.collect do |target_dir|
            files = []
            Dir["#{target_dir}/**/*"].each do |file_name|
              if !File.directory?(file_name) && !IO.read(file_name).include?('DO NOT EDIT: File is auto-generated')
                files << ::Buildr::Util.relative_path(file_name, target_dir)
              end
            end
            files += project.extra_keep_file_names
            new_content = files.sort.join("\n") + "\n"

            existing = IO.read("#{target_dir}/keep_files.txt") rescue ''
            if existing != new_content
              puts "Generating keep_files.txt in #{target_dir} for #{project.name}"
              FileUtils.mkdir_p target_dir
              IO.write("#{target_dir}/keep_files.txt", new_content)
              IO.write("#{target_dir}/.gitattributes", new_content.split("\n").collect{|line| "#{line} linguist-generated"}.join("\n") + "\n")
              keep_files_regenerated = true
            end
          end

          Domgen.error("Regenerated keep files, aborting build to ensure no files are accidentally deleted. Please try build again") if keep_files_regenerated
        end
      end
      project.task(':domgen:load').enhance([t.name])
      project.task(':generate:keep_files').enhance([t.name])
    end

    desc 'Generate the keep files'
    task 'generate:keep_files'

    desc 'Generate the source code and pre-compile artifacts required to build application'
    task 'generate:all' do
      task('domgen:all').invoke if BuildrPlus::FeatureManager.activated?(:domgen)
    end

    desc 'Check generated source files are committed in source control'
    task 'generate:check_generated_source_code_committed' do
      unless BuildrPlus::Generate.generated_directories.empty?
        status_output = `git status --porcelain #{BuildrPlus::Generate.generated_directories.join(' ')} 2>&1`.strip
        diff_output = `git diff #{BuildrPlus::Generate.generated_directories.join(' ')} 2>&1`.strip
        raise "Uncommitted changes in generated source trees. Commit the files.\n-----\n#{diff_output}\n-----\n#{`git status #{BuildrPlus::Generate.generated_directories.join(' ')} 2>&1`}" if 0 != status_output.size
      end
    end
  end
end
