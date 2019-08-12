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

BuildrPlus::FeatureManager.feature(:idea_codestyle) do |f|
  f.enhance(:Config) do
    def default_codestyle
      'au.com.stocksoftware.idea.codestyle:idea-codestyle:xml:1.14'
    end

    def codestyle
      @codestyle || self.default_codestyle
    end

    attr_writer :codestyle
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|
      if project.ipr?
        project.ipr.add_component_from_artifact(BuildrPlus::IdeaCodestyle.codestyle)

        project.ipr.add_component('JavaProjectCodeInsightSettings') do |xml|
          xml.tag!('excluded-names') do
            xml << '<name>com.sun.istack.internal.NotNull</name>'
            xml << '<name>com.sun.istack.internal.Nullable</name>'
            xml << '<name>org.jetbrains.annotations.Nullable</name>'
            xml << '<name>org.jetbrains.annotations.NotNull</name>'
            xml << '<name>org.testng.AssertJUnit</name>'
          end
        end
        project.ipr.add_component('NullableNotNullManager') do |component|
          component.option :name => 'myDefaultNullable', :value => 'javax.annotation.Nullable'
          component.option :name => 'myDefaultNotNull', :value => 'javax.annotation.Nonnull'
          component.option :name => 'myNullables' do |option|
            option.value do |value|
              value.list :size => '2' do |list|
                list.item :index => '0', :class => 'java.lang.String', :itemvalue => 'org.jetbrains.annotations.Nullable'
                list.item :index => '1', :class => 'java.lang.String', :itemvalue => 'javax.annotation.Nullable'
              end
            end
          end
          component.option :name => 'myNotNulls' do |option|
            option.value do |value|
              value.list :size => '2' do |list|
                list.item :index => '0', :class => 'java.lang.String', :itemvalue => 'org.jetbrains.annotations.NotNull'
                list.item :index => '1', :class => 'java.lang.String', :itemvalue => 'javax.annotation.Nonnull'
              end
            end
          end
        end
      end
    end
  end
end
