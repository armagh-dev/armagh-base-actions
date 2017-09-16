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


require_relative '../../helpers/coverage_helper'

require 'test/unit'
require 'mocha/test_unit'

require_relative '../../../lib/armagh/support/extract'
require_relative '../../helpers/fixture_helper'

class TestExtract < Test::Unit::TestCase

  include FixtureHelper

  def setup
    set_fixture_dir 'extract'
    @fixtures = {
      '7zip' => fixture('dir.7z'),
      'tar' => fixture('dir.tar'),
      'tgz' => fixture('dir.tgz'),
      'zip' => fixture('dir.zip')
    }

    @expected = {
      'dir/file1.txt' => "file1\n",
      'dir/file2.txt' => "file2\n",
      'dir/file3.txt' => "file3\n",
    }
  end

  def test_extract_exceptions
    assert_raise(Armagh::Support::Extract::ExtractError.new('Either a filename or a type must be provided to determine which extractor to use.')) do
      Armagh::Support::Extract.extract('string', filename: nil, type: nil, filename_pattern: '*.txt')
    end

    assert_raise(Armagh::Support::Extract::ExtractError.new("Unknown type 'fake_type'.  Expected one of: 7zip, tar, tgz, zip.")) do
      Armagh::Support::Extract.extract('string', filename: nil, type: 'fake_type', filename_pattern: '*.txt')
    end

    assert_raise(Armagh::Support::Extract::ExtractError.new("File 'bad_file.txt' needs to have one of the following extensions: .7z, .tar, .tar.gz, .tgz, .zip.")) do
      Armagh::Support::Extract.extract('string', filename: 'bad_file.txt')
    end
  end

  def test_extract_tar
    result = {}

    Armagh::Support::Extract.extract_tar(@fixtures['tar']) do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_tar(@fixtures['tar'], filename_pattern: '*.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_tar(@fixtures['tar'], filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tar'], filename: 'something.tar') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tar'], type: 'tar') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tar'], type: 'tar', filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tar'], type: 'tar', filename: 'something.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    assert_raise(Armagh::Support::Extract::ExtractError.new('Unable to untar.')) do
      Armagh::Support::Extract.extract(nil, type: 'tar', filename_pattern: 'sub/*.txt')
    end
  end

  def test_extract_tgz
    result = {}

    Armagh::Support::Extract.extract_tgz(@fixtures['tgz']) do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_tgz(@fixtures['tgz'], filename_pattern: '*.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_tgz(@fixtures['tgz'], filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tgz'], filename: 'something.tgz') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tgz'], filename: 'something.tar.gz') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tgz'], type: 'tgz') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tgz'], type: 'tgz', filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['tgz'], type: 'tgz', filename: 'something.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    assert_raise(Armagh::Support::Extract::ExtractError.new('Unable to untgz.')) do
      Armagh::Support::Extract.extract(nil, type: 'tgz', filename_pattern: 'sub/*.txt')
    end
  end

  def test_extract_zip
    result = {}

    Armagh::Support::Extract.extract_zip(@fixtures['zip']) do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_zip(@fixtures['zip'], filename_pattern: '*.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_zip(@fixtures['zip'], filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['zip'], filename: 'something.zip') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['zip'], type: 'zip') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['zip'], type: 'zip', filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['zip'], type: 'zip', filename: 'something.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    assert_raise(Armagh::Support::Extract::ExtractError.new('Unable to unzip.')) do
      Armagh::Support::Extract.extract(nil, type: 'zip', filename_pattern: 'sub/*.txt')
    end
  end

  def test_extract_7zip
    result = {}

    Armagh::Support::Extract.extract_7zip(@fixtures['7zip']) do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_7zip(@fixtures['7zip'], filename_pattern: '*.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract_7zip(@fixtures['7zip'], filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['7zip'], filename: 'something.7z') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['7zip'], type: '7zip') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['7zip'], type: '7zip', filename_pattern: 'sub/*.txt') do |filename, content|
      result[filename] = content
    end
    assert_empty result

    result.clear
    Armagh::Support::Extract.extract(@fixtures['7zip'], type: '7zip', filename: 'something.txt') do |filename, content|
      result[filename] = content
    end
    assert_equal @expected, result

    assert_raise(Armagh::Support::Extract::ExtractError.new('Unable to un7zip.')) do
      Armagh::Support::Extract.extract(nil, type: '7zip', filename_pattern: 'sub/*.txt')
    end
  end
end
