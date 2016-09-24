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
      
      actions = []
      
      modules = [ "StandardActions", "CustomActions" ].collect{ |mod|
        begin
          Armagh.const_get mod 
        rescue
        end
      }.compact
      
      modules.each do |mod|
        actions.concat mod.constants.collect{ |c| 
          maybe_class = mod.const_get(c) 
          maybe_class if maybe_class.is_a?( Class )
        }.compact
      end
      
      actions
    end
  end
end