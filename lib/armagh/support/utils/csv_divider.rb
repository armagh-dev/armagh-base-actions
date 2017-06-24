class CSVDivider

  attr_reader :source
  attr_accessor :sub_string, :offset

  def initialize(source, options = {})
    @source = source
    @offset        = options[:offset] || 0
    @size_per_part = options[:size_per_part]
    @col_sep       = options[:col_sep]
  end

  def divide
    eof = false

    while eof == false
      @sub_string      = IO.read(source, @size_per_part, @offset)
      @sub_string_size = sub_string.size

      find_previous_complete_record if last_line_has_partial_record?

      yield current_sub_string

      @offset += @sub_string.size
      eof    = true if reached_last_part_from_file?
    end
  end

  private def headers
    @headers ||= divided_part_header
  end

  private def header_count
    @header_count ||= headers.scan(@col_sep).count
  end

  private def last_line_count
    last_line.scan(@col_sep).count
  end

  private def current_sub_string
    if @offset == 0
      sub_string
    else
      headers + sub_string
    end
  end

  private def divided_part_header
    headers = sub_string.lines.first
  end

  private def last_line
    sub_string.lines.last
  end

  private def reached_last_part_from_file?
    last_line_not_dropped? && within_max_size?
  end

  private def last_line_not_dropped?
    @sub_string_size == sub_string.size
  end

  private def find_previous_complete_record
    until (last_line_has_complete_record? && within_max_size?)
      @sub_string = drop_last_line_from_sub_string
      last_line_count = last_line.scan(@col_sep).count
    end
  end

  private def last_line_has_partial_record?
    (last_line_count != header_count) && (@sub_string_size >= @size_per_part)
  end

  private def last_line_has_complete_record?
    last_line_count == header_count
  end

  private def within_max_size?
   @sub_string_size <= @size_per_part
  end

  private def drop_last_line_from_sub_string
    return sub_string if sub_string.lines.count == 1
    lines = sub_string.lines
    lines.pop
    lines.join
  end
end
