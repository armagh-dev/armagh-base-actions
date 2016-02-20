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

require_relative 'action'

module Armagh
  class CollectionSplitter < Parameterized
    # Splits a collected document before storing for processing.  This is an optional component that runs on each document after a collect.  May be useful
    #  for dividing up work or handling files that are too large to store in Mongo.

    def initialize(caller, logger, parameters, output_doctype)
      super()
      @caller = caller
      @logger = logger
      @parameters = parameters
      @output_doctype = output_doctype
    end

    # Doc is a CollectedDocument
    def split(doc)
      raise ActionErrors::ActionMethodNotImplemented, 'CollectionSplitterActions must overwrite the split method.'
    end

    # raises InvalidDoctypeError
    def create(id=nil, draft_content, meta)
      action_doc = ActionDocument.new(id, draft_content, {}, meta, @output_doctype)
      @caller.create_document(action_doc)
    end
  end
end

