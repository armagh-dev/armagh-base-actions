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

require_relative 'coverage_helper'

require 'test/unit'
require 'mocha/test_unit'
require 'fileutils'

require_relative '../lib/armagh/base/actions/init'

class TestInit < Test::Unit::TestCase

  def setup
    @base_dir = '/tmp/test_actions'
    @asset_dir = File.join(__dir__, '..', 'assets')
  end

  def teardown
    FileUtils.rm_rf @base_dir
  end

  def test_create_scaffolding
    project_name = 'mystery'

    FileUtils.mkdir_p @base_dir
    Dir.chdir @base_dir
    test_dir = File.join(@base_dir, "#{project_name}-custom_actions")

    Armagh::Base::Actions::Init.create_scaffolding(project_name)

    assert_true File.directory?(test_dir)
    source_files = Dir.glob(File.join(@asset_dir, '**', '*')).collect{|f| f.sub(@asset_dir, '')}
    generated_files = Dir.glob(File.join(test_dir, '**', '*')).collect{|f| f.sub(test_dir, '')}
    assert_equal(source_files.length, generated_files.length, 'Source and generated should have the same number of files')

    #uniq
    only_source = source_files - generated_files
    only_generated = generated_files - source_files

    only_source.each do |source_file|
      unless source_file =~ /\[[A-Z_]+\]/
        fail "#{source_file} did not get added by the generator"
      end
    end

    only_generated.each do |generated_file|
      assert_nil(generated_file =~ /\[[A-Z_]+\]/, "#{generated_file} was not successfully renamed")
    end

    #diff
    (generated_files-only_generated).each do |file|
      original = File.join(@asset_dir, file)
      next unless File.file? original

      generated = File.join(test_dir, file)

      original_content = File.readlines(original)
      generated_content = File.readlines(generated)

      assert_equal(original_content.length, generated_content.length, "#{original} and #{generated} have different lengths")

      original_content.each_with_index do |o_line, idx|
        g_line = generated_content[idx]
        assert_nil(g_line =~ /\[[A-Z_]+\]/, "#{generated}:#{idx} has replacement flags in it (#{g_line})")
        next if o_line =~ /\[[A-Z_]+\]/
        assert_equal(o_line, generated_content[idx])
      end
    end
  end

end
