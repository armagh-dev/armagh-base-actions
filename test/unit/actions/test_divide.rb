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

require_relative '../../../lib/armagh/actions/divide'
require_relative '../../../lib/armagh/actions/collect'

class TestDivide < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @collection = mock
    if Object.const_defined?( :SubCollect )
      Object.send( :remove_const, :SubCollect )
    end
    Object.const_set :SubCollect, Class.new( Armagh::Actions::Collect )
    SubCollect.define_output_docspec( 'bigdocs', 'action description', default_type: 'dansbigdocs', default_state: Armagh::Documents::DocState::READY )

    @config_store = []
    coll_config = SubCollect.create_configuration( @config_store, 'set', {
      'action' => { 'name' => 'mysubcollect' },
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false}
    })
    
    if Object.const_defined?( :SubDivide )
      Object.send( :remove_const, :SubDivide )
    end
    Object.const_set :SubDivide, Class.new( Armagh::Actions::Divide )
    SubDivide.define_default_input_type 'innie'
    SubDivide.define_output_docspec( 'littledocs', 'action description ')

    @config_store = []
    div_config = SubDivide.create_configuration( @config_store, 'set2', {
      'action' => { 'name' => 'mysubdivide' },
      'input'  => { 'doctype' => Armagh::Documents::DocSpec.new( 'dansbigdocs', Armagh::Documents::DocState::READY )},
      'output' => { 'littledocs' => Armagh::Documents::DocSpec.new( 'danslittledocs', Armagh::Documents::DocState::READY )}
    })
    @divide_action = SubDivide.new( @caller, 'logger_name', div_config, @collection)
    
  end 

  def test_unimplemented_divide
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@divide_action.divide(nil)}
  end

  def test_create
    content = {'content' => true}
    meta = {'meta' => true}

    @caller.expects(:create_document)

    @divide_action.source = {}
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

