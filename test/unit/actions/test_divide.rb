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
    if Object.const_defined?( :SubCollect )
      Object.send( :remove_const, :SubCollect )
    end
    Object.const_set :SubCollect, Class.new( Armagh::Actions::Collect )
    SubCollect.include Configh::Configurable
    SubCollect.define_output_docspec( 'output_type', 'action description', default_type: 'type', default_state: Armagh::Documents::DocState::WORKING )
    config = SubCollect.use_static_config_values ( {
      'action' => { 'name' => 'mysubcollect' },
      'input'  => { 'doctype' => 'randomdoc' }
      })
    
    @divider = Armagh::Actions::Divide.new( @caller, 'logger_name', config, config.output.output_type )
  end

  def test_unimplemented_divide
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@divider.divide(nil)}
  end

  def test_create
    content = {'content' => true}
    meta = {'meta' => true}

    @caller.expects(:create_document)

    @divider.source = {}
    @divider.create(content, meta)
  end

  def test_inheritence
    assert_true Armagh::Actions::Divide.respond_to? :define_parameter
    assert_true Armagh::Actions::Divide.respond_to? :defined_parameters

    assert_true @divider.respond_to? :log_debug
    assert_true @divider.respond_to? :log_info
    assert_true @divider.respond_to? :notify_dev
    assert_true @divider.respond_to? :notify_ops
  end
end

