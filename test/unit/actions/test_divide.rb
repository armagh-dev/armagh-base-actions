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

require_relative '../../../lib/armagh/actions/divide'
require_relative '../../../lib/armagh/actions/collect'

class TestDivide < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    if Object.const_defined?( :SubCollect )
      Object.send( :remove_const, :SubCollect )
    end
    Object.const_set :SubCollect, Class.new( Armagh::Actions::Collect )
    SubCollect.define_output_docspec( 'bigdocs', 'action description', default_type: 'dansbigdocs', default_state: Armagh::Documents::DocState::READY )

    @config_store = []
    coll_config = SubCollect.create_configuration( @config_store, 'set', {
      'action' => { 'name' => 'mysubcollect', 'workflow' => 'wf' },
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    if Object.const_defined?( :SubDivide )
      Object.send( :remove_const, :SubDivide )
    end
    Object.const_set :SubDivide, Class.new( Armagh::Actions::Divide )
    SubDivide.define_default_input_type 'innie'


    @config_store = []
    div_config = SubDivide.create_configuration( @config_store, 'set2', {
      'action' => { 'name' => 'mysubdivide', 'workflow' => 'wf' },
      'input'  => { 'docspec' => Armagh::Documents::DocSpec.new( 'dansbigdocs', Armagh::Documents::DocState::READY )},
      'output' => { 'docspec' => Armagh::Documents::DocSpec.new( 'danslittledocs', Armagh::Documents::DocState::READY )}
    })

    @divide_action = SubDivide.new( @caller, 'logger_name', div_config)

  end

  def test_unimplemented_divide
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@divide_action.divide(nil)}
  end
  
  def test_output_docspec_not_defined
    Object.const_set :BadSubDivide, Class.new( Armagh::Actions::Divide )
    BadSubDivide.define_default_input_type 'innie'
    e = assert_raises( Configh::ConfigInitError ) do
      div_config = BadSubDivide.create_configuration( @config_store, 'set2', {
        'action' => { 'name' => 'mysubdivide', 'workflow' => 'wf' },
        'input'  => { 'docspec' => Armagh::Documents::DocSpec.new( 'dansbigdocs', Armagh::Documents::DocState::READY )}
      })
      @divide_action = BadSubDivide.new( @caller, 'logger_name', div_config, @collection)
    end
    assert_equal "Unable to create configuration for 'BadSubDivide' named 'set2' because: \n    Group 'output' Parameter 'docspec': type validation failed: value cannot be nil", e.message
  end

  def test_too_many_output_docspecs
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubDivide' named 'set3' because: \n    Divide actions must have exactly one output docspec.")

    assert_raise(e) do
      SubDivide.define_output_docspec 'docspec2', 'another output docspec'

      SubDivide.create_configuration(@config_store, 'set3', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY)},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('danslittledocs', Armagh::Documents::DocState::READY),
          'docspec2' => Armagh::Documents::DocSpec.new('danslittledocs2', Armagh::Documents::DocState::READY),
        }
      })
    end
  end

  def test_no_out_spec
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubDivide' named 'set4' because: \n    Group 'output' Parameter 'docspec': type validation failed: value cannot be nil")

    assert_raise(e) do
      SubDivide.create_configuration(@config_store, 'set4', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY)},
      })
    end
  end

  def test_no_in_spec
    Object.send(:remove_const, :SubDivide) if Object.const_defined?(:SubDivide)
    Object.const_set :SubDivide, Class.new( Armagh::Actions::Divide )

    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubDivide' named 'set5' because: \n    Group 'input' Parameter 'docspec': type validation failed: value cannot be nil")

    assert_raise(e) do
      SubDivide.create_configuration(@config_store, 'set5', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('danslittledocs', Armagh::Documents::DocState::READY),
        }
      })
    end
  end

  def test_invalid_in_spec
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubDivide' named 'set6' because: \n    Input docspec 'docspec' state must be ready.")

    assert_raise(e) do
      SubDivide.create_configuration(@config_store, 'set6', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::PUBLISHED)},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('danslittledocs', Armagh::Documents::DocState::READY),
        }
      })
    end
  end

  def test_invalid_out_spec
    e = Configh::ConfigInitError.new("Unable to create configuration for 'SubDivide' named 'set7' because: \n    Output docspec 'docspec' state must be one of: ready, working.")

    assert_raise(e) do
      SubDivide.create_configuration(@config_store, 'set7', {
        'action' => {'name' => 'mysubdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('dansbigdocs', Armagh::Documents::DocState::READY)},
        'output' => {
          'docspec' => Armagh::Documents::DocSpec.new('danslittledocs', Armagh::Documents::DocState::PUBLISHED),
        }
      })
    end
  end

  def test_valid_out_spec
    assert_nothing_raised do
      SubDivide.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'subdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('randomdoc', Armagh::Documents::DocState::READY)},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })

      SubDivide.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'subdivide', 'workflow' => 'wf'},
        'input' => {'docspec' => Armagh::Documents::DocSpec.new('randomdoc', Armagh::Documents::DocState::READY)},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::WORKING)}
      })
    end
  end

  def test_create
    content = "some content"
    meta = {'meta' => true}

    @caller.expects(:create_document)

    @divide_action.doc_details = {}
    @divide_action.create(content, meta)
  end

  def test_inheritence
    assert_true SubDivide.respond_to? :define_parameter
    assert_true SubDivide.respond_to? :defined_parameters

    assert_true @divide_action.respond_to? :log_debug
    assert_true @divide_action.respond_to? :log_info
    assert_true @divide_action.respond_to? :notify_dev
    assert_true @divide_action.respond_to? :notify_ops
  end
end

