# Copyright 2018 Noragh Analytics, Inc.
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

require_relative '../documents/action_document'

module Armagh
  module Support
    module DocAttr

      def get_doc_attr(doc_or_content, hpath)
        content = (doc_or_content.is_a? Armagh::Documents::ActionDocument) ? doc_or_content.content : doc_or_content
        dig_first(content, hpath)
      end

      def dig_first(node, hpath, idx = 0)
        return nil   if node.nil? || hpath.nil? || hpath.empty?
        return node  if idx >= hpath.length

        key = hpath[idx]

        if node.is_a? Hash
          return dig_first(node[key], hpath, idx+1)
        elsif node.is_a? Array
          ## handle Arrays differently than the build-in Array.dig
          ## if key is not an integer String, "skip over" Array and
          ## try each Array element to find first match for key
          begin
            return dig_first(node[Integer(key)], hpath, idx+1)
          rescue
            ## key is not an integer String
            new_node = nil
            node.each do |elem|
              new_node = dig_first(elem, hpath, idx)  ## this key
              break  unless new_node.nil?
            end
            return new_node
          end
        end

        return nil
      end

    end
  end
end
