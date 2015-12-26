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
    parser || OptionParser.new do |p|
      p.on_tail '-h', '--help' #TODO { abort to_s }
      p.on_tail '--version'
    end
  end

  private :resolve_binding, :resolve_parser

  extend Forwardable

  def_delegators :@parser, :accept, :reject
  def_delegators :@parser, :abort, :warn
  def_delegators :@parser, :load

  def parse(*argv)
    @parser.parse *argv
    parse_args *argv
    argv
  end

  def parse!(*argv)
    @parser.parse! *argv
    parse_args! *argv
    argv
  end

  def_delegators :@parser, :to_a, :to_s

  def_delegator :@parser, :program_name, :program
  def_delegator :@parser, :version

  def usage(*args)
    line = (args * ' ') << "\n"

    if @parser.banner.nil?
      @parser.on_head "\n" and @parser.on_tail "\n"
      @parser.banner << "usage: #{program} " << line
    else
      @parser.banner << "   or: #{program} " << line
    end

    self
  end

  alias_method :use, :usage

  def option(*opts, &handler)
    bound = false

    if opts.size == 1
      case opts[0]
      when Hash then
        hash, variable = opts[0], [hash.delete(:variable), hash.delete(:bind)].compact[0]
        bound, default = !!variable, hash.delete(:default) || (@reader.call(variable.to_sym) if variable)
        opts, handler = Switch.parser_opts_from_hash hash, &handler
      when String then
        string, variable = *(opts[0] !~ /\A\s*-/ ? opts[0].split(/\s+/, 2).reverse : [opts[0], nil])
        bound, default = !!variable, (@reader.call(variable.to_sym) if variable)
        opts, handler = Switch.parser_opts_from_string string, &handler
      end
    end

    if bound
      variable = variable.to_sym
      (@bound_variables_with_defaults ||= {})[variable] = default
    end

    @parser.on(*opts) do |r|
      unless opts.include? :OPTIONAL
        a = opts.select { |o| o =~ /\A-/ }.sort_by { |o| o.length }[-1]
        @parser.abort "missing argument: #{a}=" if !r || (r.respond_to?(:empty?) && r.empty?)
      end

      (handler || -> (_) { r }).call(r == nil ? default : r).tap { |x| @writer.call variable, x if bound }
    end

    self
  end

  alias_method :opt, :option

  #TODO
  def argument(*args, &handler)

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

  def default?(v)
    v = v.to_sym
    return nil unless (@bound_variables_with_defaults || {}).has_key? v
    @bound_variables_with_defaults[v] == @reader.call(v)
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

      argument = (hash[:argument].to_s if hash[:argument])
      description = ([hash[:description]].flatten * ' ' if hash[:description])
      handler ||= hash[:handler]

      return ([style, pattern, values] + names + [argument, description]).compact, handler
    end

    def self.parser_opts_from_string(string = '', &handler)
      shorts, longs = [], []

      while string.sub!(/\A(?:(?<short>-\w)\s+)/, '')
        shorts << $~[:short]
      end

      style, pattern, values, argument = nil

      while string.sub!(/\A(?:(?<long>--[\[\]\-\w]+[\]\w]+)?(?:(?<argument>\[?=[<(]\S+[)>]\]?)|\s+))/, '')
        longs << $~[:long]
        argument = $~[:argument]

        next unless argument

        style = argument[0] == '=' ? :REQUIRED : :OPTIONAL
        values = $~[:values].split('|') if argument =~ /\[?=\((?<values>\S*)\)\]?/

        if values.nil? && argument =~ /\[?=<(?<name>\S+):(?<pattern>\S+)>\]?/
          pattern = Module.const_get($~[:pattern]) rescue Regexp.new($~[:pattern])
          argument = "=<#{$~[:name]}>"
          argument = "[#{argument}]" if style == :OPTIONAL
        end
      end

      description = !string.empty? ? string.strip : nil

      return ([style, pattern, values] + shorts + longs + [argument, description]).compact, handler
    end
  end

  #TODO
  def parse_args(*argv)

  end

  private :parse_args

  #TODO
  def parse_args!(*argv)

  end

  private :parse_args!

  module Arguable
    def define_and_bind(opts = {}, &block)
      if opts[:to] == :locals
        target, bind = TOPLEVEL_BINDING, :to_local_variables
      else
        target = opts[:target] || opts[:to]
        bind = (:to_local_variables if opts[:locals]) || opts[:bind] || ("to_#{opts[:via]}".to_sym if opts[:via])
      end

      @optbind = OptionBinder.new parser: opts[:parser], target: target, bind: bind, &block
      self.options = @optbind.parser
      @optbind
    end

    alias_method :define, :define_and_bind
    alias_method :bind, :define_and_bind

    def binder
      @optbind
    end

    def parser
      self.options
    end
  end
end

ARGV.extend(OptionBinder::Arguable)

OptBind = OptionBinder
