# OptBind

[![Build Status](https://img.shields.io/travis/pavolzbell/optbind.svg)](https://travis-ci.org/pavolzbell/optbind)
[![Gem Version](https://img.shields.io/gem/v/optbind.svg)](https://rubygems.org/gems/optbind)

Binds command-line options to objects or variables.

Extends command-line option analysis by wrapping an instance of standard [`OptionParser`](http://ruby-doc.org/stdlib-2.3.1/libdoc/optparse/rdoc/OptionParser.html).
Enables binding of options and arguments to `Hash` entries, public accessors, local, instance, or class variables. Provides `Hash` and `String` only interfaces
to define command-line options, unlike a mixed interface by standard library. Supports access to default values and argument analysis. Builds Git-like options
and help by default. 

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

### Definitions

Option and argument definitions include:

#### Hash options

```ruby
e, t, v, b, m = false, 80, true, 'master', [STDIN]

OptionBinder.new do |b|
  b.usage %w([<options>] <branch> [<path>...])
  b.usage %w([<options>] -e <branch> [<command>...])
  b.option variable: :e, names: %w(e eval)
  b.option variable: :t, mode: :OPTIONAL, short: 't', long: 'trim', argument: '[=<length>]', type: Integer
  b.option variable: :v, names: %w(-v --[no]-verbose), description: 'Be more verbose.'
  b.argument variable: :b, mode: :REQUIRED, argument: '<branch>'
  b.argument variable: :a, mode: :OPTIONAL, multiple: true, argument: '[<mix>...]'
end
```

#### Plain strings

```ruby
e, t, v, b, m = false, 80, true, 'master', [STDIN]

OptionBinder.new do |b|
  b.usage '[<options>] <branch> [<path>...]'
  b.usage '[<options>] -e <branch> [<command>...]'
  b.option 'e -e --eval'
  b.option 't -t --trim[=<length:integer>]'
  b.option 'v -v --[no-]verbose Be more verbose.'
  b.argument 'b <branch>'
  b.argument 'm [<mix>...]'
end
```

### Bindings

Various binding possibilities include:   

#### Bind to `Hash` entries

Create target:

```ruby
options = { input: STDIN, output: STDOUT }
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: options) do |b|
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
OptionBinder.new(target: options) do |b|
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

Create target:

```ruby
class Options
  @@input, @@output = STDIN, STDOUT
end

options = Options.new
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: options, bind: :to_class_variables) do |b|
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

Create target:

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
OptionBinder.new(target: options, bind: :to_instance_variables) do |b|
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

Create target:

```ruby
input, output = STDIN, STDOUT
```

Use `OptionBinder` directly:

```ruby
OptionBinder.new(target: TOPLEVEL_BINDING, bind: :to_local_variables) do |b|
  # ...
end
```

Use `OptionBinder` directly with top level binding object as target by default:

```ruby
OptionBinder.new do |b|
  # ...
end
```

Use `ARGV` shortcut:

```ruby
ARGV.define_and_bind(to: TOPLEVEL_BINDING, via: :local_variables) do
  # ... 
end  
```

Use `ARGV` shortcut with top level binding object as target by default:

```ruby
ARGV.define_and_bind(to: :locals) do
  # ... 
end  
```

### Extensions

Use `optbind/ext` shortcut to load option binder with all available extensions at once:

```ruby
require 'optbind/ext'
```

Several available extensions include: 

#### Default

Adds default values to option descriptions.

```ruby
require 'optbind/default'

# ...

print binder.help
```

#### Mode

Adds `order` and `permute` methods.

```ruby
require 'optbind/mode'

# ...

binder.order ARGV
```

Note that `order!` and `permute!` methods in `ARGV` from `OptionParser` are redefined to raise an unsupported error without this extension.

#### Type

Adds various common types to accept in definitions.

```ruby
require 'optbind/type'

# ...

binder.option 'm --matcher=<pattern:Regexp>'
binder.option 'r --repository=<uri:URI>'
```

#### Handler

Adds various common handlers to accept in definitions.

```ruby
require 'optbind/handler'

# ... 

binder.option 's --storage=<name>', &included_in(%w(file memory))
binder.option 'a --attachments=<ids>', &listed_as(Integer)
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
