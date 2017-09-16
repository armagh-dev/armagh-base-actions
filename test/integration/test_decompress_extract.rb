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


require_relative '../helpers/coverage_helper'
require_relative '../helpers/fixture_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'fileutils'

require_relative '../../lib/armagh/actions/collect'
require_relative '../../lib/armagh/documents/source'

class TDECollectFile < Armagh::Actions::Collect
  include FixtureHelper

  def collect
    set_fixture_dir 'extract'
    file = fixture_path 'dir.tgz'

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.cp(file, './dir.tgz')
        source = Armagh::Documents::Source.new(type: 'file', filename: 'dir.tgz', host: 'localhost', path: '.')
        create(collected: 'dir.tgz', metadata: {}, source: source)
      end
    end

  end
end

class TDECollectURL < Armagh::Actions::Collect
  include FixtureHelper

  def collect
    set_fixture_dir 'extract'
    file = fixture_path 'dir.tgz'

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        tgz = File.read(file)
        source = Armagh::Documents::Source.new(type: 'url', url: 'http://somesite.test')
        create(collected: tgz, metadata: {}, source: source)
      end
    end
  end
end

class TestDecompressExtract < Test::Unit::TestCase

  def setup
    @caller = mock('caller')
    @divider = mock('divider')
    @config_store = []
  end

  def test_decompress_then_extract_file
    @caller.expects(:instantiate_divider).returns(nil)

    @caller.expects(:create_document).with {|doc| doc.raw == "file1\n" &&  doc.source.filename == 'dir.tgz:dir/file1.txt'}
    @caller.expects(:create_document).with {|doc| doc.raw == "file2\n" &&  doc.source.filename == 'dir.tgz:dir/file2.txt'}
    @caller.expects(:create_document).with {|doc| doc.raw == "file3\n" &&  doc.source.filename == 'dir.tgz:dir/file3.txt'}

    config = TDECollectFile.create_configuration(@config_store, 'a', {
      'action' => {'name' => 'mysubcollect'},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'decompress' => true, 'extract' => true, 'extract_format' => 'tar'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    action = TDECollectFile.new( @caller, 'logger_name', config, @config_store )
    action.collect
  end

  def test_decompress_then_extract_url
    @caller.expects(:instantiate_divider).returns(nil)

    @caller.expects(:create_document).with {|doc| doc.raw == "file1\n" &&  doc.source.filename == ':dir/file1.txt'}
    @caller.expects(:create_document).with {|doc| doc.raw == "file2\n" &&  doc.source.filename == ':dir/file2.txt'}
    @caller.expects(:create_document).with {|doc| doc.raw == "file3\n" &&  doc.source.filename == ':dir/file3.txt'}

    config = TDECollectURL.create_configuration(@config_store, 'a', {
      'action' => {'name' => 'mysubcollect'},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'decompress' => true, 'extract' => true, 'extract_format' => 'tar'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    action = TDECollectURL.new( @caller, 'logger_name', config, @config_store )
    action.collect
  end

  def test_decompress_then_extract_file_divide
    @caller.expects(:instantiate_divider).returns(@divider)

    docspec_param = mock
    docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
    defined_params = mock
    defined_params.expects(:find_all_parameters).returns([docspec_param])

    @divider.expects(:config).returns(defined_params)
    @divider.stubs(:doc_details=)

    @divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file1.txt' && File.read('dir/file1.txt') == "file1\n"}
    @divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file2.txt' && File.read('dir/file2.txt') == "file2\n"}
    @divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file3.txt' && File.read('dir/file3.txt') == "file3\n"}

    config = TDECollectFile.create_configuration(@config_store, 'a', {
      'action' => {'name' => 'mysubcollect'},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'decompress' => true, 'extract' => true, 'extract_format' => 'tar'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    action = TDECollectFile.new( @caller, 'logger_name', config, @config_store )
    action.collect
  end

  def test_decompress_then_extract_divide_url
    @caller.expects(:instantiate_divider).returns(@divider)

    docspec_param = mock
    docspec_param.expects(:value).returns(Armagh::Documents::DocSpec.new('a', 'ready'))
    defined_params = mock
    defined_params.expects(:find_all_parameters).returns([docspec_param])

    @divider.expects(:config).returns(defined_params)
    @divider.stubs(:doc_details=)

    @divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file1.txt' && File.read('dir/file1.txt') == "file1\n"}
    @divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file2.txt' && File.read('dir/file2.txt') == "file2\n"}
    @divider.expects(:divide).with{|doc| doc.collected_file == 'dir/file3.txt' && File.read('dir/file3.txt') == "file3\n"}

    config = TDECollectURL.create_configuration(@config_store, 'a', {
      'action' => {'name' => 'mysubcollect'},
      'collect' => {'schedule' => '*/5 * * * *', 'archive' => false, 'decompress' => true, 'extract' => true, 'extract_format' => 'tar'},
      'output' => {'docspec' => Armagh::Documents::DocSpec.new('type', Armagh::Documents::DocState::READY)}
    })

    action = TDECollectURL.new( @caller, 'logger_name', config, @config_store )
    action.collect
  end
end

