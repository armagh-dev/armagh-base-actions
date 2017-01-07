# Copyright 2017 Noragh Analytics, Inc.
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


module FixtureHelper

  def set_fixture_dir(dir)
    @fixture_dir = dir
  end

  def fixture_path(filename)
    File.expand_path(
      File.join(
        File.dirname(__FILE__),
        '..',
        'fixtures',
        @fixture_dir.to_s,
        filename
      )
    )
  end

  def fixture(filename, content = nil)
    path = fixture_path(filename)
    dir  = File.dirname(path)
    Dir.mkdir(dir) unless File.directory?(dir)

    if content && !File.exist?(path)
      File.open(path, 'w') { |f| f << content }
      puts "WARNING: New fixture written: #{path[/\/(test\/fixtures\/.+)$/, 1]}"
    end

    if ['.txt', '.text', '.csv', '.xml', '.htm', '.html'].include?(File.extname(filename.downcase))
      File.read(path).strip
    else
      File.binread(path)
    end
  end

end
