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

Dir[File.join(__dir__, 'actions', '*.rb')].each { |file| require file }

module Armagh
  module Actions

    BASE_ACTION_TYPES = [Collect, Consume, Divide, Publish, Split]

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
        actions.concat mod.constants.collect {|c|
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
        }
      end

      actions.compact!
      actions
    end

    def self.name_to_class(action_class_name)

      klass = nil
      begin
        klass = eval( action_class_name )
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