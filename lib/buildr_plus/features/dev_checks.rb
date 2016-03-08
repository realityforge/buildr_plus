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
BuildrPlus::FeatureManager.feature(:dev_checks) do |f|
  f.enhance(:ProjectExtension) do

    desc 'Run pre-commit tests and open the code quality reports.'
    task 'dev:checks' => %w(ci:commit dev:open-reports)

    desc 'Open any code quality reports that have been generated.'
    task 'dev:open-reports' do

      top_level_projects = Buildr.projects.select { |p| !(p.name =~ /:/) }
      raise "Expected to find a single top-level project but found #{top_level_projects.collect { |p| p.name }.inspect}" unless top_level_projects.size == 1

      os = RbConfig::CONFIG['host_os']
      is_unix = os =~ /(aix|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i

      %w(checkstyle/checkstyle.html pmd/pmd.html findbugs/findbugs.html pmd/cpd.text).each do |file|
        f = top_level_projects[0]._(:reports, file)
        if File.exist?(f)
          puts "Opening #{f}"

          if f =~ /\.text$/
            # Rename file so it is forced to open in browser
            target_filename = f.gsub(/\.text$/, '.html')
            target_file = File.open(target_filename, 'w')

            # Replace text CRLFs with HTML <br/>s
            File.open(f, 'r') do |l|
              while line = l.gets
                target_file.puts line.gsub(/\r/, '<br/>').gsub(/\n/, '<br/>')
              end
            end
            target_file.close

            f = target_filename
          end

          if is_unix
            system %{xdg-open "#{f}"}
          else
            system %{open "#{f}"}
          end
          sleep 0.5
        end
      end
    end
  end
end
