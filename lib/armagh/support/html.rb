# Copyright 2016 Noragh Analytics, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either 
# express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Armagh
  module Support
    module HTML
      module_function

      HTML_TO_TEXT_SHELL = %w(w3m -T text/html -cols 10000 -O UTF-8 -o display_link_num=true -o alt_entity=false)

      def to_text(html, force_breaks: false)
        html.gsub!(/&apos;/i, "'")
        html.gsub!(/<sup>|<\/sup>/i, '')
        html.gsub!(/\n/, '<br \>') if force_breaks

        Shell.call_with_input(HTML_TO_TEXT_SHELL, html)

      rescue Shell::ShellError => e
        if e.message.include? "No such file or directory - #{HTML_TO_TEXT_SHELL.first}"
          raise Shell::MissingProgramError, "Missing required #{HTML_TO_TEXT_SHELL.first} program, please make sure it is installed"
        else
          raise e
        end
      end
    end
  end
end
