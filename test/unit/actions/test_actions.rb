# Copyright 2018 Noragh Analytics, Inc.
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

require 'fileutils'
require 'tmpdir'

require_relative '../../../lib/armagh/actions'

module Armagh
  module StandardActions
    class ThisTestCollect < Actions::Collect; end
    class ThisTestPublish < Actions::Publish; end
  end
  
  module CustomActions
    class ThatTestSplit < Actions::Split; end
    class InvalidClass; end
    class InvalidAction < Actions::Action; end
  end

  module Actions
    def self.reset_template_name_map
      @template_name_map = nil
    end
  end
end

class TestActions < Test::Unit::TestCase

  def test_defined_actions
    
    defined_classes = [
      Armagh::StandardActions::ThisTestCollect,
      Armagh::StandardActions::ThisTestPublish,
      Armagh::CustomActions::ThatTestSplit
    ]
    
    assert_equal defined_classes, Armagh::Actions.defined_actions
  end

  def test_available_templates
    client_spec = mock('client_spec')
    standard_spec = mock('standard_spec')
    another_spec = mock('another_spec')

    specs = {
      'some_client-custom_actions' => client_spec,
      'armagh-standard_actions' => standard_spec,
      'another_gem' => another_spec
    }

    Gem.expects(:loaded_specs).returns(specs)

    Dir.mktmpdir do |dir|
      client_gem_path = File.join(dir, 'client_gem')
      standard_gem_path = File.join(dir, 'standard_gem')
      client_gem_template_path = File.join(client_gem_path, Armagh::Actions::TEMPLATE_PATH)
      standard_gem_template_path = File.join(standard_gem_path, Armagh::Actions::TEMPLATE_PATH)

      client_spec.expects(:gem_dir).returns(client_gem_path)
      standard_spec.expects(:gem_dir).returns(standard_gem_path)


      FileUtils.mkdir_p File.join(client_gem_template_path, 'custom1')
      FileUtils.mkdir_p File.join(client_gem_template_path, 'custom2')
      FileUtils.mkdir_p File.join(client_gem_template_path, 'custom3')
      FileUtils.touch(File.join(client_gem_template_path, 'custom1', 'template_cust1.erubis'))
      FileUtils.touch(File.join(client_gem_template_path, 'custom2', 'template_cust2.erubis'))
      FileUtils.touch(File.join(client_gem_template_path, 'custom3', 'template_cust3.erubis'))

      FileUtils.mkdir_p File.join(standard_gem_template_path, 'standard1')
      FileUtils.mkdir_p File.join(standard_gem_template_path, 'standard2')
      FileUtils.mkdir_p File.join(standard_gem_template_path, 'standard3')
      FileUtils.touch(File.join(standard_gem_template_path, 'standard1', 'template_std1.erubis'))
      FileUtils.touch(File.join(standard_gem_template_path, 'standard2', 'template_std2.erubis'))
      FileUtils.touch(File.join(standard_gem_template_path, 'standard3', 'template_std3.erubis'))

      templates = Armagh::Actions.available_templates

      expected = ['custom1/template_cust1.erubis (CustomActions)',
                  'custom2/template_cust2.erubis (CustomActions)',
                  'custom3/template_cust3.erubis (CustomActions)',
                  'standard1/template_std1.erubis (StandardActions)',
                  'standard2/template_std2.erubis (StandardActions)',
                  'standard3/template_std3.erubis (StandardActions)']

      assert_equal expected, templates

      assert_equal File.join(client_gem_template_path, 'custom3', 'template_cust3.erubis'), Armagh::Actions.get_template_path('custom3/template_cust3.erubis (CustomActions)')
      assert_equal File.join(standard_gem_template_path, 'standard2', 'template_std2.erubis'), Armagh::Actions.get_template_path('standard2/template_std2.erubis (StandardActions)')
    end
  end

  def test_get_template_path_initial_call
    Armagh::Actions.reset_template_name_map
    Armagh::Actions.expects(:available_templates)
    begin
      Armagh::Actions.get_template_path('something')
    rescue NoMethodError
      # This isn't a problem.  We just want to make sure available_templates is called, but by doing so, we prevent the assignment of @template_name_map
    end
  end

  def test_name_to_class_good
    klass = Armagh::Actions.name_to_class('Armagh::StandardActions::ThisTestCollect')
    assert_equal Armagh::StandardActions::ThisTestCollect, klass
  end

  def test_name_to_class_doesnt_exist
    e = assert_raises do
      Armagh::Actions.name_to_class( 'blah' )
    end
    assert_equal 'Action class name blah not valid', e.message
  end

  def test_name_to_class_not_an_action
    e = assert_raises do
      Armagh::Actions.name_to_class( 'String' )
    end
    assert_equal 'Class String is not a defined standard or custom action', e.message
  end
end