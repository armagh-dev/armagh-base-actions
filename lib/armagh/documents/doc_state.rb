# frozen_string_literal: true
#
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

module Armagh
  module Documents
    module DocState
      WORKING = 'working'.freeze
      READY = 'ready'.freeze
      PUBLISHED = 'published'.freeze

      def self.valid_state?(state)
        DocState::constants.collect { |c| DocState.const_get(c) }.include?(state)
      end
    end
  end
end