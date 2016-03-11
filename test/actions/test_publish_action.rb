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


require_relative '../coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../lib/armagh/actions/publish_action'

class TestPublishActon < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @output_docspec = Armagh::DocSpec.new('PublishDocument', Armagh::DocState::PUBLISHED)

    @publish_action = Armagh::PublishAction.new('action', @caller, @logger, {}, {'output_type'=> @output_docspec})
  end

  def test_unimplemented_publish
    assert_raise(Armagh::ActionErrors::ActionMethodNotImplemented) {@publish_action.publish(nil)}
  end

  def test_no_define_input_type
    e = assert_raise(Armagh::ActionErrors::DocSpecError){Armagh::PublishAction.define_input_type 'type'}
    assert_equal('Publish actions have no usable Input doc types.', e.message)
  end

  def test_no_define_output_docspec
    e = assert_raise(Armagh::ActionErrors::DocSpecError){Armagh::PublishAction.define_output_docspec 'type'}
    assert_equal('Publish actions have no usable Output DocSpecs.', e.message)
  end

  def test_valid
    assert_true @publish_action.valid?
    assert_empty @publish_action.validation_errors
  end

  def test_valid_wrong_num_output_docspecs
    output_docspecs = {
        'type1' => @output_docspec,
        'type2' => Armagh::DocSpec.new('PublishDocument2', Armagh::DocState::PUBLISHED)
    }
    publish_action = Armagh::PublishAction.new('action', @caller, @logger, {}, output_docspecs)
    assert_false publish_action.valid?
    assert_equal({'_all' => 'PublishActions can only have one output docspec.'}, publish_action.validation_errors['output_docspecs'])

    output_docspecs = {}
    publish_action = Armagh::PublishAction.new('action', @caller, @logger, {}, output_docspecs)
    assert_false publish_action.valid?
    assert_equal({'_all' => 'PublishActions can only have one output docspec.'}, publish_action.validation_errors['output_docspecs'])
  end

  def test_valid_invalid_out_state
    output_docspec = Armagh::DocSpec.new('PublishDocument', Armagh::DocState::WORKING)
    publish_action = Armagh::PublishAction.new('action', @caller, @logger, {}, {'output_type'=> output_docspec})
    assert_false publish_action.valid?
    assert_equal({'output_type' => 'Output document state for a PublishAction must be published.'}, publish_action.validation_errors['output_docspecs'])

    output_docspec = Armagh::DocSpec.new('PublishDocument', Armagh::DocState::READY)
    publish_action = Armagh::PublishAction.new('action', @caller, @logger, {}, {'output_type'=> output_docspec})
    assert_false publish_action.valid?
    assert_equal({'output_type' => 'Output document state for a PublishAction must be published.'}, publish_action.validation_errors['output_docspecs'])
  end

  def test_inheritence
    assert_true Armagh::PublishAction.respond_to? :define_parameter
    assert_true Armagh::PublishAction.respond_to? :defined_parameters

    assert_true Armagh::PublishAction.respond_to? :define_input_type
    assert_true Armagh::PublishAction.respond_to? :defined_input_type
    assert_true Armagh::PublishAction.respond_to? :define_output_docspec
    assert_true Armagh::PublishAction.respond_to? :defined_output_docspecs

    assert_true @publish_action.respond_to? :valid?
    assert_true @publish_action.respond_to? :validate
  end
end
