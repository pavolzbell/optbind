# frozen_string_literal: true

require 'forwardable'
require 'optparse'

class OptionBinder
  attr_reader :parser, :target

  def initialize(parser: nil, target: nil, bind: nil)
    target, bind = TOPLEVEL_BINDING, :to_local_variables if target == nil && bind == nil
    @parser = resolve_parser(parser)
    @target, @reader, @writer = target, *resolve_binding(target, bind)
    yield self if block_given?
  end

  def resolve_binding(target, bind)
    case bind
    when :to_local_variables
      raise ArgumentError unless target.is_a? Binding
      return -> (v) { target.local_variable_get v }, -> (v, x) { target.local_variable_set v, x }
    when :to_instance_variables
      return -> (v) { target.instance_variable_get "@#{v}" }, -> (v, x) { target.instance_variable_set "@#{v}", x }
    else
      return -> (v) { target[v] }, -> (v, x) { target[v] = x } if target.respond_to? :[]
      return -> (v) { target.public_send v }, -> (v, x) { target.public_send "#{v}=", x }
    end
  end

  def resolve_parser(parser = nil)
    parser ||= OptionParser.new do |p|
      p.define_singleton_method(:banner) { (b = super()) !~ /\AU/ ? b : "usage: #{program_name} [<options>]\n\n" }
      p.define_singleton_method(:help) { super().gsub(/(-\S+)=\[/, '\1[=') << "    -h, --help\n        --version\n\n" }
    end
    parser.tap do |p|
      p.program_name = ::PROGRAM if defined? ::PROGRAM
      p.version = ::VERSION if defined? ::VERSION
    end
  end

  private :resolve_binding, :resolve_parser

  extend Forwardable

  def_delegators :@parser, :accept, :reject
  def_delegators :@parser, :abort, :warn
  def_delegators :@parser, :load

  { order: '*argv, &blk', order!: 'argv', permute: '*argv', permute!: 'argv', parse: '*argv', parse!: 'argv' }.each do |m, a|
    class_eval "def #{m} #{a}; @parser.#{m} #{a}; parse_args#{'!' if m =~ /!\z/} argv; rescue OptionParser::ParseError; @parser.abort; end", __FILE__, __LINE__
  end

  def_delegators :@parser, :to_a, :to_s

  def_delegator :@parser, :program_name, :program
  def_delegator :@parser, :version
  def_delegator :@parser, :help

  def usage(*args)
    line = (args * ' ') << "\n"

    if @parser.banner =~ /\Ausage:.+\n\n/i
      @parser.banner = "usage: #{program} #{line}"
      @parser.separator "\n"
    else
      @parser.banner += "   or: #{program} #{line}"
    end

    self
  end

  alias_method :use, :usage

  def option(*opts, &handler)
    opts, handler, bound, variable, default = *several_variants(*opts, &handler)

    @parser.on(*opts) do |r|
      if opts.include? :REQUIRED
        a = opts.select { |o| o =~ /\A-/ }.sort_by { |o| o.length }[-1]
        @parser.abort "missing argument: #{a}=" if !r || (r.respond_to?(:empty?) && r.empty?)
      end

      handle! handler, r, bound, variable, default
    end

    (@bound_variables_with_defaults ||= {})[variable] = default if bound
    self
  end

  alias_method :opt, :option

  def argument(*opts, &handler)
    opts, handler, bound, variable, default = *several_variants(*opts, &handler)

    opts.each do |opt|
      (opts << :MULTIPLE) and break if opt.to_s =~ /<\S+>\.{3}/
    end

    (@argument_definitions ||= []) << { opts: opts, handler: handler, bound: bound, variable: variable }
    (@bound_variables_with_defaults ||= {})[variable] = default if bound
    self
  end

  alias_method :arg, :argument

  def bound_defaults
    @bound_variables_with_defaults ? @bound_variables_with_defaults.dup : {}
  end

  def bound_variables
    return {} unless @bound_variables_with_defaults
    Hash[@bound_variables_with_defaults.keys.map { |v| [v, @reader.call(v)] }]
  end

  def assigned_variables
    return {} unless @assigned_variables_with_values
    @assigned_variables_with_values.dup
  end

  def default?(v)
    v = v.to_sym
    return nil unless bound? v
    (@bound_variables_with_defaults[v] || {}) == @reader.call(v)
  end

  def bound?(v)
    (@bound_variables_with_defaults || {}).has_key? v.to_sym
  end

  def assigned?(v)
    return nil unless bound? v
    (@assigned_variables_with_values || {}).has_key? v.to_sym
  end

  module Switch
    def self.parser_opts_from_hash(hash = {}, &handler)
      style = case (hash[:style] || hash[:mode]).to_s.downcase
      when 'required' then :REQUIRED
      when 'optional' then :OPTIONAL
      end

      pattern = hash[:pattern] || hash[:type]
      values = hash[:values]
      names = [hash[:long], hash[:longs]].flatten.map { |n| n.to_s.sub(/\A-{,2}/, '--') if n }
      names += [hash[:short], hash[:shorts]].flatten.map { |n| n.to_s.sub(/\A-{,2}/, '-') if n }
      names += [hash[:name], hash[:names]].flatten.map do |n|
        next unless n
        n = n.to_s
        next n if n[0] == '-'
        n[2] ? "--#{n}" : "-#{n}"
      end

      argument = (hash[:argument].to_s.sub(/\A(\[)?=?/, '=\1') if hash[:argument])
      description = ([hash[:description]].flatten * ' ' if hash[:description])
      handler ||= hash[:handler]
      return ([style, pattern, values] + names + [argument, description]).compact, handler
    end

    def self.parser_opts_from_string(string = '', &handler)
      string, shorts, longs = string.dup, [], []

      while string.sub!(/\A(?:(?<short>-\w)\s+)/, '')
        shorts << $~[:short]
      end

      style, pattern, values, argument = nil

      while string.sub!(/\A(?:(?<long>--[\[\]\-\w]+[\]\w]+)?(?:(?<argument>(?:\[?=?|=\[)[<(]\S+[)>]\.{,3}\]?)|\s+))/, '')
        longs << $~[:long] if $~[:long]
        next unless $~[:argument]
        argument = $~[:argument]
        style = argument =~ /\A=?[<(]/ ? :REQUIRED : :OPTIONAL
        values = $~[:values].split('|') if argument =~ /(?:\[?=?|=\[)\((?<values>\S*)\)\]?/

        if values.nil? && argument =~ /(?:\[?=?|=\[)<(?<name>\S+):(?<pattern>\S+)>\]?/
          pattern = Module.const_get($~[:pattern]) rescue Regexp.new($~[:pattern])
          argument = "=<#{$~[:name]}>"
          argument = "=[#{argument[1..-1]}]" if style == :OPTIONAL
        else
          argument.sub!(/\A(?:=\[|\[?=?)/, style == :OPTIONAL ? '=[' : '=')
        end
      end

      description = !string.empty? ? string.strip : nil
      return ([style, pattern, values] + shorts + longs + [argument, description]).compact, handler
    end
  end

  def several_variants(*opts, &handler)
    bound, variable, default = false, nil, nil

    if opts.size == 1
      case opts[0]
      when Hash
        hash, variable = opts[0], [hash.delete(:variable), hash.delete(:bind)].compact[0]
        bound = !(opts[:bound] === false) && !!variable
        default = hash.delete(:default) || (@reader.call(variable.to_sym) if variable)
        opts, handler = Switch.parser_opts_from_hash hash, &handler
      when String
        string, variable = *(opts[0] !~ /\A\s*-/ ? opts[0].split(/\s+/, 2).reverse : [opts[0], nil])
        bound, default = !!variable, (@reader.call(variable.to_sym) if variable)
        opts, handler = Switch.parser_opts_from_string string, &handler
      end
    end

    variable = variable.to_sym if variable
    return opts, handler, bound, variable, default
  end

  private :several_variants

  def parse_args(argv)
    parse_args! argv.dup
  end

  def parse_args!(argv)
    return argv unless @argument_definitions
    @argument_definitions.each do |a|
      default = (@bound_variables_with_defaults ||= {})[a[:variable]]
      r = argv[0] ? argv.shift : default
      r = ([r].flatten + argv.shift(argv.size)).compact if a[:opts].include? :MULTIPLE
      @parser.abort 'missing arguments' if (r.nil? || (r.is_a?(Array) && r.empty?)) && a[:opts].include?(:REQUIRED)
      handle! a[:handler], r, a[:bound], a[:variable], default
      return argv if a[:opts].include? :MULTIPLE
    end
    @parser.abort 'too many arguments' if argv[0]
    argv
  end

  private :parse_args, :parse_args!

  def handle!(handler, raw, bound, variable, default)
    (handler || -> (r) { r }).call(raw == nil ? default : raw).tap do |x|
      return x unless bound
      @writer.call variable, x
      (@assigned_variables_with_values ||= {})[variable] = x
    end
  end

  private :handle!

  module Arguable
    def binder=(bind)
      unless @optbind = bind
        class << self
          undef_method(:binder)
          undef_method(:binder=)
        end
      end
    end

    def binder(opts = {}, &blk)
      unless @optbind
        if opts[:to] == :locals
          target, bind = TOPLEVEL_BINDING, :to_local_variables
        else
          target = opts[:target] || opts[:to]
          bind = (:to_local_variables if opts[:locals]) || opts[:bind] || ("to_#{opts[:via]}".to_sym if opts[:via])
        end

        @optbind = OptionBinder.new parser: opts[:parser], target: target, bind: bind
      end

      @optbind.instance_eval &blk if blk
      self.options = @optbind.parser
      @optbind
    end

    alias_method :define, :binder
    alias_method :define_and_bind, :binder
    alias_method :bind, :binder

    def define_and_parse!(opts = {}, &blk)
      define opts, &blk
      parse!
    end

    alias_method :bind_and_parse!, :define_and_parse!

    def parser
      self.options
    end

    def order!(&blk)
      binder.order! self, &blk
    end

    def permute!
      binder.permute! self
    end

    def parse!
      binder.parse! self
    end
  end
end

ARGV.extend(OptionBinder::Arguable)

OptBind = OptionBinder
