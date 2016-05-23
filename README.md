# OptBind

[![Build Status](https://img.shields.io/travis/pavolzbell/optbind.svg)](https://travis-ci.org/pavolzbell/optbind)
[![Gem Version](https://img.shields.io/gem/v/optbind.svg)](https://rubygems.org/gems/optbind)

Binds command-line options to variables.

Extends command-line option analysis by wrapping an instance of standard [`OptionParser`](http://ruby-doc.org/stdlib-2.3.1/libdoc/optparse/rdoc/OptionParser.html).
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

ARGV                                         #=> []

[i, o, v]                                    #=> ['file.in', 'file.out', false]
```

Use `bind` or one of its aliases on `ARGV` instead of `bind_and_parse!` to be able to `parse!` command line arguments later:

```ruby
ARGV.bind to: :locals do
  # ...
end

ARGV.parse!
```

Create an `OptionBinder` and use it directly:

```ruby
binder = OptionBinder.new do
  # ...
end

binder.parse! ARGV
```

Note that plain `OptionBinder.new` binds to local variables of top level binding object by default. 

See specs for more examples and details on usage.

### Bindings

Various binding options include:   

#### Bind to `Hash` object

Create target:

```ruby
options = { input: STDIN, output: STDOUT }
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: options) do
  # ...
end
```

Use `ARGV` shortcut:

```ruby
ARGV.define_and_bind(to: options) do
  # ... 
end  
```

#### Bind to public accessors

Create target:

```ruby
class Options
  attr_accessor :input, :output
  
  def initialize
    @input, @output = STDIN, STDOUT
  end
end
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: options) do
  # ...
end
```

Use `ARGV` shortcut:

```ruby
ARGV.define_and_bind(to: options) do
  # ... 
end  
```

#### Bind to class variables

```ruby
class Options
  @@input, @@output = STDIN, STDOUT
end

options = Options.new
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: options, bind: :to_class_variables) do
  # ...
end
```

Use `ARGV` shortcut:

```ruby
ARGV.define_and_bind(to: options, via: :class_variables) do
  # ... 
end  
```

#### Bind to instance variables

```ruby
class Options
  def initialize
    @input, @output = STDIN, STDOUT
  end
end

options = Options.new
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: options, bind: :to_instance_variables) do
  # ...
end
```

Use `ARGV` shortcut:

```ruby
ARGV.define_and_bind(to: options, via: :instance_variables) do
  # ... 
end  
```

#### Bind to local variables

```ruby
input, output = STDIN, STDOUT
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: TOPLEVEL_BINDING, bind: :to_local_variables) do
  # ...
end
```

Use `ARGV` shortcut:

```ruby
ARGV.define_and_bind(to: TOPLEVEL_BINDING, via: :local_variables) do
  # ... 
end  
```

or

```ruby
ARGV.define_and_bind(to: :locals) do
  # ... 
end  
```

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
