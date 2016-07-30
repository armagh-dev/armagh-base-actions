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
require 'fakefs/safe'

require_relative '../../../lib/armagh/actions'

class TestCollect < Test::Unit::TestCase

  def setup
    @caller = mock
    @output_docspec = Armagh::Documents::DocSpec.new('OutputDocument', Armagh::Documents::DocState::READY)
    @content = 'collected content'
    @collect_action = Armagh::Actions::Collect.new('action', @caller, 'logger_name', {}, {'output_type'=> @output_docspec})
    @source = {
        'type' => 'url',
        'url' => 'some url'
    }

  end

  def test_unimplemented_collect
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) {@collect_action.collect}
  end

  def test_create_no_divider
    @caller.expects(:get_divider).returns(nil)
    @caller.expects(:create_document)
    @collect_action.create(@content, {'meta'=>true}, 'output_type', @source)
  end

  def test_create_with_divider_content
    FakeFS do
      divider = mock
      @caller.expects(:get_divider).returns(divider)
      divider.expects(:source=).twice

      divider.expects(:divide).with() do |collected_doc|
        assert_true collected_doc.is_a?(Armagh::Documents::CollectedDocument)
        assert_true File.file? collected_doc.collected_file
        assert_equal @content, File.read(collected_doc.collected_file)
        true
      end

      @collect_action.create(@content, {'meta'=>true}, 'output_type', @source)
    end
  end

  def test_create_with_divider_file
    FakeFS do
      divider = mock
      @caller.expects(:get_divider).returns(divider)
      divider.expects(:source=).twice
      collected_file = 'filename'
      File.write(collected_file, @content)

      divider.expects(:divide).with() do |collected_doc|
        valid = true
        valid &&= collected_doc.is_a?(Armagh::Documents::CollectedDocument)
        valid &&= File.file? collected_doc.collected_file
        valid &&= (File.read(collected_doc.collected_file) == @content)
        valid
      end

      @collect_action.create(collected_file, {'meta'=>true}, 'output_type', @source)
    end
  end

  def test_create_undefined_type
    assert_raise(Armagh::Documents::Errors::DocSpecError) do
      @collect_action.create('something', {}, 'bad_type', @source)
    end
  end

  def test_invalid_create_content
    assert_raise(Armagh::Actions::Errors::CreateError) do
      @collect_action.create({}, {}, 'output_type', @source)
    end
  end

  def test_file_source
    source = {
        'type' => 'file',
        'filename' => 'filename',
        'host' => 'host',
        'path' => 'path'
    }

    @caller.expects(:get_divider).returns(nil)
    @caller.expects(:create_document).returns(nil)

    @collect_action.create(@content, {'meta'=>true}, 'output_type', source)
  end

  def test_file_source_bad_filename
    source = {
        'type' => 'file',
        'host' => 'host',
        'path' => 'path'
    }

    e = Armagh::Actions::Errors::CreateError.new('Source filename must be set.')
    assert_raise(e){@collect_action.create(@content, {'meta'=>true}, 'output_type', source)}
  end

  def test_file_source_bad_path
    source = {
        'type' => 'file',
        'filename' => 'filename',
        'host' => 'host'
    }

    e = Armagh::Actions::Errors::CreateError.new('Source path must be set.')
    assert_raise(e){@collect_action.create(@content, {'meta'=>true}, 'output_type', source)}
  end

  def test_file_source_bad_host
    source = {
        'type' => 'file',
        'filename' => 'filename',
        'path' => 'path'
    }

    e = Armagh::Actions::Errors::CreateError.new('Source host must be set.')
    assert_raise(e){@collect_action.create(@content, {'meta'=>true}, 'output_type', source)}
  end

  def test_url_source_bad_url
    source = {
        'type' => 'url'
    }

    e = Armagh::Actions::Errors::CreateError.new('Source url must be set.')
    assert_raise(e){@collect_action.create(@content, {'meta'=>true}, 'output_type', source)}
  end

  def test_source_bad_type
    source = {
        'type' => 'invalid'
    }

    e = Armagh::Actions::Errors::CreateError.new('Source type must be url or file.')
    assert_raise(e){@collect_action.create(@content, {'meta'=>true}, 'output_type', source)}
  end

  def test_valid
    valid = @collect_action.validate
    assert_true valid['valid']
    assert_empty valid['errors']
    assert_empty valid['warnings']
  end

  def test_valid_invalid_out_state
    output_docspec = Armagh::Documents::DocSpec.new('Outputdocspec', Armagh::Documents::DocState::PUBLISHED)
    collect_action = Armagh::Actions::Collect.new('action', @caller, 'logger_name', {}, {'output_type'=> output_docspec})
    valid = collect_action.validate
    assert_false valid['valid']
    assert_equal(['Output docspec \'output_type\' state must be one of: ["ready", "working"].'], valid['errors'])
    assert_empty valid['warnings']
  end

  def test_inheritence
    assert_true Armagh::Actions::Collect.respond_to? :define_parameter
    assert_true Armagh::Actions::Collect.respond_to? :defined_parameters

    assert_true Armagh::Actions::Collect.respond_to? :define_default_input_type
    assert_true Armagh::Actions::Collect.respond_to? :defined_default_input_type
    assert_true Armagh::Actions::Collect.respond_to? :define_output_docspec
    assert_true Armagh::Actions::Collect.respond_to? :defined_output_docspecs

    assert_true @collect_action.respond_to? :validate
    assert_true @collect_action.respond_to? :log_debug
    assert_true @collect_action.respond_to? :log_info
    assert_true @collect_action.respond_to? :notify_dev
    assert_true @collect_action.respond_to? :notify_ops
  end
end
