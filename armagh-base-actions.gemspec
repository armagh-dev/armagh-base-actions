# coding: utf-8
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

require_relative 'lib/armagh/base/actions/name'
require_relative 'lib/armagh/base/actions/version'

def get_build_version(version)
  if ENV['ARMAGH_PRODUCTION_RELEASE']
    version
  else
    revision = `hg identify --num 2>/dev/null`.strip.gsub('+', '-dev')
    if revision.empty?
      "#{version}-dev"
    else
      "#{version}.#{revision}"
    end
  end
rescue
  "#{version}-dev"
end

Gem::Specification.new do |spec|
  spec.name          = Armagh::Base::Actions::NAME
  spec.version       = get_build_version Armagh::Base::Actions::VERSION
  spec.authors       = ['Armagh Dev Team']
  spec.email         = 'armagh-dev@noragh.com'
  spec.summary       = 'Actions generator'
  spec.description   = ''
  spec.homepage      = ''
  spec.license       = 'Apache-2.0'

  spec.files         = Dir.glob('{bin,lib,assets}/**/*') + %w(README LICENSE)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'ox', '~> 2.4'
  spec.add_dependency 'bson', '~> 4.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'noragh-gem-tasks', '~> 0.1'
  spec.add_development_dependency 'test-unit', '~> 3.0'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'simplecov', '~> 0.11'
  spec.add_development_dependency 'simplecov-rcov', '~> 0.2'
  spec.add_development_dependency 'fakefs', '~> 0.6'
  spec.add_development_dependency 'yard', '~> 0.8'
end
