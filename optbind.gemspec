require_relative 'lib/optbind/version'

Gem::Specification.new do |s|
  s.name          = 'optbind'
  s.version       = OptBind::VERSION
  s.authors       = ['Pavol Zbell']
  s.email         = ['pavol.zbell@gmail.com']

  s.summary       = 'Binds command-line options to variables.'
  s.description   = 'Binds command-line options to variables. Supports binding of options and arguments, default values, and partial argument analysis.'
  s.homepage      = 'https://github.com/pavolzbell/optbind'
  s.license       = 'MIT'

  s.files         = Dir['*.md', 'lib/**/*']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.1.0'

  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'pry',   '>= 0.10.0'
end
