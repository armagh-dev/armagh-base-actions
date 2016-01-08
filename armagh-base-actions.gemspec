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

require_relative 'lib/armagh/base/actions/version'

Gem::Specification.new do |spec|
  spec.name          = 'armagh-base-actions'
  spec.version       = Armagh::Base::Actions::VERSION
  spec.authors       = ['Armagh Dev Team']
  spec.email         = 'armagh-dev@noragh.com'
  spec.summary       = 'Actions generator'
  spec.description   = ''
  spec.homepage      = ''
  spec.license       = 'APL 2.0'

  spec.files         = Dir.glob('{bin,lib,assets}/**/*') + %w(LICENSE.txt)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'noragh-gem-tasks'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'simplecov-rcov'


  # Don't add runtime dependencies.  This gem is provided to the client for development of their own actions.  Dependencies complicate the delivery process.
end
