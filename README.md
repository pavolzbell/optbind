# OptBind

[![Build Status](https://img.shields.io/travis/pavolzbell/optbind.svg)](https://travis-ci.org/pavolzbell/optbind)
[![Gem Version](https://img.shields.io/gem/v/optbind.svg)](https://badge.fury.io/gh/pavolzbell/optbind)

Binds command-line options to variables.

Extends command-line option analysis by wrapping an instance of standard [`OptionParser`](http://ruby-doc.org/stdlib-2.2.3/libdoc/optparse/rdoc/OptionParser.html).
Enables binding of options and arguments to instance or local variables. Provides `Hash` and `String` only interfaces
to define command line options, unlike a mixed interface by standard library. Supports access to default values and
partial argument analysis. Builds Git-like options and help by default. 

## Installation

    bundle install optbind

## Usage

Bind local variables to `ARGV` and parse command line arguments: 

```ruby
require 'optbind'

ARGV                                         #=> ['--no-verbose', '-o', 'file.out', 'file.in'] 

i, o, v = STDIN, STDOUT, true

ARGV.bind_and_parse! to: :locals do
  use '[<options>] [<file>]'
  use '--help'
  opt 'o -o --output=<file>'
  opt 'v -v --[no-]verbose'
  arg 'i [<file>]'
end

[i, o, v]                                    #=> ['file.in', 'file.out', false]
```

See specs for more examples and details on usage.

## Testing

    bundle exec rspec

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin new-feature`)
5. Create new Pull Request

## License

This software is released under the [MIT License](LICENSE.md)
