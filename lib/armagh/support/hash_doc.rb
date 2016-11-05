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

module Armagh
  module Support
    class HashDoc < Hash
      attr_accessor :allow_missing, :show_empty_array, :enum_format

      class HashDocError             < StandardError; end
      class TypeMismatchError        < HashDocError; end
      class InvalidReferenceError    < HashDocError; end
      class InvalidEnumHashDocError  < HashDocError; end
      class InvalidConcatLayoutError < HashDocError; end
      class MissingBlockError        < HashDocError
        attr_accessor :message
        def initialize() @message = 'No block given (yield)' end
      end

      def initialize(hash = nil)
        set(hash) if hash
      end

      def set(hash)
        raise TypeMismatchError, "Hash object expected, instead: #{hash.class}" unless hash.is_a?(Hash)
        clear
        update(hash)
        @ref = hash
      end

      def get(*nodes, default: nil, allow_missing: nil)
        value = get_node(*nodes, allow_missing: allow_missing)
        ['', nil].include?(value) && default ? default : value
      end

      def with(*nodes, allow_missing: nil)
        raise MissingBlockError unless block_given?
        restore = @ref
        @ref = get_node(*nodes, allow_missing: allow_missing)
        yield
      ensure
        @ref = restore
      end

      def loop(*nodes, show_empty: nil, allow_missing: nil)
        raise MissingBlockError unless block_given?
        parent = get_node(*nodes, allow_missing: allow_missing) || []
        parent = [parent] unless parent.is_a?(Array)
        restore = @ref
        if parent.empty? && (show_empty || @show_empty_array)
          @ref = parent
          yield 1
          @ref = restore
          return
        end
        parent.each_with_index do |ref, index|
          @ref = ref
          yield index + 1
        end
      ensure
        @ref = restore
      end

      def enum(*nodes, hash, format: nil, allow_missing: nil)
        raise InvalidEnumHashDocError, %q(Please provide a valid enum hash lookup, e.g., {'value'=>'description', nil=>['else', 'lookup not found']}) unless hash.is_a?(Hash)
        format ||= @enum_format
        value  = get_node(*nodes, allow_missing: allow_missing)
        result = hash[value]
        result =
          if result
            [value, result]
          else
            hash_else = hash[nil]
            if hash_else
              if hash_else.is_a?(Array)
                hash_else.size == 2 ? hash_else : [value, hash_else.first]
              else
                [value, hash_else]
              end
            else
              [value, nil]
            end
          end
        if format
          return value.to_s unless result.last
          return result.last if result.last && result.first.to_s.strip.empty?
          format % (format.sub(/%s/, '').include?('%s') ? result : result.last)
        else
          result
        end
      end

      def concat(layout, allow_missing: nil)
        raise InvalidConcatLayoutError, "Must be String, instead: #{layout.class}" unless layout.is_a?(String)
        result  = delim = ''
        pattern = /[A-Za-z0-9_\.]+/
        prefix  = layout[/^(.*?)@/m, 1]
        suffix  = layout.reverse[/^(.*?)#{pattern}@/m, 1].reverse
        text    = layout.split(/@#{pattern}/)
        text.shift if !text.empty? && (text.first.empty? || !prefix.empty?)
        fields  = layout.scan(/@#{pattern}/)
        fields.each_with_index do |field, index|
          field.sub!(/^@/, '')
          value = get_node(field, allow_missing: allow_missing)
          unless value.to_s.strip.empty?
            result << delim unless delim.empty?
            result << value.to_s.strip
            delim = text[index]
          end
        end
        result.empty? ? '' : "#{prefix}#{result}#{suffix}"
      end

      def find_all(node, source = @ref)
        return [] unless source.is_a?(Hash)
        result  = []
        restore = @ref
        @ref    = source
        value   = get_node(node, allow_missing: true)
        @ref    = restore
        result << value if value
        source.each do |k, v|
          case v
          when Hash
            result += find_all(node, v)
          when Array
            v.each { |va| result += find_all(node, va) }
          else
            []
          end
        end
        result
      end

      def audit
        raise MissingBlockError unless block_given?
        @audit = {}
        yield
        process_audit
        audit = {}
        @audit.sort.each do |field, count|
          count = count.to_i
          audit[count] ||= []
          audit[count] << field
        end
        @audit = nil
        Hash[audit.sort_by { |field| field }]
      end

      private def get_node(*nodes, allow_missing: nil)
        return @ref if nodes.empty?
        allow_missing ||= @allow_missing
        nodes.map! { |node| node = node.is_a?(Symbol) ? node.to_s : node }
        if nodes.size == 1 && nodes.first.include?('.')
          nodes = nodes.first.split('.')
          nodes.map! { |f| f[/^\d+$/] ? f.to_i : f }
        end
        audit_field(nodes.last)
        result = @ref.dig(*nodes)
        raise InvalidReferenceError, nodes.inspect unless result || allow_missing
        result
      rescue TypeError => e
        case e.message
        when 'no implicit conversion of String into Integer',
             'String does not have #dig method',
             'Fixnum does not have #dig method'
          return nil if allow_missing
          raise InvalidReferenceError, nodes.to_s
        end
        raise e
      end

      private def audit_field(field)
        return unless @audit
        @audit[field.to_s] ||= 0
        @audit[field.to_s]  += 1
      end

      private def process_audit(source = @ref)
        if source.is_a?(Array)
          source.each { |ref| process_audit(ref) }
        else
          source.each do |key, value|
            if value.is_a?(Hash) || value.is_a?(Array)
              process_audit(value)
            else
              @audit[key.to_s] ||= nil
            end
          end
        end
      end

    end
  end
end
