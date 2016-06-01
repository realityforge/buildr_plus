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

BuildrPlus::FeatureManager.feature(:redfish) do |f|
  f.enhance(:ProjectExtension) do
    first_time do
      require 'redfish'
    end

    before_define do |buildr_project|
      if buildr_project.ipr?
        if Redfish.domain_by_key?("local_#{buildr_project.name}")
          Redfish::Config.default_domain_key = "local_#{buildr_project.name}"
        elsif Redfish.domain_by_key?(buildr_project.name)
          Redfish::Config.default_domain_key = buildr_project.name
        end
      end
    end

    after_define do |buildr_project|
      if buildr_project.ipr?

        if BuildrPlus::FeatureManager.activated?(:domgen) && Redfish.domain_by_key?(buildr_project.name)
          domain = Redfish.domain_by_key(buildr_project.name)
          domain.pre_artifacts << buildr_project._("generated/domgen/#{buildr_project.name}/main/etc/#{buildr_project.name_as_class}.redfish.fragment.json")
          buildr_project.task(":#{domain.task_prefix}:pre_build" => ["#{buildr_project.name}:domgen:#{buildr_project.name}"])
        end

        unless BuildrPlus::Util.subprojects(buildr_project).any? { |p| p == "#{buildr_project.name}:domains" }
          buildr_project.instance_eval do
            desc 'Redfish Domain Definitions'
            define 'domains' do
              Redfish::Buildr.define_domain_packages
            end
          end
        end
      end
    end
  end
end
