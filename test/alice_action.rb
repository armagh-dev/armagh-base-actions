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

require_relative '../lib/armagh/action'

module Armagh
	class AliceAction < Armagh::Action
	
		define_parameter( 'full_name', 'Full name',    String,   'prompt' =>'e.g., Jane Doe', 'required' => true )
		define_parameter( 'age',      'Years old',     Integer,  'prompt' =>'e.g., 33',       'default'  => 35   )
		define_parameter( 'city',     'City name',     String,   'prompt' =>'e.g., Pullman',  'required' => true, 'validation_callback' => 'validate_city_name' )
		define_parameter( 'customer', 'Is a customer', Boolean,                              	'required' => true )
		define_parameter( 'birthday', 'Full birthday', Date,                                 	'required' => true )
		
		def validate_city_name( city )
			return 'City must be a string that starts with an S' unless (city.is_a? String and city[/S/])
			return nil
		end
		
		def validate
			unless Date.today.between?(@config['birthday'] >> (@config['age']*12), @config['birthday'] >> (@config['age']*12) + 1)
			  return "Age and birthday don't agree"
			end
			return nil
		end
	end
end