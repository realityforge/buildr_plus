# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

raise 'Patch applied in latest release of buildr' if Buildr::VERSION > '1.4.24'

module Buildr::GWT::ProjectExtension

  def gwt(module_names, options = {})
    p = options[:target_project]
    target_project = p.nil? ? project : p.is_a?(String) ? project(p) : p
    output_key = options[:output_key] || project.id
    output_dir = project._(:target, :generated, :gwt, output_key)
    artifacts = ([project.compile.target] + project.compile.sources + project.resources.sources).flatten.compact.collect do |a|
      a.is_a?(String) ? file(a) : a
    end
    dependencies = options[:dependencies] ? artifacts(options[:dependencies]) : (project.compile.dependencies + [project.compile.target]).flatten.compact.collect do |dep|
      dep.is_a?(String) ? file(dep) : dep
    end

    unit_cache_dir = project._(:target, :gwt, :unit_cache_dir, output_key)

    version = gwt_detect_version(dependencies) || Buildr::GWT.version

    additional_gwt_deps = []
    existing_deps = project.compile.dependencies.collect do |d|
      a = artifact(d)
      a.invoke if a.is_a?(Buildr::Artifact)
      a.to_s
    end
    Buildr::GWT.dependencies(version).each do |d|
      a = artifact(d)
      a.invoke if a.respond_to?(:invoke)
      # The next two lines are patched
      project.iml.main_dependencies << a unless !project.iml? || existing_deps.include?(a.to_s)
      project.compile.dependencies << a unless existing_deps.include?(a.to_s)
      additional_gwt_deps << a
    end

    task = project.file(output_dir) do
      Buildr::GWT.gwtc_main(module_names,
                            (dependencies + artifacts + additional_gwt_deps).flatten.compact,
                            output_dir,
                            unit_cache_dir,
                            {:version => version}.merge(options))
    end
    task.enhance(dependencies)
    task.enhance([project.compile])
    target_project.assets.paths << task
    task
  end
end
