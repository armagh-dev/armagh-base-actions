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

require_relative '../../lib/armagh/actions/collection_splitter'

class TestCollectionSplitter < Test::Unit::TestCase

  def setup
    @logger = mock
    @caller = mock
    @output_docspec = mock
    @collection_splitter = Armagh::CollectionSplitter.new(@caller, @logger, {}, @output_docspec)
  end

  def test_unimplemented_split
    assert_raise(Armagh::ActionErrors::ActionMethodNotImplemented) {@collection_splitter.split(nil)}
  end

  def test_create
    id = 'id'
    draft_content = 'content'
    meta = {'meta' => true}

    @caller.expects(:create_document)

    @collection_splitter.create(id, draft_content, meta)
  end

  def test_inheritence
    assert_true Armagh::CollectionSplitter.respond_to? :define_parameter
    assert_true Armagh::CollectionSplitter.respond_to? :defined_parameters

    assert_true @collection_splitter.respond_to? :validate
  end
end

