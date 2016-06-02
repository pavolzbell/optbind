require 'spec_helper'

require 'date'
require 'optparse'
require 'shellwords'
require 'time'
require 'uri'

include OptParse::Acceptables

describe OptBind::Switch do
  before(:each) { require 'optbind/type' }

  shared_examples_for 'resolve_type' do |name|
    it "resolves #{name}" do
      type = OptBind.const_get name.to_s.gsub(/(?:\A|[-_]+)\w/) { |p| p[-1].upcase }
      expect(subject.parser_opts_from_string "<value:#{name}>").to contain_exactly [:REQUIRED, type, '=<value>'], nil
    end
  end

  describe '.parser_opts_from_string' do
    context 'with argument' do
      context 'with name and type' do
        include_examples 'resolve_type', :Object
        include_examples 'resolve_type', :String
        include_examples 'resolve_type', :Symbol
        include_examples 'resolve_type', :Regexp
        include_examples 'resolve_type', :Array

        include_examples 'resolve_type', :NilClass
        include_examples 'resolve_type', :TrueClass
        include_examples 'resolve_type', :FalseClass

        include_examples 'resolve_type', :Integer
        include_examples 'resolve_type', :BinaryInteger
        include_examples 'resolve_type', :DecimalInteger
        include_examples 'resolve_type', :OctalInteger
        include_examples 'resolve_type', :HexadecimalInteger

        include_examples 'resolve_type', :Float

        include_examples 'resolve_type', :Numeric
        include_examples 'resolve_type', :DecimalNumeric

        include_examples 'resolve_type', :Date
        include_examples 'resolve_type', :DateTime
        include_examples 'resolve_type', :Time

        include_examples 'resolve_type', :Shellwords
        include_examples 'resolve_type', :ShellWords

        include_examples 'resolve_type', :URI

        context 'with alternative syntax' do
          include_examples 'resolve_type', :array
          include_examples 'resolve_type', :true_class
          include_examples 'resolve_type', :decimal_numeric
          include_examples 'resolve_type', :shell_words
        end
      end
    end
  end
end

describe OptBind do
  before(:each) do
    require 'optbind/type'
  end

  shared_examples_for 'parse_blank' do
    include_examples 'parse_value', nil => nil, description: 'parses missing argument as nil'
    include_examples 'raise_value', '', description: 'raises an empty string as failure'
  end

  shared_examples_for 'parse_value' do |value, options = {}|
    options = value if options.empty?
    description = options.delete :description
    value, object = *(options.to_a[0])

    it description || "parses #{value} as #{object.to_s}" do
      options = OptBind.new(target: {}) { |o| o.opt "o --option[=<value:#{type}>]" }
      options.parse value ? "--option=#{value}" : '--option'
      expect(options.target).to eq o: object
    end
  end

  shared_examples_for 'raise_value' do |value, options = {}|
    description = options[:description]
    error = options[:error] || OptionParser::InvalidArgument
    message = options[:message] || "invalid argument: --option=#{value}"

    it description || "raises #{value} as invalid" do
      options = OptBind.new(target: {}) { |o| o.opt "o --option[=<value:#{type}>]" }
      expect { options.parse value ? "--option=#{value}" : '--option' }.to raise_error error, message
    end
  end

  describe 'parsing an optional option' do
    context 'with Object' do
      let(:type) { :Object }

      include_examples 'parse_value', nil => true, description: 'parses missing argument as true'
      include_examples 'parse_value', '' => '', description: 'parses an empty string as empty string'
      include_examples 'parse_value', 'a string' => 'a string'
    end

    context 'with String' do
      let(:type) { :String }

      include_examples 'parse_blank'
      include_examples 'parse_value', 'a string' => 'a string'
    end

    context 'with Symbol' do
      let(:type) { :Symbol }

      include_examples 'parse_blank'
      include_examples 'parse_value', 'symbol' => :symbol, description: 'parses a string as a symbol'
    end

    context 'with Regexp' do
      let(:type) { :Regexp }

      include_examples 'parse_value', nil => nil, description: 'parses missing argument as nil'
      include_examples 'parse_value', '' => //, description: "parses an empty string as #{//}"
      include_examples 'parse_value', '\d+' => /\d+/
      include_examples 'parse_value', '/\d+/' => /\d+/
      include_examples 'parse_value', '/\d+/m' => /\d+/m
      include_examples 'parse_value', '/\d+/imx' => /\d+/imx
    end

    context 'with Array' do
      let(:type) { :Array }

      include_examples 'parse_value', nil => nil, description: 'parses missing argument as nil'
      include_examples 'parse_value', '' => [], description: 'parses an empty string as an empty array'
      include_examples 'parse_value', 'a,b' => %w(a b)
      include_examples 'parse_value', 'a, b' => ['a', ' b']
    end

    context 'with NilClass' do
      let(:type) { :NilClass }

      include_examples 'parse_value', nil => nil, description: 'parses missing argument as nil'
      include_examples 'parse_value', '' => '', description: 'parses an empty string as empty string'
      include_examples 'parse_value', 'a string' => 'a string'
    end

    context 'with TrueClass' do
      let(:type) { :TrueClass }

      include_examples 'parse_value', nil => true, description: 'parses missing argument as true'
      include_examples 'parse_value', 'nil' => false
      include_examples 'parse_value', 'true' => true
      include_examples 'parse_value', 'false' => false
      include_examples 'parse_value', 'yes' => true
      include_examples 'parse_value', 'no' => false
      include_examples 'parse_value', '+' => true
      include_examples 'parse_value', '-' => false
    end

    context 'with FalseClass' do
      let(:type) { :FalseClass }

      include_examples 'parse_value', nil => false, description: 'parses missing argument as false'
      include_examples 'parse_value', 'nil' => false
      include_examples 'parse_value', 'true' => true
      include_examples 'parse_value', 'false' => false
      include_examples 'parse_value', 'yes' => true
      include_examples 'parse_value', 'no' => false
      include_examples 'parse_value', '+' => true
      include_examples 'parse_value', '-' => false
    end

    context 'with Integer' do
      let(:type) { :Integer }

      include_examples 'parse_blank'
      include_examples 'parse_value', '0b1011011' => 0b1011011
      include_examples 'parse_value', '01011011' => 0o1011011
      include_examples 'parse_value', '1011011' => 1011011
      include_examples 'parse_value', '0o133' => 0o133
      include_examples 'parse_value', '0133' => 0o133
      include_examples 'parse_value', '133' => 133
      include_examples 'parse_value', '91' => 91
      include_examples 'parse_value', '0x5b' => 0x5b
      include_examples 'raise_value', '05b'
      include_examples 'raise_value', '5b'
    end

    context 'with BinaryInteger' do
      let(:type) { :BinaryInteger }

      include_examples 'parse_blank'
      include_examples 'parse_value', '0b1011011' => 0b1011011
      include_examples 'parse_value', '01011011' => 0b1011011
      include_examples 'parse_value', '1011011' => 0b1011011
      include_examples 'raise_value', '0o133'
      include_examples 'raise_value', '0133'
      include_examples 'raise_value', '133'
      include_examples 'raise_value', '91'
      include_examples 'raise_value', '0x5b'
      include_examples 'raise_value', '05b'
      include_examples 'raise_value', '5b'
    end

    context 'with OctalInteger' do
      let(:type) { :OctalInteger }

      include_examples 'parse_blank'
      include_examples 'raise_value', '0b1011011'
      include_examples 'parse_value', '01011011' => 0o1011011
      include_examples 'parse_value', '1011011' => 0o1011011
      include_examples 'parse_value', '0o133' => 0o133
      include_examples 'parse_value', '0133' => 0o133
      include_examples 'parse_value', '133' => 0o133
      include_examples 'raise_value', '91'
      include_examples 'raise_value', '0x5b'
      include_examples 'raise_value', '05b'
      include_examples 'raise_value', '5b'
    end

    context 'with DecimalInteger' do
      let(:type) { :DecimalInteger }

      include_examples 'parse_blank'
      include_examples 'raise_value', '0b1011011'
      include_examples 'parse_value', '01011011' => 1011011
      include_examples 'parse_value', '1011011' => 1011011
      include_examples 'raise_value', '0o133'
      include_examples 'parse_value', '0133' => 133
      include_examples 'parse_value', '133' => 133
      include_examples 'parse_value', '91' => 91
      include_examples 'raise_value', '0x5b'
      include_examples 'raise_value', '05b'
      include_examples 'raise_value', '5b'
    end

    context 'with HexadecimalInteger' do
      let(:type) { :HexadecimalInteger }

      include_examples 'parse_blank'
      include_examples 'parse_value', '0b1011011' => 0xb1011011
      include_examples 'parse_value', '01011011' => 0x1011011
      include_examples 'parse_value', '1011011' => 0x1011011
      include_examples 'raise_value', '0o133'
      include_examples 'parse_value', '0133' => 0x133
      include_examples 'parse_value', '133' => 0x133
      include_examples 'parse_value', '91' => 0x91
      include_examples 'parse_value', '0x5b' => 0x5b
      include_examples 'parse_value', '05b' => 0x5b
      include_examples 'parse_value', '5b' => 0x5b
    end

    context 'with Float' do
      let(:type) { :Float }

      include_examples 'parse_blank'

      # TODO add more examples
    end

    context 'with Numeric' do
      let(:type) { :Numeric }

      include_examples 'parse_blank'

      # TODO add more examples
    end

    context 'with DecimalNumeric' do
      let(:type) { :DecimalNumeric }

      include_examples 'parse_blank'

      # TODO add more examples
    end

    context 'with Date' do
      let(:type) { :Date }

      include_examples 'parse_blank'

      # TODO add more examples
    end

    context 'with DateTime' do
      let(:type) { :DateTime }

      include_examples 'parse_blank'

      # TODO add more examples
    end

    context 'with Time' do
      let(:type) { :Time }

      include_examples 'parse_blank'

      # TODO add more examples
    end

    context 'with ShellWords' do
      let(:type) { :ShellWords }

      include_examples 'parse_value', nil => nil, description: 'parses missing argument as nil'
      include_examples 'parse_value', '' => [], description: 'parses an empty string as an empty array'

      # TODO add more examples
    end

    context 'with URI' do
      let(:type) { :URI }

      include_examples 'parse_blank'

      # TODO add more examples
    end
  end
end
