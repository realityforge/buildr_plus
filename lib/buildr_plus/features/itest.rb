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

BuildrPlus::FeatureManager.feature(:itest => [:rails]) do |f|
  f.enhance(:ProjectExtension) do
    first_time do
      require 'itest'
    end

    after_define do |project|
      if project.ipr?
        Dir["#{project._('test')}/*"].each do |dir|
          next unless File.directory?(dir)
          basename = File.basename(dir)
          next if basename == 'fixtures'
          ITest.define_test("test/#{basename}/**/*_test.rb", :key => basename.to_sym)
        end
      end
    end
  end
end
