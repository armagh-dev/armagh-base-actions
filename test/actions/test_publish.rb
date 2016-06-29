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

require_relative '../../lib/armagh/actions/publish'

class TestPublish < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @output_docspec = Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::PUBLISHED)

    @publish_action = Armagh::Actions::Publish.new('action', @caller, 'logger_name', {}, {'output_type'=> @output_docspec})
  end

  def test_unimplemented_publish
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@publish_action.publish(nil)}
  end

  def test_no_define_input_type
    e = assert_raise(Armagh::Documents::Errors::DocSpecError){Armagh::Actions::Publish.define_input_type 'type'}
    assert_equal('Publish actions have no usable Input doc types.', e.message)
  end

  def test_no_define_output_docspec
    e = assert_raise(Armagh::Documents::Errors::DocSpecError){Armagh::Actions::Publish.define_output_docspec 'type'}
    assert_equal('Publish actions have no usable Output DocSpecs.', e.message)
  end

  def test_validate
    assert_equal({'errors' => [], 'valid' => true, 'warnings' => []}, @publish_action.validate)
  end

  def test_validate_wrong_num_output_docspecs
    output_docspecs = {
        'type1' => @output_docspec,
        'type2' => Armagh::Documents::DocSpec.new('PublishDocument2', Armagh::Documents::DocState::PUBLISHED)
    }
    publish_action = Armagh::Actions::Publish.new('action', @caller, 'logger_name', {}, output_docspecs)
    valid = publish_action.validate
    assert_false valid['valid']
    assert_equal(['PublishActions can only have one output docspec.'], valid['errors'])

    output_docspecs = {}
    publish_action = Armagh::Actions::Publish.new('action', @caller, 'logger_name', {}, output_docspecs)
    valid = publish_action.validate
    assert_false valid['valid']
    assert_equal(['PublishActions can only have one output docspec.'], valid['errors'])
  end

  def test_validate_invalid_out_state
    output_docspec = Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::WORKING)
    publish_action = Armagh::Actions::Publish.new('action', @caller, 'logger_name', {}, {'output_type'=> output_docspec})
    valid = publish_action.validate
    assert_false valid['valid']
    assert_equal(['Output document state for a PublishAction must be published.'], valid['errors'])

    output_docspec = Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::READY)
    publish_action = Armagh::Actions::Publish.new('action', @caller, 'logger_name', {}, {'output_type'=> output_docspec})
    valid = publish_action.validate
    assert_false valid['valid']
    assert_equal(['Output document state for a PublishAction must be published.'], valid['errors'])
  end

  def test_inheritence
    assert_true Armagh::Actions::Publish.respond_to? :define_parameter
    assert_true Armagh::Actions::Publish.respond_to? :defined_parameters

    assert_true Armagh::Actions::Publish.respond_to? :define_input_type
    assert_true Armagh::Actions::Publish.respond_to? :defined_input_type
    assert_true Armagh::Actions::Publish.respond_to? :define_output_docspec
    assert_true Armagh::Actions::Publish.respond_to? :defined_output_docspecs

    assert_true @publish_action.respond_to? :validate

    assert_true @publish_action.respond_to? :log_debug
    assert_true @publish_action.respond_to? :log_info
    assert_true @publish_action.respond_to? :notify_dev
    assert_true @publish_action.respond_to? :notify_ops
  end
end
