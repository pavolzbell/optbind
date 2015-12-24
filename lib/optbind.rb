require 'forwardable'
require 'optparse'

class OptionBinder
  attr_reader :parser, :target

  def initialize(parser: nil, target: TOPLEVEL_BINDING, locals: false)
    @parser = resolve_parser(parser)
    @target, @reader, @writer = target, resolve_binding(target, locals)
  end

  def resolve_binding(target, locals = false)
    return -> (v) { target[v] }, -> (v, x) { target[v] = x } if target.respond_to? :[]
    return -> (v) { target.public_send v }, -> (v, x) { target.public_send v, x } unless target.is_a? Binding
    return -> (v) { target.local_variable_get v }, -> (v, x) { target.local_variable_set v, x } if locals
    return -> (v) { target.instance_variable_get v }, -> (v, x) { target.instance_variable_set v, x }
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
    super
    parse_args *argv
  end

  def parse!(*argv)
    super
    parse_args! *argv
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
        bound, default = !!variable, hash.delete(:default) || (@reader.call(bound) if bound)
        opts, handler = Switch.parser_opts_from_hash hash, &handler
      when String then
        string, variable = opts[0] =~ /\A-/ ? opts[0].split(/\s+/, 2).reverse : opts[0], nil
        bound, default = !!variable, (@reader.call(bound) if bound)
        opts, handler = Switch.parser_opts_from_string string, &handler
      end
    end

    (@bound_variables_with_defaults ||= {})[variable] = default if bound

    @parser.on(opts) do |r|
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

  #TODO
  module Arguable
    def define_and_bind(to: TOPLEVEL_BINDING, locals: false)
      @optbind = OptionBinder.new parser: nil, target: to, locals: locals
      self.options = @optbind.parser
      yield @optbind if block_given?
      @optbind
    end
  end
end

ARGV.extend(OptionBinder::Arguable)

OptBind = OptionBinder
