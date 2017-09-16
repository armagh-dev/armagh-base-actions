# Copyright 2017 Noragh Analytics, Inc.
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

require_relative '../../helpers/fixture_helper'
require_relative '../../helpers/coverage_helper'

require_relative '../../../lib/armagh/actions'
require_relative '../../../lib/armagh/documents'


require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'
require 'configh'
require 'facets/zlib'

class TestCollect < Test::Unit::TestCase
  include FixtureHelper

  def setup
    set_fixture_dir 'extract'

    @tgz = fixture('dir.tgz')

    @caller = mock
    @collection = mock
    if Object.const_defined?( :SubCollect )
      Object.send( :remove_const, :SubCollect )
    end
    Object.const_set :SubCollect, Class.new(Armagh::Actions::Collect)
    SubCollect.define_output_docspec('output_type', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY)
    @config_store = []
    config = SubCollect.create_configuration(@config_store, 'a', {
      'action' => {'name' => 'mysubcollect'},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    @collect_action = SubCollect.new(@caller, 'logger_name', config, @collection)
    @content = 'collected content'
    @source = Armagh::Documents::Source.new(type: 'url', url: 'some url')
  end

  def teardown
    FakeFS::FileSystem.clear
  end

  def test_unimplemented_collect
    assert_raise(Armagh::Actions::Errors::ActionMethodNotImplemented) { @collect_action.collect }
  end

  def test_input_doctype_override
    assert_equal "#{SubCollect::COLLECT_DOCTYPE_PREFIX}mysubcollect:ready", @collect_action.config.input.docspec.to_s
  end

  def test_create_no_divider
    @caller.expects(:instantiate_divider).returns(nil)
    @caller.expects(:create_document)
    @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: @source)
  end

  def test_create_with_divider_content
    FakeFS do
      divider = mock
      @caller.expects(:instantiate_divider).returns(divider)

      docspec_param = mock
      docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
      defined_params = mock
      defined_params.expects(:find_all_parameters).returns([docspec_param])
      divider.expects(:config).returns(defined_params)
      divider.expects(:doc_details=).with({'source' => @source, 'document_id' => nil, 'title' => nil, 'copyright' => nil, 'document_timestamp' => nil})
      divider.expects(:doc_details=).with(nil)

      divider.expects(:divide).with() do |collected_doc|
        assert_true collected_doc.is_a?(Armagh::Documents::CollectedDocument)
        assert_true File.file? collected_doc.collected_file
        assert_equal @content, File.read(collected_doc.collected_file)
        true
      end

      @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_with_divider_file_and_archive
    document_id = '123'
    title = 'title'
    timestamp = Time.at(0)
    copyright = 'copyright'

    FakeFS do
      divider = mock
      @caller.expects(:instantiate_divider).returns(divider)
      docspec_param = mock
      docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
      defined_params = mock
      defined_params.expects(:find_all_parameters).returns([docspec_param])
      divider.expects(:config).returns(defined_params)
      divider.expects(:doc_details=).with({'source' => @source, 'document_id' => document_id, 'title' => title, 'copyright' => copyright, 'document_timestamp' => timestamp})
      divider.expects(:doc_details=).with(nil)
      collected_file = 'filename'
      File.write(collected_file, @content)

      divider.expects(:divide).with() do |collected_doc|
        valid = true
        valid &&= collected_doc.is_a?(Armagh::Documents::CollectedDocument)
        valid &&= File.file? collected_doc.collected_file
        valid &&= (File.read(collected_doc.collected_file) == @content)
        valid
      end

      @collect_action.create(collected: collected_file, metadata: {'meta' => true}, docspec_name: 'output_type', source: @source, document_id: document_id, title: title, document_timestamp: timestamp, copyright: copyright)
    end
  end

  def test_create_archive
    @caller.expects(:instantiate_divider).returns(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    random_id = 'someid'
    meta = {'meta' => true}

    Armagh::Support::Random.stubs(:random_id).returns(random_id)
    @caller.expects(:archive).with(logger_name, action_name, random_id, {'metadata' => meta, 'source' => @source.to_hash})
    @caller.expects(:create_document)

    config = SubCollect.create_configuration(@config_store, 'a_cre_arch', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => true},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}

    })

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    FakeFS do
      @collect_action.create(collected: @content, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_archive_divider
    divider = mock
    @caller.expects(:instantiate_divider).returns(divider)

    random_id = 'random_id'
    Armagh::Support::Random.stubs(:random_id).returns(random_id)

    docspec_param = mock
    docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
    defined_params = mock
    defined_params.expects(:find_all_parameters).returns([docspec_param])
    divider.expects(:config).returns(defined_params)
    divider.expects(:doc_details=).with({'source' => @source, 'document_id' => nil, 'title' => nil, 'copyright' => nil, 'document_timestamp' => nil})
    divider.expects(:doc_details=).with(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}

    @caller.expects(:archive).with(logger_name, action_name, random_id, {'source' => {'type' => 'url', 'url' => 'some url'}, 'metadata' => {'meta' => true}})
    divider.expects(:divide)

    config = SubCollect.create_configuration(@config_store, 'a_cre_arch_div', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => true},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    FakeFS do
      @collect_action.create(collected: @content, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_archive_known_filename
    @caller.expects(:instantiate_divider).returns(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}
    filename = 'filename'
    @source.filename = filename

    @caller.expects(:archive).with(logger_name, action_name, filename, {'metadata' => meta, 'source' => @source.to_hash})
    @caller.expects(:create_document)

    config = SubCollect.create_configuration(@config_store, 'a_cre_arc_kn_fn', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => true},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    FakeFS do
      @collect_action.create(collected: @content, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_undefined_type
    assert_raise(Armagh::Documents::Errors::DocSpecError) do
      @collect_action.create(collected: 'something', metadata: {}, docspec_name: 'bad_type', source: @source)
    end
  end

  def test_invalid_create_content
    assert_raise(Armagh::Actions::Errors::CreateError) do
      @collect_action.create(collected: {}, metadata: {}, docspec_name: 'output_type', source: @source)
    end
  end

  def test_invalid_create_metadata
    assert_raise(Armagh::Actions::Errors::CreateError) do
      @collect_action.create(collected: '', metadata: '', docspec_name: 'output_type', source: @source)
    end
  end

  def test_invalid_create_document_id
    assert_raise(Armagh::Actions::Errors::CreateError) do
      @collect_action.create(collected: '', metadata: {}, docspec_name: 'output_type', source: @source, document_id: 123)
    end
  end

  def test_invalid_create_title
    assert_raise(Armagh::Actions::Errors::CreateError) do
      @collect_action.create(collected: '', metadata: {}, docspec_name: 'output_type', source: @source, title: 123)
    end
  end

  def test_invalid_create_copyright
    assert_raise(Armagh::Actions::Errors::CreateError) do
      @collect_action.create(collected: '', metadata: {}, docspec_name: 'output_type', source: @source, copyright: 123)
    end
  end

  def test_invalid_create_document_timestamp
    assert_raise(Armagh::Actions::Errors::CreateError) do
      @collect_action.create(collected: '', metadata: {}, docspec_name: 'output_type', source: @source, document_timestamp: 123)
    end
  end

  def test_file_source
    source = Armagh::Documents::Source.new(type: 'file', filename: 'filename', host: 'host', path: 'path')

    @caller.expects(:instantiate_divider).returns(nil)
    @caller.expects(:create_document).returns(nil)

    @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: source)
  end

  def test_file_source_bad_filename
    source = Armagh::Documents::Source.new(type: 'file', host: 'host', path: 'path')
    e = Armagh::Actions::Errors::CreateError.new('Source filename must be set.')
    assert_raise(e) { @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: source) }
  end

  def test_file_source_bad_path
    source = Armagh::Documents::Source.new(type: 'file', filename: 'filename', host: 'host')
    e = Armagh::Actions::Errors::CreateError.new('Source path must be set.')
    assert_raise(e) { @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: source) }
  end

  def test_file_source_bad_host
    source = Armagh::Documents::Source.new(type: 'file', filename: 'filename', path: 'path')
    e = Armagh::Actions::Errors::CreateError.new('Source host must be set.')
    assert_raise(e) { @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: source) }
  end

  def test_url_source_bad_url
    source = Armagh::Documents::Source.new(type: 'url')
    e = Armagh::Actions::Errors::CreateError.new('Source url must be set.')
    assert_raise(e) { @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: source) }
  end

  def test_source_bad_type
    source = Armagh::Documents::Source.new(type: 'invalid')
    e = Armagh::Actions::Errors::CreateError.new('Source type must be url or file.')
    assert_raise(e) { @collect_action.create(collected: @content, metadata: {'meta' => true}, docspec_name: 'output_type', source: source) }
  end

  def test_valid_out_spec
    SubCollect.define_output_docspec('docspec', 'action description')

    assert_nothing_raised do
      SubCollect.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'mysubcollect'},
        'collect' => {'schedule' => '*/5 * * * *', 'archive' => false},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })

      SubCollect.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'mysubcollect'},
        'collect' => {'schedule' => '*/5 * * * *', 'archive' => false},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::WORKING)}
      })
    end
  end

  def test_invalid_out_spec
    Object.send(:remove_const, :SubCollect) if Object.const_defined?(:SubCollect)
    Object.const_set :SubCollect, Class.new(Armagh::Actions::Collect)
    SubCollect.define_output_docspec('collected_doc', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::PUBLISHED)
    e = assert_raises(Configh::ConfigInitError) {
      config = SubCollect.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'mysubcollect'},
        'collect' => {'schedule' => '*/5 * * * *', 'archive' => false},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })
    }
    assert_equal "Unable to create configuration for 'SubCollect' named 'inoutstate' because: \n    Output docspec 'collected_doc' state must be one of: ready, working.", e.message
  end

  def test_multiple_in_spec
    Object.send(:remove_const, :SubCollect) if Object.const_defined?(:SubCollect)
    Object.const_set :SubCollect, Class.new(Armagh::Actions::Collect)
    e = Armagh::Actions::ConfigurationError.new('You cannot define default input types for collectors')
    assert_raise(e){SubCollect.define_default_input_type('trigger')}
  end

  def test_valid_invalid_schedule
    if Object.const_defined?(:SubCollect)
      Object.send(:remove_const, :SubCollect)
    end
    Object.const_set :SubCollect, Class.new(Armagh::Actions::Collect)
    SubCollect.include Configh::Configurable
    SubCollect.define_output_docspec('collected_doc', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY)
    assert_raises(Configh::ConfigInitError.new("Unable to create configuration for 'SubCollect' named 'inoutstate' because: \n    Schedule 'invalid' is not valid cron syntax.")) {
      SubCollect.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'mysubcollect'},
        'collect' => {'schedule' => 'invalid', 'archive' => false},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })
    }
  end

  def test_valid_invalid_extract
    if Object.const_defined?(:SubCollect)
      Object.send(:remove_const, :SubCollect)
    end
    Object.const_set :SubCollect, Class.new(Armagh::Actions::Collect)
    SubCollect.include Configh::Configurable
    SubCollect.define_output_docspec('collected_doc', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY)
    assert_raises(Configh::ConfigInitError.new("Unable to create configuration for 'SubCollect' named 'inoutstate' because: \n    Group 'collect' Parameter 'extract_format': value is not one of the options")) {
      SubCollect.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'mysubcollect'},
        'collect' => {'extract' => true, 'extract_filter' => '*.txt', 'extract_format' => 'invalid'},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })
    }
  end

  def test_valid_no_schedule
    Object.send(:remove_const, :SubCollect) if Object.const_defined?(:SubCollect)

    Object.const_set :SubCollect, Class.new(Armagh::Actions::Collect)
    SubCollect.include Configh::Configurable
    SubCollect.define_output_docspec('collected_doc', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY)

    assert_nothing_raised do
      SubCollect.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'mysubcollect'},
        'collect' => {'archive' => false},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })
    end
  end

  def test_valid_archive
    if Object.const_defined?(:SubCollect)
      Object.send(:remove_const, :SubCollect)
    end
    Object.const_set :SubCollect, Class.new(Armagh::Actions::Collect)
    SubCollect.include Configh::Configurable
    SubCollect.define_output_docspec('collected_doc', 'action description', default_type: 'OutputDocument', default_state: Armagh::Documents::DocState::READY)


    assert_nothing_raised {
      SubCollect.create_configuration([], 'inoutstate', {
        'action' => {'name' => 'mysubcollect'},
        'collect' => {'schedule' => '*/5 * * * *', 'archive' => true},
        'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
      })
    }
  end

  def test_create_decompress
    @caller.expects(:instantiate_divider).returns(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}

    @caller.expects(:create_document).with {|doc| doc.raw == @content}

    config = SubCollect.create_configuration(@config_store, 'a_cre_arch', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'decompress' => true},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    compressed = Zlib.compress(@content)

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    FakeFS do
      @collect_action.create(collected: compressed, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_decompress_divide
    divider = mock
    @caller.expects(:instantiate_divider).returns(divider)

    docspec_param = mock
    docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
    defined_params = mock
    defined_params.expects(:find_all_parameters).returns([docspec_param])
    divider.expects(:config).returns(defined_params)
    divider.expects(:doc_details=).with({'source' => @source, 'document_id' => nil, 'title' => nil, 'copyright' => nil, 'document_timestamp' => nil})
    divider.expects(:doc_details=).with(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}

    divider.expects(:divide)

    config = SubCollect.create_configuration(@config_store, 'a_cre_dec_div', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'decompress' => true},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    compressed = Zlib.compress(@content)

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    file_content = nil
    FakeFS do
      filename = '/tmp/file'
      FileUtils.mkdir_p '/tmp'
      File.write(filename, compressed)
      @collect_action.create(collected: filename, metadata: meta, docspec_name: 'output_type', source: @source)
      file_content = File.read(filename)
    end

    assert_equal(@content, file_content)
  end

  def test_create_extract
    filename = 'some.tgz'
    @caller.expects(:instantiate_divider).returns(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}

    @caller.expects(:create_document).with {|doc| doc.raw == "file1\n" &&  doc.source.filename == "#{filename}:dir/file1.txt"}
    @caller.expects(:create_document).with {|doc| doc.raw == "file2\n" &&  doc.source.filename == "#{filename}:dir/file2.txt"}
    @caller.expects(:create_document).with {|doc| doc.raw == "file3\n" &&  doc.source.filename == "#{filename}:dir/file3.txt"}

    config = SubCollect.create_configuration(@config_store, 'a_cre_ext', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'extract' => true, 'extract_filter' => '*.txt'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    @source.filename = 'some.tgz'

    FakeFS do
      File.write(filename, @tgz)
      @collect_action.create(collected: filename, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_extract_none
    filename = 'some.tgz'
    @caller.expects(:instantiate_divider).returns(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}

    @caller.expects(:notify_ops).with(logger_name, action_name, 'No files were extracted.')

    config = SubCollect.create_configuration(@config_store, 'a_cre_ext', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'extract' => true, 'extract_filter' => '*.png'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    @source.filename = 'some.tgz'

    FakeFS do
      File.write(filename, @tgz)
      @collect_action.create(collected: filename, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_extract_divide
    @source.filename = 'some.tgz'

    divider = mock
    @caller.expects(:instantiate_divider).returns(divider)

    docspec_param = mock
    docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
    defined_params = mock
    defined_params.expects(:find_all_parameters).returns([docspec_param])
    divider.expects(:config).returns(defined_params)
    divider.expects(:doc_details=).with({'source' => @source, 'document_id' => nil, 'title' => nil, 'copyright' => nil, 'document_timestamp' => nil})
    divider.expects(:doc_details=).with(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}

    divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file1.txt' && File.read('dir/file1.txt') == "file1\n"}
    divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file2.txt' && File.read('dir/file2.txt') == "file2\n"}
    divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file3.txt' && File.read('dir/file3.txt') == "file3\n"}

    config = SubCollect.create_configuration(@config_store, 'a_cre_dec_div', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'extract' => true, 'extract_format' => 'tgz'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    FakeFS do
      @collect_action.create(collected: @tgz, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_create_extract_divide_none
    @source.filename = 'some.tgz'

    divider = mock
    @caller.expects(:instantiate_divider).returns(divider)

    docspec_param = mock
    docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
    defined_params = mock
    defined_params.expects(:find_all_parameters).returns([docspec_param])
    divider.expects(:config).returns(defined_params)
    divider.expects(:doc_details=).with({'source' => @source, 'document_id' => nil, 'title' => nil, 'copyright' => nil, 'document_timestamp' => nil})
    divider.expects(:doc_details=).with(nil)

    logger_name = 'logger'
    action_name = 'mysubcollect'
    meta = {'meta' => true}

    @caller.expects(:notify_ops).with(logger_name, action_name, 'No files were extracted.')

    config = SubCollect.create_configuration(@config_store, 'a_cre_dec_div', {
      'action' => {'name' => action_name},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'extract' => true, 'extract_format' => 'tgz', 'extract_filter' => '*.png'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    @collect_action = SubCollect.new(@caller, logger_name, config, @collection)
    FakeFS do
      @collect_action.create(collected: @tgz, metadata: meta, docspec_name: 'output_type', source: @source)
    end
  end

  def test_inheritance
    assert_true SubCollect.respond_to? :define_parameter
    assert_true SubCollect.respond_to? :defined_parameters

    assert_true SubCollect.respond_to? :define_default_input_type
    assert_true SubCollect.respond_to? :define_output_docspec

    assert_true @collect_action.respond_to? :log_debug
    assert_true @collect_action.respond_to? :log_info
    assert_true @collect_action.respond_to? :notify_dev
    assert_true @collect_action.respond_to? :notify_ops
  end
end
