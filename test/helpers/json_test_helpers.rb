module JSONTestHelpers
  def combine_parts(parts)
    json_parts = parts.map { |p| JSON.parse(p) }
    h = {}
    h["employees"] = []
    json_parts.each do |json_part|
      json_part.each do |k,v|
        if k != "employees"
          h[k] = v if h[k].nil?
        else
          h["employees"] << v unless h["employees"].include?(v)
        end
      end
    end
    h["employees"] = h["employees"].flatten
    h
  end

  def parts_sizes(parts)
    parts.map(&:size)
  end

  def load_expected_content(file_path)
    YAML.load_file(file_path)
  end
end

