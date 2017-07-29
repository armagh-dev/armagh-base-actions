require 'csv'
require_relative '../../base/errors/armagh_error'

class CSVDivider
  class CSVDividerError         < ArmaghError; notifies :dev; end
  class RowMissingValueError    < CSVDividerError; end
  class RowWithExtraValuesError < CSVDividerError; end

  DEFAULT_SIZE_PER_PART = 100
  DEFAULT_COL_SEP = ","
  DEFAULT_ROW_SEP = "\n"
  DEFAULT_QUOTE_CHAR = '"'

  LINE_SCAN_REGEX = /(?:[\w|\d|\-|@|\.]|"[^"]*")+/

  attr_reader :source, :file, :row_sep, :col_sep, :quote_char, :size_per_part
  attr_accessor :divided_parts, :line, :offset

  def initialize(source, options = {})
    @source        = source
    @size_per_part = options['size_per_part'] || DEFAULT_SIZE_PER_PART
    @col_sep       = options['col_sep']       || DEFAULT_COL_SEP
    @row_sep       = options['row_sep']       || DEFAULT_ROW_SEP
    @quote_char    = options['quote_char']    || DEFAULT_QUOTE_CHAR

    @divided_parts   = []
  end

  def file
    @file ||= File.open(source)
  end

  def divide
    file.each_line(row_sep) do |current_line|
      # current_line = current_line.gsub(col_sep, DEFAULT_COL_SEP) unless col_sep == DEFAULT_COL_SEP
      # current_line = current_line.gsub(row_sep, DEFAULT_ROW_SEP) unless row_sep == DEFAULT_ROW_SEP
      @line = current_line

      #TODO: refactor to remove nested if/elsif's
      if divided_parts.empty?
        add_header_to_divided_parts
      elsif file.eof?
        if divided_part_plus_line_size <= size_per_part
          add_line_to_divided_part
          yield divided_parts.join
        elsif divided_part_plus_line_size > size_per_part
          yield divided_parts.join

          @divided_parts = []
          add_header_to_divided_parts
          add_line_to_divided_part

          yield divided_parts.join
        end
      elsif !file.eof?
        raise RowMissingValueError    if line.scan(LINE_SCAN_REGEX).count < header_count
        raise RowWithExtraValuesError if line.scan(LINE_SCAN_REGEX).count > header_count

        if divided_part_plus_line_size <= size_per_part
          add_line_to_divided_part
        elsif divided_part_plus_line_size > size_per_part
          yield divided_parts.join

          @divided_parts = []
          add_header_to_divided_parts
          add_line_to_divided_part
        end
      end

      #TODO: consider adding error handling here
    end
    file.close
  end

  private def add_line_to_divided_part
    divided_parts << @line
  end

  private def divided_part_plus_line_size
    sub_string_size + line.size
  end

  private def sub_string_size
    divided_parts.map(&:size).sum
  end

  private def add_header_to_divided_parts
    @headers ||= line
    divided_parts << headers
  end

  private def header_count
    @header_count ||= headers.scan(LINE_SCAN_REGEX).count
  end

  private def headers
    @headers
  end

end
