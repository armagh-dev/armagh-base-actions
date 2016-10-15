#
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
#

require 'timeout'
require 'mongo'

module Armagh
  module Actions

    class ActionStateTimeoutError < StandardError; end
    class ActionStateError < StandardError; end
    
    module Stateful
      
      def with_locked_action_state( collection, timeout ) 
        
        name = @config&.action&.name || 'default'
        begin
          action_state_doc = ActionStateDocument.find_or_create( collection, name, Process.pid, timeout )
          yield action_state_doc
        ensure
          action_state_doc.save_and_unlock if action_state_doc
        end
      end
    end
       
    class ActionStateDocument
      attr_accessor :state_doc_id, :locked_by, :content
      
      def self.find_or_create( collection, action_name, pid, timeout = 10 )
        
        state_doc_id = "#{action_name}_state"
        
        doc = collection.find_one_and_update(
          { '_id' => state_doc_id, 'locked_by' => nil },
          { '$set' => {'locked_by' => pid, 'locked_at' => Time.now }},
          :return_document => :after
        )
        
        if doc.nil?
          begin     
            doc = { '_id' => state_doc_id, 'type' => name, 'locked_by' => pid, 'locked_at' => Time.now, 'content' => {} }
            collection.insert_one( doc )
          rescue
            doc = nil
          end
          
          begin
            
            Timeout::timeout( timeout ) do
                        
             while doc.nil?
               doc = collection.find_one_and_update(
                 { '_id' => state_doc_id, 'locked_by' => nil },
                 { '$set' => {'locked_by' => pid, 'locked_at' => Time.now }},
                 :return_document => :after
               )
               sleep 1 unless doc
              end
            end 
          rescue Timeout::Error 
            raise ActionStateTimeoutError
          end
        end
        
        new(  collection, doc['_id'], doc['locked_by'], doc['content'] )
      end
              
      def initialize( collection, state_doc_id, pid, content = {} )
        @collection = collection
        @state_doc_id = state_doc_id
        @content = content 
        @locked_by = pid
      end
      
      
      def save
        
        raise ActionStateError.new( "Content must be a hash") unless @content.is_a?( Hash )
        raise ActionStateError.new( "Cannot save unless you have the lock") unless @locked_by
        
        @collection.find_one_and_update(
          { '_id' => @state_doc_id, 'locked_by' => @locked_by },
          { '$set' => { 'content' => @content }}
        )
        
      end

      def save_and_unlock
        
        raise ActionStateError.new( "Content must be a hash") unless @content.is_a?( Hash )
        raise ActionStateError.new( "Cannot save unless you have the lock") unless @locked_by
        
        @collection.find_one_and_update(
          { '_id' => @state_doc_id, 'locked_by' => @locked_by },
          { '$set' => { 'content' => @content, 'locked_by' => nil, 'locked_at' => nil }}
        )
        
        @locked_by = nil
        @locked_at = nil
      end
    end
  end
end