require 'spec_helper'

describe OptBind do
  before(:each) do
    require 'optbind/handler'
    extend OptionBinder::Handler
  end

  shared_examples_for 'parse_value' do |value, options = {}|
    options = value if options.empty?
    description = options.delete :description
    value, object = *(options.to_a[0])

    it description || "parses #{value} as #{object.to_s}" do
      options = OptBind.new(target: {}) { |o| o.opt 'o --option[=<value>]', &handler }
      options.parse value ? "--option=#{value}" : '--option'
      expect(options.target).to eq o: object
    end
  end

  shared_examples_for 'raise_value' do |value, options = {}|
    description = options[:description]
    error = options[:error] || OptionParser::InvalidArgument
    message = options[:message] || "invalid argument: --option=#{value}"

    it description || "raises #{value} as invalid" do
      options = OptBind.new(target: {}) { |o| o.opt 'o --option[=<value>]', &handler }
      expect { options.parse value ? "--option=#{value}" : '--option' }.to raise_error error, message
    end
  end

  describe 'parsing an optional option' do
    context 'with #matched_by /\d*/' do
      let(:handler) { matched_by /\d*/ }

      include_examples 'parse_value', nil => true, description: 'parses missing argument as true'
      include_examples 'parse_value', '' => '', description: 'parses an empty string as empty string'
      include_examples 'parse_value', '0' => '0'

      # TODO add more examples
    end

    context 'with #included_in %w(left right)' do
      let(:handler) { included_in %w(left right) }

      include_examples 'raise_value', nil, description: 'raises missing argument as failure', message: 'invalid argument: --option true'
      include_examples 'raise_value', '', description: 'raises an empty string as failure'
      include_examples 'parse_value', 'left' => 'left'

      # TODO add more examples
    end

    context 'with #listed_as /\d*/' do
      let(:handler) { listed_as /\d*/ }

      include_examples 'raise_value', nil, description: 'raises missing argument as failure', message: 'invalid argument: --option true'
      include_examples 'parse_value', '' => [], description: 'parses an empty string as an empty array'
      include_examples 'parse_value', '0' => %w(0)
      include_examples 'parse_value', '0,1' => %w(0 1)

      # TODO add more examples
    end

    context 'with #listed_as Integer' do
      let(:handler) { listed_as Integer }

      include_examples 'raise_value', nil, description: 'raises missing argument as failure', message: 'invalid argument: --option true'
      include_examples 'parse_value', '' => [], description: 'parses an empty string as an empty array'
      include_examples 'parse_value', '0' => [0]
      include_examples 'parse_value', '0,1' => [0, 1]

      # TODO add more examples
    end
  end
end
