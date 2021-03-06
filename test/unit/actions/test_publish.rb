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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/actions/publish'

class TestPublish < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @collection = mock
    if Object.const_defined?( :SubPublish )
      Object.send( :remove_const, :SubPublish )
    end
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
    @config_store = []
    @config = SubPublish.create_configuration( @config_store, 'set', {
      'action' => { 'name' => 'mySubPublish', 'workflow' => 'wf' },
      'input'  => { 'docspec' => 'the_doctype:ready' },
      'output' => { 'docspec' => 'the_doctype:published' }
      })
    
    @publish_action = SubPublish.new( @caller, 'logger_name', @config )
  end

  def test_unimplemented_publish
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@publish_action.publish(nil)}
  end

  def test_validate_wrong_num_output_docspecs
    if Object.const_defined?( :SubPublish )
      Object.send( :remove_const, :SubPublish )
    end
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
    e = assert_raises( Armagh::Actions::ConfigurationError ) {
      SubPublish.define_output_docspec( 'type', 'published doctype', default_type: 'randomdoc', default_state: Armagh::Documents::DocState::PUBLISHED )
    }
    assert_equal "The output docspec is already defined for you in a publish action.", e.message
    
  
    Object.send( :remove_const, :SubPublish )
    Object.const_set :SubPublish, Class.new( Armagh::Actions::Publish )
     e = assert_raises( Armagh::Actions::ConfigurationError ) {
       SubPublish.define_default_input_type 'randomdoc'
    }
    assert_equal "The input docspec is already defined for you in a publish action.", e.message
  end

  def test_no_out_spec
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubPublish' named 'set2' because: \n    Group 'output' Parameter 'docspec': type validation failed: value cannot be nil")
    assert_raise(e) do
      SubPublish.create_configuration(@config_store, 'set2', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY)},
        'output' => {
        }
      })
    end
  end

  def test_no_in_spec
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubPublish' named 'set2' because: \n    Group 'input' Parameter 'docspec': type validation failed: value cannot be nil")
    assert_raise(e) do
      SubPublish.create_configuration(@config_store, 'set2', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::PUBLISHED),
        }
      })
    end
  end

  def test_invalid_in_spec
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubPublish' named 'set2' because: \n    Input docspec 'docspec' state must be ready.")
    assert_raise(e) do
      SubPublish.create_configuration(@config_store, 'set2', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::WORKING)},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::PUBLISHED),
        }
      })
    end
  end

  def test_invalid_out_spec
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubPublish' named 'set2' because: \n    Output docspec 'docspec' state must be one of: published.")
    assert_raise(e) do
      SubPublish.create_configuration(@config_store, 'set2', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY)},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::WORKING),
        }
      })
    end
  end

  def test_same_in_out_spec
    e = assert_raise do
      SubPublish.create_configuration(@config_store, 'set2', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY)},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY),
        }
      })

      assert_true e.message.include?("Action can't have same doc specs as input and output.")
    end
  end

  def test_diff_out_types
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubPublish' named 'set2' because: \n    Input doctype (dansbigdocs) and output doctype (dansbigdocs2) must be the same for Publish actions")
    assert_raise(e) do
      SubPublish.create_configuration(@config_store, 'set2', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY)},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs2', Armagh::Documents::DocState::PUBLISHED),
        }
      })
    end
  end

  def test_get_existing_published_document
    doc = Armagh::Documents::ActionDocument.new(
             document_id: 'id', content: {'content' => 'old'}, raw: 'old', metadata: {'meta' => 'old'},
             docspec: @config.output.docspec, source: {}, new: true, title: 'title', copyright: 'copyright', document_timestamp: Time.at(0).utc)

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
