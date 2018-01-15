
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'environmate/version'

Gem::Specification.new do |spec|
  spec.name          = 'environmate'
  spec.version       = Environmate::VERSION
  spec.authors       = ['Andreas Zuber']
  spec.email         = ['zuber@puzzle.ch']

  spec.summary       = 'Manage Puppet environments with a GIT workflow'
  spec.description   = 'Environmate is a Webhook receiver for various GIT '\
                       'web frontends for deloying Puppet environments to'\
                       'the master/server'
  spec.homepage      = 'https://github.com/puzzle/environmate'
  spec.license       = 'GPL-3.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sinatra', '~> 2'
  spec.add_dependency 'lockfile', '~> 2'

  # TODO: make this dependencies optional
  spec.add_dependency 'xmpp4r', '~> 0'
  spec.add_dependency 'librarian-puppet', '~> 3'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rack-test', '~> 0.8'
  spec.add_development_dependency 'simplecov', '~> 0.15'
  spec.add_development_dependency 'rubocop', '~> 0.51'
end
