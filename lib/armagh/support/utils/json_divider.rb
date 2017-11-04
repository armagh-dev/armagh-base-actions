require_relative '../../base/errors/armagh_error'

class JSONDivider
  class JSONDividerError < ArmaghError; notifies :dev; end
  class SizeError                             < JSONDividerError; notifies :dev; end
  class DivideTargetNotFoundInFirstChunkError < JSONDividerError; notifies :dev; end
  class SizePerPartTooSmallError              < JSONDividerError; notifies :dev; end

  DEFAULT_SIZE_PER_PART = 250
  DEFAULT_DIVIDE_TARGET = "employees"

  LEFT_CURLY    = '{'
  RIGHT_CURLY   = '}'
  LEFT_BRACKET  = '['
  RIGHT_BRACKET = ']'
  DOUBLE_QUOTE  = '"'
  BACKSLASH     = '\\'

  attr_reader :source, :file, :size_per_part, :divide_target
  attr_accessor :divided_parts, :header, :footer, :errors

  def initialize(source, options = {})
    @source        = source
    @size_per_part = options['size_per_part'] || DEFAULT_SIZE_PER_PART
    @divide_target = options['divide_target'] || DEFAULT_DIVIDE_TARGET

    @stack         = []
    @buffer        = ""
    @header        = ""
    @footer        = ""
    @element_map   = []
    @errors        = []
  end

  def file
    @file ||= File.open(source)
  end

  def divide
    file.each_char do |char|
      case current_state
      when nil
        @stack.push(:start_of_file)
        @buffer << char
        @stack.push(:inside_string) if char == DOUBLE_QUOTE
      when :reached_max_size_per_part
        raise DivideTargetNotFoundInFirstChunkError unless divide_target_found?
      when :start_of_file
        @buffer << char

        if char == DOUBLE_QUOTE
          @stack.push(:inside_string)
        elsif (char == LEFT_BRACKET) && divide_target_found?
          raise SizeError, "The header_size for #{File.basename(source)} is #{header_size}, which is greater than the size_per_part of: #{size_per_part}" if header_too_large?
          @header = @buffer
          @stack.push(:inside_divide_target)
        else
          @stack.push(:reached_max_size_per_part) if reached_max_size_per_part?
        end
      when :backslash_inside_string
        @buffer << char if header_empty?
        @stack.pop
      when :inside_string
        @buffer << char if header_empty?

        if char == DOUBLE_QUOTE
          @stack.pop
        elsif char == BACKSLASH
          @stack.push(:backslash_inside_string)
        end
      when :inside_divide_target
        if char == DOUBLE_QUOTE
          @stack.push(:inside_string)
        elsif char == LEFT_CURLY
					element = Element.new
					element.offset = file.pos - 1
					@element_map << element
          @stack.push(:inside_divide_element_object)
        elsif char == RIGHT_BRACKET
          current_position = file.pos - 1
          @footer = IO.read(source, nil, current_position)
          raise SizeError, "The footer_size for #{File.basename(source)} is #{footer_size}, which is greater than the size_per_part of: #{size_per_part}" if footer_too_large?
          raise SizeError, "The 'header + footer' size for #{File.basename(source)} is #{header_footer_size}, which is greater than the size_per_part of: #{size_per_part}" if header_footer_too_large?
          @stack.push(:end_of_divide_target)
        end
      when :inside_divide_element_object
        if char == DOUBLE_QUOTE
          @stack.push(:inside_string)
        elsif char == LEFT_CURLY
          @stack.push(:inside_nested_hash)
        elsif char == RIGHT_CURLY
          element = @element_map.last
          bytesize = file.pos - element.offset
          element.bytesize = bytesize
          @stack.pop
        end
      when :inside_nested_hash
        if char == DOUBLE_QUOTE
          @stack.push(:inside_string)
        elsif char == LEFT_CURLY
          @stack.push(:inside_nested_hash)
        elsif char == RIGHT_CURLY
          @stack.pop
        end
      when :end_of_divide_target
        @stack.push(:end_of_file)
      when :end_of_file
      end
    end

    if size_per_part_too_small?
      raise SizePerPartTooSmallError, "The size_per_part for #{File.basename(source)} needs to be at least #{minimum_divided_part_size}"
    end

    divided_parts.each do |part|
      yield part
    end
  end

  def divided_parts
    grouped_map.each_with_object([]) do |group, ary|
      s = ""
      s << @header

      group.each do |e|
        s << e.content_from(source)
        s << "," unless e == group.last
      end

      s << footer
      ary << s
    end
  end

  def grouped_map
    grouped_elements = []

    @element_map.each_with_object([]) do |e, ary|
      if (grouped_elements.map(&:bytesize).sum + e.bytesize) < (size_per_part - header_size - footer_size)
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

  private def current_state
    @stack.last
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

  private def header_too_large?
    header_size > size_per_part
  end

  private def footer_too_large?
    footer_size > size_per_part
  end

  private def header_footer_too_large?
    header_footer_size > size_per_part
  end


  private def buffer_size
    @buffer.bytesize
  end

  private def minimum_divided_part_size
    @element_map.map {|e| (header_size + e.bytesize + footer_size) }.max
  end

  private def divide_target_regex
    /\"#{divide_target}\"\s*:\s*\[/
  end

  private def divide_target_found?
    @buffer =~ divide_target_regex
  end

  private def reached_max_size_per_part?
    buffer_size >= size_per_part
  end

  private def header_empty?
    @header == ""
  end

  private def size_per_part_too_small?
    size_per_part < minimum_divided_part_size
  end

end

