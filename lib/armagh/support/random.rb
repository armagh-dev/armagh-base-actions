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
  module Support
    module Random
      RANDOM_ID_LENGTH = 20

      CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a

      module_function

      def random_id
        random_str(RANDOM_ID_LENGTH)
      end

      def random_str(length)
        CHARS.sample(length).join
      end
    end
  end
end
