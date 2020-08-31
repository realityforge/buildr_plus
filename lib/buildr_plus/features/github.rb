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

# Enable this feature if the code is hosted in public github server
BuildrPlus::FeatureManager.feature(:github) do |f|
  f.enhance(:Config) do
    attr_writer :enable_github_actions

    def enable_github_actions?
      @enable_github_actions.nil? ? true : !!@enable_github_actions
    end

    def generate_github_actions
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      automerge = "#{base_directory}/.github/workflows/automerge.yml"
      FileUtils.mkdir_p File.dirname(automerge)
      IO.write(automerge, automerge_content)
    end

    def remove_github_actions
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      automerge = "#{base_directory}/.github/workflows/automerge.yml"
      FileUtils.rm_f automerge
    end

    def check_github_actions
      base_directory = File.dirname(Buildr.application.buildfile.to_s)
      automerge = "#{base_directory}/.github/workflows/automerge.yml"
      exists = File.exist?(automerge)
      if !enable_github_actions? && exists
        puts 'Github automerge action present but actions disabled'
        return false
      elsif enable_github_actions? && (!exists || IO.read(automerge) != automerge_content)
        puts 'Github automerge action is not uptodate'
        return false
      end
      true
    end

    private

    def automerge_content
      <<CONTENT
# DO NOT EDIT: File is auto-generated
name: automerge
on:
  pull_request:
    types:
      - labeled
      - unlabeled
      - synchronize
      - opened
      - edited
      - ready_for_review
      - reopened
      - unlocked
  pull_request_review:
    types:
      - submitted
  status: {}
jobs:
  automerge:
    runs-on: ubuntu-latest
    steps:
      - name: automerge
        uses: "pascalgn/automerge-action@a4b03eff945989d41c623c2784d6602560b91e5b"
        env:
          # see https://github.com/marketplace/actions/merge-pull-requests#configuration for more configuration options
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
          # Only merge if automerge label is present and wip label is not present
          MERGE_LABELS: "automerge,!wip"
CONTENT
    end
  end

  f.enhance(:ProjectExtension) do
    desc 'Check Github actions are configured.'
    task 'github:check' do
      unless BuildrPlus::Github.check_github_actions
        raise 'Github actions are not correctly configured. Please run "buildr github:fix" and commit changes.'
      end
    end

    desc 'Configure Github actions.'
    task 'github:fix' do
      if BuildrPlus::Github.enable_github_actions?
        BuildrPlus::Github.generate_github_actions
      else
        BuildrPlus::Github.remove_github_actions
      end
    end
  end
end
