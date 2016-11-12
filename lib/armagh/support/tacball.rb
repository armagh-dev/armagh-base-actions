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

require 'tac'

module Armagh
  module Support
    module Tacball

      class TacballDataTypeError < StandardError; end

      module_function

      def create_tacball_file(
        docid:,
        dateposted: nil,
        title:,
        feed:,
        timestamp:,
        hastext: '',
        source: '',
        originaltype: '',
        data_repository: '',
        txt_content: '',
        copyright: '',
        html_content: '',
        inject_html: '',
        basename:,
        output_path: '',
        logger:
      )
        begin
          TAC.logger = logger
          TAC.create_tacball_file(
            docid: docid,
            dateposted: dateposted,
            title: title,
            feed: feed,
            timestamp: timestamp,
            hastext: hastext,
            source: source,
            originaltype: originaltype,
            data_repository: data_repository,
            txt_content: txt_content,
            copyright: copyright,
            html_content: html_content,
            inject_html: inject_html,
            basename: basename,
            output_path: output_path
          )
        rescue TAC::TacballDataTypeError => e
          raise TacballDataTypeError, e.message
        end
      end

    end
  end
end
