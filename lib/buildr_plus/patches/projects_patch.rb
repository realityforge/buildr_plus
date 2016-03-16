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

raise 'Patch applied in latest release of buildr' if Buildr::VERSION > '1.4.23'

class Buildr::Project
  class << self
    def projects(*names) #:nodoc:
      options = names.pop if Hash === names.last
      rake_check_options options, :scope, :no_invoke if options

      no_invoke = options && options[:no_invoke]

      @projects ||= {}
      names = names.flatten
      if options && options[:scope]
        # We assume parent project is evaluated.
        if names.empty?
          parent = @projects[options[:scope].to_s] or raise "No such project #{options[:scope]}"
          @projects.values.select { |project| project.parent == parent }.each { |project| project.invoke unless no_invoke }.
            map { |project| [project] + projects(:scope => project, :no_invoke => no_invoke) }.flatten.sort_by(&:name)
        else
          names.uniq.map { |name| project(name, :scope => options[:scope], :no_invoke => no_invoke) }
        end
      elsif names.empty?
        # Parent project(s) not evaluated so we don't know all the projects yet.
        @projects.values.each { |project| project.invoke unless no_invoke }
        @projects.keys.map { |name| project(name, :no_invoke => no_invoke) or raise "No such project #{name}" }.sort_by(&:name)
      else
        # Parent project(s) not evaluated, for the sub-projects we may need to find.
        names.map { |name| name.split(':') }.select { |name| name.size > 1 }.map(&:first).uniq.each { |name| project(name, :no_invoke => no_invoke) }
        names.uniq.map { |name| project(name, :no_invoke => no_invoke) or raise "No such project #{name}" }.sort_by(&:name)
      end
    end

    # :call-seq:
    #   project(name) => project
    #
    # See Buildr#project.
    def project(*args, &block) #:nodoc:
      options = args.pop if Hash === args.last
      return define(args.first, options, &block) if block
      rake_check_options options, :scope, :no_invoke if options
      no_invoke = options && options[:no_invoke]

      raise ArgumentError, 'Only one project name at a time' unless args.size == 1
      @projects ||= {}
      name = args.first.to_s
      # Make sure parent project is evaluated (e.g. if looking for foo:bar, find foo first)
      unless @projects[name]
        parts = name.split(':')
        project(parts.first, options || {}) if parts.size > 1
      end
      if options && options[:scope]
        # We assume parent project is evaluated.
        project = options[:scope].split(':').inject([[]]) { |scopes, scope| scopes << (scopes.last + [scope]) }.
          map { |scope| @projects[(scope + [name]).join(':')] }.
          select { |project| project }.last
      end
      project ||= @projects[name] # Not found in scope.
      raise "No such project #{name}" unless project
      project.invoke unless no_invoke || Buildr.application.current_scope.join(":").to_s == project.name.to_s
      project
    end
  end
end
