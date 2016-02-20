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
  class SubscribeAction < Action
    # Triggered by a Doctype in a READY state.  The incoming document is unchanged.
    # Can create/edit additional documents of any type or state

    # Doc is an ActionDocument
    def subscribe(doc)
      raise ActionErrors::ActionMethodNotImplemented, 'SubscribeActions must overwrite the subscribe method.'
    end

    # raises InvalidDoctypeError
    def edit(id, doctype_name)
      doctype = @output_doctypes[doctype_name]
      raise ActionErrors::DoctypeError.new "Editing an unknown doctype #{doctype_name}.  Available doctypes are #{@output_doctypes.keys}" if doctype.nil?
      @caller.edit_document(id, doctype) do |external_doc|
        yield external_doc
      end
    end
  end
end
