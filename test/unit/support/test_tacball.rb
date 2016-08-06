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
require 'fakefs/safe'

require_relative '../../helpers/coverage_helper'
require_relative '../../../lib/armagh/support/tacball'

class TestTacball < Test::Unit::TestCase

  def setup
  end

  def test_create_tacball_file
    expected_filename = 'base_name.txt.tgz.1451696523.160102'
    FakeFS {
      FileUtils.touch('base_name.txt.')
      output_filename = Armagh::Support::Tacball.create_tacball_file(
        docid: '4025/docid',
        dateposted: 1451696523,
        title: 'title',
        feed: 'feed',
        timestamp: 1451696523,
        hastext: true,
        pubtimestamp: 1451696523,
        source: 'source',
        originaltype: 'orig_type',
        data_repository: 'data_repo',
        txt_content: 'hello world',
        copyright: 'copyright',
        html_content: '',
        inject_html: true,
        basename: 'base_name.txt',
        output_path: '/some/output/path'
      )
      assert_equal expected_filename, output_filename
    }
  end

  def test_create_tacball_file_with_no_docid
    error = assert_raise(ArgumentError) {
      Armagh::Support::Tacball.create_tacball_file(
        dateposted: 1451696523,
        title: 'title',
        feed: 'feed',
        timestamp: 1451696523,
        hastext: true,
        pubtimestamp: 1451696523,
        source: 'source',
        originaltype: 'orig_type',
        data_repository: 'data_repo',
        txt_content: 'hello world',
        copyright: 'copyright',
        html_content: '',
        inject_html: true,
        basename: 'base_name.txt',
        output_path: '/some/output/path'
      )
    }
    assert_equal "missing keyword: docid", error.message
  end

  def test_create_tacball_file_with_invalid_docid
    FakeFS {
      FileUtils.touch('base_name.txt.')
      error = assert_raise(Armagh::Support::Tacball::TacballDataTypeError) {
        Armagh::Support::Tacball.create_tacball_file(
          docid: 4025,
          dateposted: 1451696523,
          title: 'title',
          feed: 'feed',
          timestamp: 1451696523,
          hastext: true,
          pubtimestamp: 1451696523,
          source: 'source',
          originaltype: 'orig_type',
          data_repository: 'data_repo',
          txt_content: 'hello world',
          copyright: 'copyright',
          html_content: '',
          inject_html: true,
          basename: 'base_name.txt',
          output_path: '/some/output/path'
        )
      }
      assert_equal "Document ID must be a string", error.message
    }
  end

end
