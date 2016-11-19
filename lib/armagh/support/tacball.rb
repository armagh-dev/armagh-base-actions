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
require 'configh'

module Armagh
  module Support
    module Tacball
      include Configh::Configurable

      class TacballError < StandardError; end
      class FieldTypeError < TacballError; end
      class InvalidDocidError < TacballError; end
      class InvalidFeedError < TacballError; end
      class AttachmentOrOriginalExtnError < TacballError; end
      class OriginalFileAndExtensionError < TacballError; end
 
      define_parameter name: 'feed',
                       description: "TACBall Document Feed Name. Must be in format #{TAC::VALID_FEED_REGEX}",
                       type: 'string',
                       required: true,
                       group: 'tacball'

      define_parameter name: 'source',
                       description: 'TACBall Document Source Name',
                       type: 'string',
                       required: true,
                       group: 'tacball'
         
      module_function

      def create_tacball_file(
        config,
        docid:,
        dateposted: nil,
        title:,
        timestamp:,
        hastext: false,
        originaltype: '',
        data_repository: '',
        txt_content: '',
        copyright: '',
        html_content: '',
        inject_html: false,
        basename:,
        output_path: '.',
        logger:
      )
        begin
          TAC.logger = logger
          TAC.create_tacball_file(
            docid: docid,
            dateposted: dateposted,
            title: title,
            feed: config.tacball.feed,
            timestamp: timestamp,
            hastext: hastext,
            source: config.tacball.source,
            originaltype: originaltype,
            data_repository: data_repository,
            txt_content: txt_content,
            copyright: copyright,
            html_content: html_content,
            inject_html: inject_html,
            basename: basename,
            output_path: output_path
          )
        rescue TAC::FieldTypeError => e
          raise FieldTypeError, e.message
        rescue TAC::InvalidDocidError => e
          raise InvalidDocidError, e.message
        rescue TAC::InvalidFeedError => e
          raise InvalidFeedError, e.message
        rescue TAC::AttachmentOrOriginalExtnError => e
          raise AttachmentOrOriginalExtnError, e.message
        rescue TAC::OriginalFileAndExtensionError => e
          raise OriginalFileAndExtensionError, e.message
        end
      end

    end
  end
end
