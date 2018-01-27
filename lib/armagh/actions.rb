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

require 'facets/kernel/constant'

Dir[File.join(__dir__, 'actions', '*.rb')].each { |file| require file }

module Armagh
  module Actions

    BASE_ACTION_TYPES = [Collect, Consume, Divide, Publish, Split]

    TEMPLATE_PATH = File.join('lib', 'armagh', 'templates', '')

    def self.defined_actions
      actions = []

      modules = %w(StandardActions CustomActions).collect do |mod|
        begin
          Armagh.const_get mod
        rescue
        end
      end

      modules.compact!

      modules.each do |mod|
        new_actions = mod.constants.collect do |c|
          klass = nil
          maybe_class = mod.const_get(c)

          if maybe_class.is_a?(Class)
            BASE_ACTION_TYPES.each do |type|
              if maybe_class < type
                klass = maybe_class
                break
              end
            end
          end

          klass
        end

        actions.concat new_actions.sort_by! { |a| a.to_s }
      end

      actions.compact!
      actions
    end

    def self.available_templates
      templates = []
      @template_name_map = {}

      Gem.loaded_specs.each do |gem_name, spec|
        package_name = if gem_name.end_with? '-standard_actions'
                         'StandardActions'
                       elsif gem_name.end_with? '-custom_actions'
                         'CustomActions'
                       else
                         nil
                       end

        if package_name
          template_dir = File.join(spec.gem_dir, TEMPLATE_PATH)
          Dir.glob(File.join(template_dir, '*', '*')).select{|f| File.file? f}.each do |file|
            template_name = "#{file.sub(template_dir, '')} (#{package_name})"
            @template_name_map[template_name] = file
            templates << template_name
          end
        end
      end

      templates.sort!
      templates
    end

    def self.get_template_path(template_name)
      return nil if template_name.nil?
      available_templates unless @template_name_map
      @template_name_map[template_name]
    end

    def self.name_to_class(action_class_name)
      klass = nil
      begin
        klass = constant( action_class_name )
      rescue
        raise "Action class name #{action_class_name} not valid"
      end

      unless defined_actions.include?( klass )
        raise "Class #{action_class_name} is not a defined standard or custom action"
      end

      klass
    end
  end
end
