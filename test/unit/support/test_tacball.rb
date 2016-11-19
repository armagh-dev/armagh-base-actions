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

require 'test/unit'
require 'mocha/test_unit'
require 'fakefs/safe'

require_relative '../../helpers/coverage_helper'
require_relative '../../../lib/armagh/support/tacball'

class TestTacball < Test::Unit::TestCase

  def setup
    @config_values = {
      'tacball' => {
        'feed' => 'carnitas',
        'source' => 'chipotle'
      }
    }
    @config = Armagh::Support::Tacball.create_configuration([], 'test', @config_values)
    @tacball_fields = {
      :docid => '4025/docid',
      :dateposted => 1451696523,
      :title => 'title',
      :timestamp => 1451696523,
      :hastext => true,
      :originaltype => 'text/plain',
      :data_repository => 'data_repo',
      :txt_content => 'hello world',
      :copyright => 'copyright',
      :html_content => '',
      :inject_html => true,
      :basename => 'basename.txt',
      :output_path => '/some/output/path',
      :logger => mock('logger')
    }
    @opts = @tacball_fields.clone
  end

  def test_create_tacball_file
    expected_filename = 'basename.txt.tgz.1451696523.160102'
    FakeFS {
      FileUtils.touch('basename.txt.')
      output_filename = Armagh::Support::Tacball.create_tacball_file(@config, @opts)
      assert_equal expected_filename, output_filename
    }
  end

  def test_create_tacball_file_with_docid_type_error
    expected = Armagh::Support::Tacball::FieldTypeError.new('Document ID must be a string')

    @opts[:docid] = 4025
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }

    @opts[:docid] = nil
    assert_raise(expected) {
      Armagh::Support::Tacball.create_tacball_file(@config, @opts)
    }
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
    @opts[:docid] = 'bad prefix/bad doc'
    FakeFS {
      FileUtils.touch('basename.txt.')
      error = assert_raise(Armagh::Support::Tacball::InvalidDocidError) {
        Armagh::Support::Tacball.create_tacball_file(@config, @opts)
      }
      assert_equal "Document ID (#{@opts[:docid]}) must be in the format #{TAC::VALID_DOCID_REGEX}.", error.message
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
      assert_equal "Feed (#{config.tacball.feed}) must be in the format #{TAC::VALID_FEED_REGEX}.", error.message
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

end
