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
  class PublishAction < Action
    # Triggered by DocType:ready
    # Content within doc is committed to a finalized state of the document
    # Can create/edit additional documents of any type or state

    def self.define_input_doctype(name, default_type: nil, default_state: nil)
      raise ActionErrors::DoctypeError.new 'Publish actions have no usable Input Doctypes.'
    end

    def self.define_output_doctype(name, default_type: nil, default_state: nil)
      raise ActionErrors::DoctypeError.new 'Publish actions have no usable Output Doctypes.'
    end

    # Doc is an ActionDocument
    def publish(doc)
      raise ActionErrors::ActionMethodNotImplemented, 'PublishActions must overwrite the publish method.'
    end

    def valid?
      valid = true
      valid &&= super

      if @input_doctypes.length != 1
        valid = false
        @validation_errors['input_doctypes'] ||= {}
        @validation_errors['input_doctypes']['_all'] = 'PublishActions can only have one input doctype.'
      end

      if @output_doctypes.length != 1
        valid = false
        @validation_errors['output_doctypes'] ||= {}
        @validation_errors['output_doctypes']['_all'] = 'PublishActions can only have one output doctype.'
      end

      input = @input_doctypes.first
      output = @output_doctypes.first

      if input && output && input.last.type != output.last.type
        valid = false
        @validation_errors['all_doctypes'] ||= []
        @validation_errors['all_doctypes'] << 'PublishActions must use the same doctype for input and output.'
      end

      if input && input.last.state != DocState::READY
        valid = false
        @validation_errors['input_doctypes'] ||= {}
        @validation_errors['input_doctypes'][input.first] = "Input document state for a PublishAction must be #{DocState::READY}."
      end

      if output && output.last.state != DocState::PUBLISHED
        valid = false
        @validation_errors['output_doctypes'] ||= {}
        @validation_errors['output_doctypes'][output.first] = "Output document state for a PublishAction must be #{DocState::PUBLISHED}."
      end
      valid
    end
  end
end
