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
require 'fakefs/safe'

require_relative '../../lib/armagh/actions'

class TestCollectAction < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @output_docspec = Armagh::DocSpec.new('OutputDocument', Armagh::DocState::READY)
    @content = 'collected content'
    @collect_action = Armagh::CollectAction.new('action', @caller, @logger, {}, {'output_type'=> @output_docspec})

  end

  def test_unimplemented_collect
    assert_raise(Armagh::ActionErrors::ActionMethodNotImplemented) {@collect_action.collect}
  end

  def test_create_no_splitter
    @caller.expects(:get_splitter).returns(nil)
    @caller.expects(:create_document)
    @collect_action.create('123', @content, {'meta'=>true}, 'output_type')
  end

  def test_create_with_splitter_content
    FakeFS do
      splitter = mock
      @caller.expects(:get_splitter).returns(splitter)

      splitter.expects(:split).with() do |collected_doc|
        assert_true collected_doc.is_a?(Armagh::CollectedDocument)
        assert_true File.file? collected_doc.collected_file
        assert_equal @content, File.read(collected_doc.collected_file)
        true
      end

      @collect_action.create('123', @content, {'meta'=>true}, 'output_type')
    end
  end

  def test_create_with_splitter_file
    FakeFS do
      splitter = mock
      @caller.expects(:get_splitter).returns(splitter)
      collected_file = 'filename'
      File.write(collected_file, @content)

      splitter.expects(:split).with() do |collected_doc|
        valid = true
        valid &&= collected_doc.is_a?(Armagh::CollectedDocument)
        valid &&= File.file? collected_doc.collected_file
        valid &&= (File.read(collected_doc.collected_file) == @content)
        valid
      end

      @collect_action.create('123', collected_file, {'meta'=>true}, 'output_type')
    end
  end

  def test_create_undefined_type
    assert_raise(Armagh::ActionErrors::DocSpecError) do
      @collect_action.create('123', 'something', {}, 'bad_type')
    end
  end

  def test_invalid_create_content
    assert_raise(Armagh::ActionErrors::CreateError) do
      @collect_action.create('234', {}, {}, 'output_type')
    end
  end

  def test_valid
    valid = @collect_action.validate
    assert_true valid['valid']
    assert_empty valid['errors']
    assert_empty valid['warnings']
  end

  def test_valid_invalid_out_state
    output_docspec = Armagh::DocSpec.new('Outputdocspec', Armagh::DocState::PUBLISHED)
    collect_action = Armagh::CollectAction.new('action', @caller, @logger, {}, {'output_type'=> output_docspec})
    valid = collect_action.validate
    assert_false valid['valid']
    assert_equal(['Output docspec \'output_type\' state must be one of: ["ready", "working"].'], valid['errors'])
    assert_empty valid['warnings']
  end

  def test_inheritence
    assert_true Armagh::CollectAction.respond_to? :define_parameter
    assert_true Armagh::CollectAction.respond_to? :defined_parameters

    assert_true Armagh::CollectAction.respond_to? :define_input_type
    assert_true Armagh::CollectAction.respond_to? :defined_input_type
    assert_true Armagh::CollectAction.respond_to? :define_output_docspec
    assert_true Armagh::CollectAction.respond_to? :defined_output_docspecs

    assert_true @collect_action.respond_to? :validate
  end
end
