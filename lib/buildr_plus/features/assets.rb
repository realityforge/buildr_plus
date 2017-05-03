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

BuildrPlus::FeatureManager.feature(:assets) do |f|
  f.enhance(:Config) do

    attr_writer :allow_bad_fonts

    def allow_bad_fonts?
      @allow_bad_fonts.nil? ? false : !!@allow_bad_fonts
    end
  end

  f.enhance(:ProjectExtension) do
    after_define do |project|
      t = project.task 'assets:check' do
        ([project._(:source, :main, :webapp)] + project.assets.paths).each do |path|
          unless BuildrPlus::Assets.allow_bad_fonts?
            ttf_files = Dir.glob("#{path}/**/*.ttf")
            eot_files = Dir.glob("#{path}/**/*.eot")
            woff2_files = Dir.glob("#{path}/**/*.woff2")
            woff_files = Dir.glob("#{path}/**/*.woff")
            svg_files = (ttf_files + eot_files + woff2_files + woff_files).collect do |f|
              svg_file = "#{File.dirname(f)}/#{File.basename(f, '.*')}.svg"
              File.exist?(svg_file) ? svg_file : nil
            end.compact

            bad_font_files = ttf_files + eot_files + svg_files
            if bad_font_files.size > 0
              BuildrPlus.error <<TEXT
The project has found to be using font files that go against best practices.
Ideally the only font files that should be used are the WOFF 2.0 variant for
browsers that support it and WOFF for all other browsers. For an explanation
of the reasoning see:

https://developers.google.com/web/fundamentals/performance/optimizing-content-efficiency/webfont-optimization
http://caniuse.com/#feat=woff
http://caniuse.com/#feat=woff2

The following font files should be removed. Do not forget to update the
@font-face declarations in any css files to remove references to files.

#{bad_font_files.collect { |f| "* #{f}" }.join("\n")}
TEXT
            end
          end
        end
      end
      project.task(':assets:check').enhance([t.name])
    end

    desc 'Check the assets conform to our constraints'
    task 'assets:check'
  end
end
