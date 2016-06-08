require 'forwardable'
require 'optbind'

require 'optparse/date'
require 'optparse/shellwords'
require 'optparse/time'
require 'optparse/uri'

class OptionBinder
  class << self
    extend Forwardable

    def_delegators OptionParser, :accept, :reject
  end

  accept(Symbol, /.+/m) { |s, _| s.to_sym if s }

  # NOTE: Regexp defined in OptionParser does not handle missing argument,
  # therefore it is redefined to work properly on switches with optional argument

  accept Regexp, %r"\A/((?:\\.|[^\\])*)/([[:alpha:]]+)?\z|.*" do |s, p, o|
    f, k = 0, nil
    if o
      f |= Regexp::IGNORECASE if /i/ =~ o
      f |= Regexp::MULTILINE if /m/ =~ o
      f |= Regexp::EXTENDED if /x/ =~ o
      k = o.delete 'imx'
      k = nil if k.empty?
    end
    Regexp.new p || s, f, k if p || s
  end

  include OptionParser::Acceptables

  # NOTE: OctalInteger defined in OptionParser does not handle 0o prefix, therefore
  # it is redefined along with Integer and Numeric patterns which use it internally

  # NOTE: OctalInteger defined in OptionParser for some reason accepts binary and hexadecimal values too,
  # whereas DecimalInteger only accepts decimal values, therefore the OctalInteger is redefined to accept
  # octal values only to unify its behavior with binary, decimal, and hexadecimal integer patterns

  binary = '(?:0b)?[01]+(?:_[01]+)*'
  octal = '(?:0o?)?[0-7]+(?:_[0-7]+)*'
  decimal = '\d+(?:_\d+)*'
  hexadecimal = '(?:0x)?[\da-f]+(?:_[\da-f]+)*'

  BinaryInteger = /\A[-+]?#{binary}\z/io
  OctalInteger = /\A[-+]?#{octal}\z/io
  HexadecimalInteger = /\A[-+]?#{hexadecimal}\z/io

  accept Integer, /\A[-+]?(?:#{binary}|#{octal}|#{hexadecimal}|#{decimal})\z/io do |*a|
    s = a[0]
    begin
      Integer s
    rescue ArgumentError
      raise OptionParser::InvalidArgument, s
    end if s
  end

  with_base = -> (b) do
    -> (*a) do
      s = a[0]
      begin
        Integer s, b
      rescue ArgumentError
        raise OptionParser::InvalidArgument, s
      end if s
    end
  end

  accept BinaryInteger, BinaryInteger, &with_base.call(2)
  accept OctalInteger, OctalInteger, &with_base.call(8)
  accept DecimalInteger, DecimalInteger, &with_base.call(10)
  accept HexadecimalInteger, HexadecimalInteger, &with_base.call(16)

  float = "(?:#{decimal}(?:\\.(?:#{decimal})?)?|\\.#{decimal})(?:E[-+]?#{decimal})?"
  real = "[-+]?(?:#{binary}|#{octal}|#{hexadecimal}|#{float})"

  accept Numeric, /\A(#{real})(?:\/(#{real}))?\z/io do |s, d, n|
    if n
      Rational d, n
    elsif s
      eval s
    end
  end

  # NOTE: ShellWords defined in OptionParser does not handle missing argument,
  # therefore it is redefined to work properly on switches with optional argument

  ShellWords = Shellwords

  OptionParser.accept(Shellwords) { |s, *| Shellwords.shellsplit s if s }

  # NOTE: URI defined in OptionParser parses successfully on an empty argument,
  # therefore it is redefined to work similarly with other complex object types

  OptionParser.accept(URI) do |s, *|
    if s
      raise OptionParser::InvalidArgument, s if s.empty?
      URI.parse s
    end
  end
end
