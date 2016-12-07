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

BuildrPlus::FeatureManager.feature(:resgen) do |f|
  f.enhance(:ProjectExtension) do

    def additional_resgen_generators
      @additional_resgen_generators ||= []
    end

    first_time do
      require 'resgen'

      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      candidate_file = File.expand_path("#{base_directory}/#{Resgen::Build::DEFAULT_RESOURCES_FILENAME}")

      Resgen::Build.define_load_task if ::File.exist?(candidate_file)

      task('resgen:postload') do
        facet_mapping =
          {
            :gwt => :gwt,
          }

        Resgen.repositories.each do |r|
          facet_mapping.each_pair do |buildr_plus_facet, resgen_facet|
            if BuildrPlus::FeatureManager.activated?(buildr_plus_facet) && !r.facet_enabled?(resgen_facet)
              raise "BuildrPlus feature '#{buildr_plus_facet}' requires that resgen facet '#{resgen_facet}' is enabled but it is not."
            end
            if !BuildrPlus::FeatureManager.activated?(buildr_plus_facet) && r.facet_enabled?(resgen_facet)
              raise "Resgen facet '#{resgen_facet}' requires that buildrPlus feature '#{buildr_plus_facet}' is enabled but it is not."
            end
          end
        end
      end
    end
  end
end
