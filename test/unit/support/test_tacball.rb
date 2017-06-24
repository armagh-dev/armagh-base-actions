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

require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'
require 'zlib'

require_relative '../../helpers/coverage_helper'
require_relative '../../../lib/armagh/support/tacball'

class TestTacball < Test::Unit::TestCase

  def setup
    @config_values = {
      'tacball' => {
        'feed' => 'carnitas',
        'source' => 'chipotle',
        'type' => 'Test'
      }
    }
    @config = Armagh::Support::Tacball.create_configuration([], 'test', @config_values)
    @tacball_fields = {
      :docid => 'docid',
      :title => 'title',
      :timestamp => 1451696523,
      :originaltype => 'text/plain',
      :data_repository => 'data_repo',
      :txt_content => 'hello world',
      :copyright => 'copyright',
      :html_content => '',
      :output_path => '/some/output/path',
      :logger => mock('logger'),
      :type => 'Failover'
    }
    @opts = @tacball_fields.clone
    @orig_env = ENV['ARMAGH_TAC_DOC_PREFIX']
    ENV['ARMAGH_TAC_DOC_PREFIX'] = '4025'
  end

  def teardown
    ENV['ARMAGH_TAC_DOC_PREFIX'] = @orig_env
    FakeFS::FileSystem.clear
  end

  def test_create_tacball_file
    expected_filename = 'Test-docid.tgz.1451696523.160102'
    output_filename = FakeFS { Armagh::Support::Tacball.create_tacball_file(@config, @opts) }
    assert_equal expected_filename, output_filename
  end

  def test_create_tacball_file_containing_original
    read_content = nil
    orig_content = 'original contents'
    orig_name    = 'filename.orig'
    @opts[:original_file] = { orig_name => orig_content }
    FakeFS {
      tgz_file = Armagh::Support::Tacball.create_tacball_file(@config, @opts)
      tgz_path = "#{@opts[:output_path]}/#{tgz_file}"
      tgz_str = StringIO.new(File.read(tgz_path))
      tgz = Gem::Package::TarReader.new(Zlib::GzipReader.new(tgz_str))
      tgz.rewind
      tgz.seek(orig_name) { |entry| read_content = entry.read }
      tgz.close
    }
    assert_equal orig_content, read_content
  end

  def test_create_tacball_file_with_title_type_error
    expected = Armagh::Support::Tacball::FieldTypeError.new('Title must be a string')

    @opts[:title] = 12345
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }

    @opts[:title] = nil
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }
  end

  def test_create_tacball_file_with_feed_type_error
    expected = Armagh::Support::Tacball::FieldTypeError.new('Feed must be a string')

    @config.tacball.expects(:feed).returns(123)
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }

    @config.tacball.expects(:feed).returns(nil)
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }
  end

  def test_create_tacball_file_with_timestamp_type_error
    expected = Armagh::Support::Tacball::FieldTypeError.new('Timestamp must be a number')

    @opts[:timestamp] = '89'
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }

    @opts[:timestamp] = nil
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }
  end

  def test_create_tacball_file_with_invalid_docid
    @opts[:docid] = 'bad doc'
    ENV['ARMAGH_TAC_DOC_PREFIX'] = 'bad prefix'
    FakeFS {
      FileUtils.touch('basename.txt.')
      error = assert_raise(Armagh::Support::Tacball::InvalidDocidError) {
        Armagh::Support::Tacball.create_tacball_file(@config, @opts)
      }
      assert_equal "Document ID (bad prefix/Test-#{@opts[:docid]}) must be in the format #{TAC::VALID_DOCID_WITH_PREFIX}", error.message
    }
  end

  def test_create_tacball_file_with_invalid_feed
    config_values = {
      'tacball' => {
        'feed' => 'This is a bad feed',
        'source' => 'chipotle'
      }
    }
    config = Armagh::Support::Tacball.create_configuration([], 'test', config_values)
    FakeFS {
      FileUtils.touch('basename.txt.')
      error = assert_raise(Armagh::Support::Tacball::InvalidFeedError) {
        Armagh::Support::Tacball.create_tacball_file(config, @opts)
      }
      assert_equal "Feed (#{config.tacball.feed}) must be in the format #{TAC::VALID_FEED}", error.message
    }
  end

  def test_create_tacball_file_orig_extn_without_source_dir
    error_message = "Attachment extensions or original extension cannot be used without source directory"
    TAC.stubs(:create_tacball_file).raises(TAC::AttachmentOrOriginalExtnError, error_message)
    FakeFS {
      FileUtils.touch('basename.txt.')
      error = assert_raise(Armagh::Support::Tacball::AttachmentOrOriginalExtnError) {
        Armagh::Support::Tacball.create_tacball_file(@config, @opts)
      }
      assert_equal error_message, error.message
    }
  end

  def test_create_tacball_file_orig_file_and_orig_extn
    error_message = "Original file and original extension cannot be used together at the same time"
    TAC.stubs(:create_tacball_file).raises(TAC::OriginalFileAndExtensionError, error_message)
    FakeFS {
      FileUtils.touch('basename.txt.')
      error = assert_raise(Armagh::Support::Tacball::OriginalFileAndExtensionError) {
        Armagh::Support::Tacball.create_tacball_file(@config, @opts)
      }
      assert_equal error_message, error.message
    }
  end

  def test_create_tacball_file_original_filename_collision_error
    expected = Armagh::Support::Tacball::OriginalFilenameCollisionError.new('Original filename will collide with another filename in the tacball')

    basename = "#{@config.tacball.type}-#{@opts[:docid]}.html"
    @opts[:original_file] = { basename => "original content" }
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }
  end

  def test_create_tacball_no_type
    @config_values['tacball'].delete('type')
    @config = Armagh::Support::Tacball.create_configuration([], 'test', @config_values)

    expected_filename = 'Failover-docid.tgz.1451696523.160102'
    output_filename = FakeFS { Armagh::Support::Tacball.create_tacball_file(@config, @opts) }
    assert_equal expected_filename, output_filename
  end

end
