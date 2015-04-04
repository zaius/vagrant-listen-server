# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-listen-server/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-listen-server'
  spec.version       = VagrantPlugins::ListenServer::VERSION
  spec.authors       = ['David Kelso']
  spec.email         = ['david@kelso.id.au']
  spec.summary       = %q{Guard / Listen TCP server to publich filesystem events to guests.}
  spec.homepage      = 'https://github.com/zaius/vagrant-listen-server'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
