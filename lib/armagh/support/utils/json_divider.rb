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
#

require_relative '../../base/errors/armagh_error'
require_relative '../../documents/action_document'
require_relative '../encoding'
require_relative '../../../ext_json_divider'

class JSONDivider
  include Armagh::Support::Encoding
  include ExtJSONDivider

  class JSONDividerError < ArmaghError; notifies :dev; end
  class JSONParseError                        < JSONDividerError; notifies :dev; end
  class ExtJSONDividerError                   < JSONDividerError; notifies :dev; end
  class SizeError                             < JSONDividerError; notifies :dev; end
  class DivideTargetNotFoundInFirstChunkError < JSONDividerError; notifies :dev; end
  class SizePerPartTooSmallError              < JSONDividerError; notifies :dev; end

  DEFAULT_SIZE_PER_PART   = Armagh::Documents::ActionDocument::RAW_MAX_LENGTH - 1024
  DEFAULT_SOURCE_ENCODING = Armagh::Support::Encoding::TARGET_ENCODING
  C_EXT_ENCODINGS         = %w{UTF-8 US-ASCII ASCII-8BIT}.collect { |enc| ::Encoding.find(enc)}.uniq

  attr_reader :source, :source_encoding, :size_per_part, :divide_target, :header, :footer

  def initialize(source, options = {})
    @source          = source
    @source_encoding = options['source_encoding'] || DEFAULT_SOURCE_ENCODING
    @size_per_part   = options['size_per_part']   || DEFAULT_SIZE_PER_PART
    @divide_target   = options['divide_target']

    begin
      @source_encoding = ::Encoding.find(@source_encoding)
    rescue
      raise JSONDividerError, "invalid source_encoding: #{@source_encoding}"
    end

    raise JSONDividerError, "file #{@source} either doesn't exist or is not readable"  unless File.readable? @source
    raise JSONDividerError, "size_per_part must be a positive integer"  unless @size_per_part.is_a?(Integer) && @size_per_part > 0

    raise JSONDividerError, "divide_target must be a String"  unless @divide_target.is_a?(String)
    if @divide_target.encoding != @source_encoding
      begin
        ## cannot use fix_encoding, because that would encode to TARGET_ENCODING
        @divide_target.encode!(@source_encoding)
      rescue => e
        raise JSONDividerError, "divide_target.encode(#{@source_encoding.name}) failed: #{e}"
      end
    end
    raise JSONDividerError, "divide_target fails valid_encoding?()"  unless @divide_target.valid_encoding?
    @divide_target = @divide_target.strip  if @divide_target.is_a? String
    raise JSONDividerError, "divide_target must be a non-blank String"  unless @divide_target.is_a?(String) && !(@divide_target.empty?)

    @header      = ""
    @footer      = ""
    @element_map = []
  end

  def divide
    @header      = ""
    @footer      = ""
    @element_map = []

    file_size = File.size(@source)
    @element_map << Element.new(file_size, 0)  if file_size <= @size_per_part

    ## for if cond, first tried @source_encoding.ascii_compatible?,
    ## but got SEGV, and debugging pointed to regcomp() when divide_target
    ## was 'non_ascii_°_char', even for ISO-8859-1, which is an 8-bit encoding;
    ## thus, looks like C regcomp expects UTF-8 or an ASCII varient
    @header, @footer = ext_json_divide(@size_per_part, @divide_target, @source, @element_map)  if @element_map.empty? && C_EXT_ENCODINGS.include?(@source_encoding)

    if @element_map.empty?
      ## ruby divider
      raise JSONDividerError, "ruby JSON divider not yet implemented"
    end

    @header = Armagh::Support::Encoding.fix_encoding(@header, proposed_encoding: @source_encoding.name)
    @footer = Armagh::Support::Encoding.fix_encoding(@footer, proposed_encoding: @source_encoding.name)

    raise SizeError, "The 'header + footer' size for #{File.basename(@source)} is #{header_footer_size}, which is greater than the size_per_part of: #{@size_per_part}"  if header_footer_too_large?
    raise SizePerPartTooSmallError, "The size_per_part for #{File.basename(@source)} needs to be at least #{minimum_divided_part_size}"  if size_per_part_too_small?

    divided_parts.each do |part|
      yield part
    end
  end

  def divided_parts
    grouped_map.each_with_object([]) do |group, ary|
      s = ""
      s << @header

      group.each do |e|
        s << Armagh::Support::Encoding.fix_encoding(e.content_from(@source), proposed_encoding: @source_encoding.name)
        s << "," unless e == group.last
      end

      s << @footer
      ary << s
    end
  end

  def grouped_map
    grouped_elements = []

    @element_map.each_with_object([]) do |e, ary|
      if (grouped_elements.map(&:bytesize).sum + e.bytesize) < (@size_per_part - header_size - footer_size)
        grouped_elements << e
      else
        ary << grouped_elements
        grouped_elements = []
        grouped_elements << e
      end

      if e == @element_map.last
        grouped_elements << e unless grouped_elements.include?(e)
        ary << grouped_elements
      end
    end
  end

  Element = Struct.new(:bytesize, :offset) do
    def content_from(source)
      IO.read(source, bytesize, offset)
    end
  end

  private def header_size
    @header.bytesize
  end

  private def footer_size
    @footer.bytesize
  end

  private def header_footer_size
    header_size + footer_size
  end

  private def header_footer_too_large?
    header_footer_size > @size_per_part
  end

  private def minimum_divided_part_size
    @element_map.map {|e| (header_size + e.bytesize + footer_size) }.max
  end

  private def size_per_part_too_small?
    @size_per_part < minimum_divided_part_size
  end

end
