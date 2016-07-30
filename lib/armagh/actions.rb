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

Dir[File.join(__dir__, 'actions', '*.rb')].each { |file| require file }

module Armagh
  module Actions
    def self.defined_actions
      load_actions_and_dividers unless @defined_actions
      @defined_actions.dup
    end

    def self.defined_dividers
      load_actions_and_dividers unless @defined_dividers
      @defined_dividers.dup
    end

    private_class_method def self.load_actions_and_dividers
      @defined_actions = []
      @defined_dividers = []

      packages = []
      packages << CustomActions if defined? CustomActions
      packages << StandardActions if defined? StandardActions

      packages.each do |package|
        next unless defined? package
        package.constants.each do |name|
          class_name = "#{package}::#{name}"
          const_obj = package.const_get(class_name)
          if const_obj.is_a?(Class)
            if const_obj < Actions::Action
              @defined_actions << const_obj
            elsif const_obj < Actions::Divide
              @defined_dividers << const_obj
            end
          end
        end
      end
    end
  end
end