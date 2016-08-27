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

require 'ox'
require 'armagh/actions'
Dir[File.join(__dir__, File.basename(__FILE__, ".*"), "*.rb")].each { |file| require file }

require 'configh'

module Armagh
  module Support
    module XML
      extend XML::Divider
      extend XML::Parser

      module_function

      def to_hash(xml, text_nodes = nil)
        Parser.to_hash(xml, text_nodes)
      end

      def file_to_hash(xml, text_nodes = nil)
        Parser.file_to_hash(xml, text_nodes)
      end

      def html_to_hash(html)
        Parser.html_to_hash(html)
      end

    end
  end
end
