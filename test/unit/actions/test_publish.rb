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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/actions/publish'

class TestPublish < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    if Object.const_defined?( :SubPublish )
      Object.send( :remove_const, :SubPublish )
    end
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
    SubPublish.define_default_input_type 'randomdoc'
    SubPublish.define_output_docspec( 'type', 'published doctype', default_type: 'randomdoc', default_state: Armagh::Documents::DocState::PUBLISHED )
    @config_store = []
    config = SubPublish.create_configuration( @config_store, 'set', {
      'action' => { 'name' => 'mySubPublish' }
      })
    
    @publish_action = SubPublish.new( @caller, 'logger_name', config )
  end

  def test_unimplemented_publish
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@publish_action.publish(nil)}
  end

  def test_validate_wrong_num_output_docspecs
    if Object.const_defined?( :SubPublish )
      Object.send( :remove_const, :SubPublish )
    end
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
    SubPublish.define_default_input_type 'randomdoc'
    SubPublish.define_output_docspec( 'type1', 'published doctype', default_type: 'randomdoc', default_state: Armagh::Documents::DocState::PUBLISHED )
    SubPublish.define_output_docspec( 'type2', 'published doctype', default_type: 'randomdoc', default_state: Armagh::Documents::DocState::PUBLISHED )
    e = assert_raises( Configh::ConfigInitError) {
      config = SubPublish.create_configuration( @config_store, 'wnop', { 'action' => { 'name' => 'mySubPublish' } })
    }
    assert_equal "Unable to create configuration SubPublish wnop: Publish actions must have exactly one output type", e.message
    
  
    Object.send( :remove_const, :SubPublish )
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
    SubPublish.define_default_input_type 'randomdoc'
     e = assert_raises( Configh::ConfigInitError) {
      config = SubPublish.create_configuration( @config_store, 'whop', { 'action' => { 'name' => 'mySubPublish' } })
    }
    assert_equal "Unable to create configuration SubPublish whop: Publish actions must have exactly one output type", e.message
  end

  def test_validate_invalid_out_state
 
    if Object.const_defined?( :SubPublish )
      Object.send( :remove_const, :SubPublish )
    end
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
    SubPublish.define_default_input_type 'randomdoc'
    SubPublish.define_output_docspec( 'type1', 'published doctype', default_type: 'randomdoc', default_state: Armagh::Documents::DocState::WORKING )
    e = assert_raises( Configh::ConfigInitError) {
      config = SubPublish.create_configuration( @config_store, 'vios', { 'action' => { 'name' => 'mySubPublish' } })
    }
    assert_equal "Unable to create configuration SubPublish vios: Output document state for a Publish action must be published.", e.message
    
  
    Object.send( :remove_const, :SubPublish )
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
    SubPublish.define_default_input_type 'randomdoc'
    SubPublish.define_output_docspec( 'type1', 'published doctype', default_type: 'randomdoc', default_state: Armagh::Documents::DocState::READY )
     e = assert_raises( Configh::ConfigInitError) {
      config = SubPublish.create_configuration( @config_store, 'vios2', { 'action' => { 'name' => 'mySubPublish' } })
    }
    assert_equal "Unable to create configuration SubPublish vios2: Action can't have same doc specs as input and output,Output document state for a Publish action must be published.", e.message
  end

  def test_get_existing_published_document
    docspec = Armagh::Documents::DocSpec.new('PublishDocument', Armagh::Documents::DocState::WORKING)
    doc = Armagh::Documents::ActionDocument.new(document_id: 'id', content: {'content' => 'old'}, metadata: {'meta' => 'old'},
                                                 docspec: docspec, source: {}, new: true)

    @caller.expects(:get_existing_published_document).with(doc)
    @publish_action.get_existing_published_document doc
  end

  def test_inheritence
    assert_true SubPublish.respond_to? :define_parameter
    assert_true SubPublish.respond_to? :defined_parameters

    assert_true SubPublish.respond_to? :define_default_input_type
    assert_true SubPublish.respond_to? :define_output_docspec

    assert_true @publish_action.respond_to? :log_debug
    assert_true @publish_action.respond_to? :log_info
    assert_true @publish_action.respond_to? :notify_dev
    assert_true @publish_action.respond_to? :notify_ops
  end
end
