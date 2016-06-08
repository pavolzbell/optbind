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
    when :to_class_variables
      return -> (v) { target.class_variable_get "@@#{v}" }, -> (v, x) { target.class_variable_set "@@#{v}", x }
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
  def_delegators :@parser, :environment, :load
  def_delegators :@parser, :to_a, :to_s

  def parse(*argv)
    parse! argv.dup.flatten
  end

  def parse!(argv = parser.default_argv)
    parse_args! @parser.parse! argv
  end

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
    o, h = *loot!(opts, &handler)

    @parser.on(*o) do |r|
      raise OptionParser::InvalidArgument if opts.include?(:REQUIRED) && (r.nil? || r.respond_to?(:empty?) && r.empty?)
      handle! h, r, bound, variable, default
    end

    (@option_definitions ||= []) << { opts: opts, handler: handler, bound: bound, variable: variable }
    (@bound_variables_with_defaults ||= {})[variable] = default if bound
    self
  end

  alias_method :opt, :option

  def argument(*opts, &handler)
    opts, handler, bound, variable, default = *several_variants(*opts, &handler)
    o, h = *loot!(opts, &handler)

    (@argument_parser ||= OptionParser.new).on(*(o + ["--#{(@argument_definitions || []).size}"])) do |r|
      raise OptionParser::InvalidArgument if opts.include?(:REQUIRED) && (r.nil? || r.respond_to?(:empty?) && r.empty?)
      handle! h, r, bound, variable, default
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
    (@bound_variables_with_defaults || {}).key? v.to_sym
  end

  def assigned?(v)
    return nil unless bound? v
    (@assigned_variables_with_values || {}).key? v.to_sym
  end

  module Switch
    def self.parser_opts_from_hash(hash = {}, &handler)
      p = (hash[:style] || hash[:mode]).to_s.upcase
      style = [(p.to_sym if %w(REQUIRED OPTIONAL).include? p), (:MULTIPLE if hash[:multiple])]
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
      description = ([hash[:description]] * ' ' if hash[:description])
      handler ||= hash[:handler]
      return (style + [pattern, values] + names + [argument, description]).compact, handler
    end

    def self.parser_opts_from_string(string = '', &handler)
      string, shorts, longs = string.dup, [], []

      while string.sub!(/\A(?:(?<short>-\w)\s+)/, '') do
        shorts << $~[:short]
      end

      style, pattern, values, argument = [], nil

      while string.sub!(/\A(?:(?<long>--[\[\]\-\w]+[\]\w]+)?(?:(?<argument>(?:\[?=?|=\[)[<(]\S+[)>]\.{,3}\]?)|\s+))/, '')
        longs << $~[:long] if $~[:long]
        next unless $~[:argument]
        argument = $~[:argument]
        style = [argument =~ /\A=?[<(]/ ? :REQUIRED : :OPTIONAL, argument =~ /\.{3}\]?\z/ ? :MULTIPLE : nil]
        values = $~[:values].split('|') if argument =~ /(?:\[?=?|=\[)\((?<values>\S*)\)\]?/

        if values.nil? && argument =~ /(?:\[?=?|=\[)<(?<name>\S+):(?<pattern>\S+)>\]?/
          argument, pattern = "=<#{$~[:name]}>#{'...' if style.include? :MULTIPLE}", $~[:pattern]
          argument = "=[#{argument[1..-1]}]" if style.include? :OPTIONAL
          pattern = pattern.gsub(/\//, '::').gsub(/(?:\A|[-_]+)\w/) { |p| p[-1].upcase } if pattern =~ /\A[-_a-z]/
          pattern = OptionBinder.const_get(pattern) rescue Regexp.new(pattern)
        else
          argument.sub!(/\A(?:=\[|\[?=?)/, style.include?(:OPTIONAL) ? '=[' : '=')
        end
      end

      description = !string.empty? ? string.strip : nil
      return (style + [pattern, values] + shorts + longs + [argument, description]).compact, handler
    end
  end

  def several_variants(*opts, &handler)
    bound, variable, default = false, nil, nil

    if opts.size == 1
      case opts[0]
      when Hash
        hash = opts[0].dup
        variable = hash.delete(:variable) || hash.delete(:bind)
        bound = !(opts.delete(:bound) === false) && !!variable
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

  class MissingArguments < OptionParser::ParseError
    const_set :Reason, 'missing arguments'
    alias_method :message, :reason
    alias_method :to_s, :reason
  end

  class TooManyArguments < OptionParser::ParseError
    const_set :Reason, 'too many arguments'
    alias_method :message, :reason
    alias_method :to_s, :reason
  end

  def parse_args!(argv)
    return argv unless @argument_parser
    k = @argument_definitions.find_index { |a| a[:opts].include? :MULTIPLE }
    p = k ? argv[0...k].map { |r| [r] } << argv[k..-1] : argv.map { |r| [r] }
    p = (p.empty? ? p << [] : p).each_with_index.map do |r, i|
      a = @argument_definitions[i]
      raise TooManyArguments unless a
      raise MissingArguments if a[:opts].include?(:REQUIRED) && r.empty?
      "--#{i}=#{r * ','}" if a[:opts].include?(:REQUIRED) || !(r.empty? || r.find(&:empty?))
    end
    @argument_parser.order! p
    argv.shift argv.size - p.size
    argv
  rescue OptionParser::InvalidArgument
    raise $!.tap { |e| e.args[0] = e.args[0].sub(/\A--\d+=/, '') }
  end

  private :parse_args!

  def loot!(opts, &handler)
    return opts, handler unless opts.include? :MULTIPLE
    o = opts.dup
    t = o.delete o.find { |a| a != Array && a.is_a?(Module) }
    o << Array unless o.include? Array
    return o, handler if t == nil || t == String
    require 'optbind/handler'
    return o, -> (a) { (handler || -> (r) { r }).call listed_as(t).call a }
  end

  def handle!(handler, raw, bound, variable, default)
    (handler || -> (r) { r }).call(raw == nil ? default : raw).tap do |x|
      return x unless bound
      @writer.call variable, x
      (@assigned_variables_with_values ||= {})[variable] = x
    end
  end

  private :loot!, :handle!

  module Arguable
    def self.extend_object(o)
      super and return unless o.singleton_class.included_modules.include? OptionParser::Arguable
      %i(order! permute!).each { |m| o.define_singleton_method(m) { raise 'unsupported' }}
    end

    def binder=(bind)
      @optbind = bind
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

      @optbind.parser.default_argv = self
      @optbind.instance_eval &blk if blk
      self.options = @optbind.parser if respond_to? :options=
      @optbind
    end

    extend Forwardable

    def_delegators :binder, :parser, :target

    alias_method :define, :binder
    alias_method :define_and_bind, :binder
    alias_method :bind, :binder

    def define_and_parse(opts = {}, &blk)
      define(opts, &blk) and parse
    end

    alias_method :bind_and_parse, :define_and_parse

    def define_and_parse!(opts = {}, &blk)
      define(opts, &blk) and parse!
    end

    alias_method :bind_and_parse!, :define_and_parse!

    def parse
      binder.parse self
    end

    def parse!
      binder.parse! self
    end
  end
end

ARGV.extend(OptionBinder::Arguable)

OptBind = OptionBinder

require 'optbind/version'
