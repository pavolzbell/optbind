require_relative 'lib/optbind/version'

Gem::Specification.new do |s|
  s.name          = 'optbind'
  s.version       = OptBind::VERSION
  s.authors       = ['Pavol Zbell']
  s.email         = ['pavol.zbell@gmail.com']

  s.summary       = 'TODO'
  s.description   = 'TODO'
  s.homepage      = 'https://github.com/pavolzbell/optbind'
  s.license       = 'MIT'

  s.files         =
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '~> 1.10'
  s.add_development_dependency 'rake',    '~> 10.0'
  s.add_development_dependency 'rspec',   '~> 3.3.0'

  s.add_development_dependency 'pry'
end
