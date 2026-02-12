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

class Buildr::Project

  def name_as_class
    Reality::Naming.pascal_case(project.name)
  end

  attr_writer :java_package_name

  def java_package_name?
    !@java_package_name.nil?
  end

  def java_package_name
    @java_package_name || group_as_package
  end

  def group_as_package
    project.group
  end

  def group_as_path
    project.group.gsub('.', '/')
  end
end
