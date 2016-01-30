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
require 'logger'
require 'mocha/test_unit'

require_relative '../lib/armagh/action'
require_relative '../lib/armagh/doc_state'

class TestAction < Test::Unit::TestCase

  def setup
    @logger = Logger.new(STDOUT)
    @caller = mock

    load File.join(__dir__, 'alice_action.rb')
    load File.join(__dir__, 'fred_action.rb')
  end

  def teardown
    Armagh::AliceAction.defined_parameters.clear
    Armagh::FredAction.defined_parameters.clear
  end

  def test_param_definitions

    [Armagh::AliceAction].each do |action|

      assert_equal(%w(full_name age city customer birthday), action::defined_parameters.keys, 'Got unexpected params')

      assert_equal('Full name', action.defined_parameters['full_name']['description'])
      assert_equal(String, action.defined_parameters['full_name']['type'])
      assert_equal('e.g., Jane Doe', action.defined_parameters['full_name']['prompt'])
      assert_equal(nil, action.defined_parameters['full_name']['default'])
      assert_equal(true, action.defined_parameters['full_name']['required'])
      assert_equal(nil, action.defined_parameters['full_name']['validation_callback'])

      assert_equal('Years old', action.defined_parameters['age']['description'])
      assert_equal(Integer, action.defined_parameters['age']['type'])
      assert_equal('e.g., 33', action.defined_parameters['age']['prompt'])
      assert_equal(35, action.defined_parameters['age']['default'])
      assert_equal(false, action.defined_parameters['age']['required'])
      assert_equal(nil, action.defined_parameters['age']['validation_callback'])

      assert_equal('City name', action.defined_parameters['city']['description'])
      assert_equal(String, action.defined_parameters['city']['type'])
      assert_equal('e.g., Pullman', action.defined_parameters['city']['prompt'])
      assert_equal(nil, action.defined_parameters['city']['default'])
      assert_equal(true, action.defined_parameters['city']['required'])
      assert_equal('validate_city_name', action.defined_parameters['city']['validation_callback'])

      assert_equal('Is a customer', action.defined_parameters['customer']['description'])
      assert_equal(Boolean, action.defined_parameters['customer']['type'])
      assert_equal(nil, action.defined_parameters['customer']['prompt'])
      assert_equal(nil, action.defined_parameters['customer']['default'])
      assert_equal(true, action.defined_parameters['customer']['required'])
      assert_equal(nil, action.defined_parameters['customer']['validation_callback'])

      assert_equal('Full birthday', action.defined_parameters['birthday']['description'])
      assert_equal(Date, action.defined_parameters['birthday']['type'])
      assert_equal(nil, action.defined_parameters['birthday']['prompt'])
      assert_equal(nil, action.defined_parameters['birthday']['default'])
      assert_equal(true, action.defined_parameters['birthday']['required'])
      assert_equal(nil, action.defined_parameters['birthday']['validation_callback'])

    end
  end

  def assert_valid_params(parameters)
    a = Armagh::AliceAction.new(@caller, @logger, parameters)
    assert_true a.valid?, "Invalid: #{ a.validation_errors }"
  end

  def assert_has_errors(parameters, expected_error_hash)
    a = Armagh::AliceAction.new(@caller, @logger, parameters)
    refute a.valid?, 'Expected errors but got none'
    reported_error_hash = a.validation_errors
    reported_error_hash.each do |param, msg|
      expected_error_msg = expected_error_hash.delete param
      reported_error_msg = reported_error_hash.delete param
      assert_equal(expected_error_msg, reported_error_msg, "Wrong error message for #{param}")
    end
    assert_empty(expected_error_hash, "Didn't receive expected errors: ")
    assert_empty(reported_error_hash, 'Received unexpected errors: ')
  end

  def base_params
    age = 50
    bday = Date.today.prev_year(age)
    {'full_name' => 'Beaumont Schneidermann', 'city' => 'Springfield', 'customer' => true, 'birthday' => bday, 'age' => age}
  end

  def test_good_params
    assert_valid_params(base_params)
  end

  def test_missing_required
    missing_reqs_params = base_params
    missing_reqs_params.delete 'city'
    assert_has_errors(missing_reqs_params, {'city' => 'Required parameter is missing.'})
  end

  def test_type_mismatch_string
    mismatched_string_params = base_params
    mismatched_string_params.merge!('full_name' => 10)
    assert_has_errors(mismatched_string_params, {'full_name' => 'Invalid type.  Expected String but was Fixnum.'})
  end

  def test_type_mismatch_integer
    mismatched_integer_params = base_params.merge!({'age' => 'yo'})
    assert_has_errors(mismatched_integer_params, {'age' => 'Invalid type.  Expected Integer but was String.'})
  end

  def test_type_mismatch_date
    mismatched_date_params = base_params.merge({'birthday' => 'yo'})
    assert_has_errors(mismatched_date_params, {'birthday' => 'Invalid type.  Expected Date but was String.'})
  end

  def test_type_mismatch_boolen
    mismatched_boolean_params = base_params.merge({'customer' => 66})
    assert_has_errors(mismatched_boolean_params, {'customer' => 'Invalid type.  Expected Boolean but was Fixnum.'})
  end

  def test_failed_custom_validation
    bad_age_params = base_params.merge({'age' => 3})
    assert_has_errors(bad_age_params, {'_all' => "Age and birthday don't agree"})
  end

  def test_bad_params_def_nonstring_name
    err = assert_raises(Armagh::ParameterError) do
      Armagh::FredAction.class_eval("define_parameter( 123, '44', Integer, 'prompt'=>'e.g., 33', 'default'  => 35)")
    end
    assert_equal('Parameter name needs to be a String', err.message)
  end

  def test_bad_params_def_nonstring_description
    err = assert_raises(Armagh::ParameterError) do
      Armagh::FredAction.class_eval("define_parameter( 'age', 44, Integer, 'prompt'=>'e.g., 33', 'default'  => 35)")
    end
    assert_equal("Parameter age's description must be a String", err.message)
  end

  def test_bad_params_def_nonstring_prompt
    err = assert_raises(Armagh::ParameterError) do
      Armagh::FredAction.class_eval("define_parameter( 'age', 'Age', Integer, 'prompt'=>33, 'default'  => 35)")
    end
    assert_equal("Parameter age's prompt must be a String", err.message)
  end

  def test_bad_params_default_class
    err = assert_raises(Armagh::ParameterError) do
      Armagh::FredAction.class_eval("define_parameter( 'age', 'Age', Integer, 'prompt'=>'e.g. 33', 'default'  => 'Hello')")
    end
    assert_equal("Parameter age's default is the wrong type", err.message)
  end

  def test_bad_params_required_not_bool
    err = assert_raises(Armagh::ParameterError) do
      Armagh::FredAction.class_eval("define_parameter( 'age', 'Age', Integer, 'prompt'=>'e.g. 33', 'required' => 42)")
    end
    assert_equal("Parameter age's required flag is not a boolean", err.message)
  end

  def test_param_multiple_defines
    err = assert_raises(Armagh::ParameterError) do
      Armagh::FredAction.class_eval("define_parameter( 'no', 'Bad', String)")
      Armagh::FredAction.class_eval("define_parameter( 'no', 'Bad', String)")
    end
    assert_equal("A parameter named 'no' already exists.", err.message)
  end

  def test_default_input_doctype
    assert_nil Armagh::FredAction.default_input_doctype
    doctype = 'InputDocType'
    Armagh::FredAction.class_eval("define_default_input_doctype('#{doctype}')")
    assert_equal(doctype, Armagh::FredAction.default_input_doctype)
  end

  def test_multiple_default_input_doctype
    err = assert_raises(Armagh::DoctypeError) do
      Armagh::FredAction.class_eval("define_default_input_doctype('Doctype')")
      Armagh::FredAction.class_eval("define_default_input_doctype('Doctype')")
    end
    assert_equal('Default Input Doctype already defined', err.message)
  end

  def test_default_output_doctype
    assert_nil Armagh::FredAction.default_output_doctype
    doctype = 'OutputDocType'
    Armagh::FredAction.class_eval("define_default_output_doctype('#{doctype}')")
    assert_equal(doctype, Armagh::FredAction.default_output_doctype)
  end

  def test_multiple_default_output_doctype
    err = assert_raises(Armagh::DoctypeError) do
      Armagh::FredAction.class_eval("define_default_output_doctype('Doctype')")
      Armagh::FredAction.class_eval("define_default_output_doctype('Doctype')")
    end
    assert_equal('Default Output Doctype already defined', err.message)
  end

  def test_no_implemented_execute
    a = Armagh::AliceAction.new(@caller, @logger, base_params)

    err = assert_raise(Armagh::ActionExecuteNotImplemented) do
      a.execute(nil)
    end
    assert_equal('The execute method needs to be overwritten by Armagh::AliceAction', err.message)
  end

  def test_implemented_execute
    f = Armagh::FredAction.new(@caller, @logger, base_params)
    assert_true(f.execute(nil))
  end

  def test_update_config
    a = Armagh::AliceAction.new(@caller, @logger, base_params)
    assert_true a.valid?
    new_params = base_params.merge({'age' => 'yo'})
    a.config = new_params
    assert_false a.valid?
  end

  def test_update_document
    a = Armagh::AliceAction.new(@caller, @logger, base_params)
    id = 'id'
    content = 'content'
    meta = 'meta'
    @caller.expects(:update_document).with(id, content, meta, Armagh::DocState::PUBLISHED)
    a.update_document(id: id, content: content, meta: meta,)
  end

  def test_insert_document
    a = Armagh::AliceAction.new(@caller, @logger, base_params)
    id = 'id'
    content = 'content'
    meta = 'meta'
    @caller.expects(:insert_document).with(nil, content, meta, Armagh::DocState::PUBLISHED)
    a.insert_document(content: content, meta: meta)

    @caller.expects(:insert_document).with(id, content, meta, Armagh::DocState::PUBLISHED)
    a.insert_document(id: id, content: content, meta: meta)
  end

  def test_insert_or_update_document
    a = Armagh::AliceAction.new(@caller, @logger, base_params)
    id = 'id'
    content = 'content'
    meta = 'meta'
    @caller.expects(:insert_or_update_document).with(id, content, meta, Armagh::DocState::PUBLISHED)
    a.insert_or_update_document(id: id, content: content, meta: meta)
  end

  def test_modify
    a = Armagh::AliceAction.new(@caller, @logger, base_params)
    id = '123'
    doc = mock
    doc.expects(:content)
    @caller.expects(:modify).yields(doc).returns(true)
    result = a.modify(id) do
      doc.content
    end

    assert_true result
  end

  def test_modify!
    a = Armagh::AliceAction.new(@caller, @logger, base_params)
    id = '123'
    doc = mock
    doc.expects(:content)
    @caller.expects(:modify!).yields(doc).returns(true)
    result = a.modify!(id) do
      doc.content
    end

    assert_true result
  end
end
