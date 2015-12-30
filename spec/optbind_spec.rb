require 'spec_helper'

describe OptBind do
  before(:each) { @script, $0 = $0, 'meow' }
  after(:each) { $0 = @script }

  describe '.new' do
    context 'with no arguments' do
      it 'creates an instance' do
        options = OptBind.new

        expect(options).to be_an_instance_of OptionBinder
        expect(options.parser).to be_an_instance_of OptionParser
        expect(options.target).to be_an_instance_of Binding
      end
    end

    context 'with custom parser and target' do
      let(:parser) { OptionParser.new }
      let(:target) { Object.new }

      it 'creates an instance' do
        options = OptBind.new parser: parser, target: target

        expect(options.parser).to equal parser
        expect(options.target).to equal target
      end
    end
  end

  describe '#program' do
    let(:options) { OptBind.new }

    it 'returns program name' do
      expect(options.program).to eq 'meow'
    end
  end

  describe '#version' do
    let(:options) { OptBind.new }

    context 'with VERSION' do
      it 'returns program version' do
        stub_const 'VERSION', '1.0.0'
        expect(options.version).to eq '1.0.0'
      end
    end

    context 'without VERSION' do
      it 'returns nothing' do
        expect(options.version).to be_nil
      end
    end
  end

  describe '#help' do
    let(:options) { OptBind.new }

    it 'returns help' do
      expect(options.help).to eq <<-HLP
usage: meow

    -h, --help
        --version

      HLP
    end

    context 'with usage' do
      it 'returns help' do
        options.use '<file>'

        expect(options.help).to eq <<-HLP
usage: meow <file>

    -h, --help
        --version

        HLP
      end
    end

    context 'with option' do
      it 'returns help' do
        options.opt '-o --output=<file>'

        expect(options.help).to eq <<-HLP
usage: meow

    -o, --output=<file>
    -h, --help
        --version

        HLP
      end
    end

    context 'with usages, options, and arguments' do
      it 'returns help' do
        options.use '[<options>] <file>'
        options.use '--help'
        options.use '--version'
        options.opt '-i --[no-]interactive'
        options.opt '-o --output=<file>'
        options.opt '-q --quiet'
        options.arg '<file>'

        expect(options.help).to eq <<-HLP
usage: meow [<options>] <file>
   or: meow --help
   or: meow --version

    -i, --[no-]interactive
    -o, --output=<file>
    -q, --quiet
    -h, --help
        --version

        HLP
      end
    end
  end

  describe 'creating a binder and binding an option' do
    shared_examples_for 'create_and_bind' do
      it 'creates and binds' do
        options = OptBind.new(target: target, bind: bind)
        expect(options.bound_defaults.key? :o).to be false
        expect(options.bound_variables.key? :o).to be false
        expect(options.opt 'o --output').to equal options
        expect(options.bound_defaults.key? :o).to be true
        expect(options.bound_variables.key? :o).to be true
      end
    end

    context 'bound via #[]' do
      include_examples 'create_and_bind' do
        let(:target) do
          { o: :STDOUT }
        end

        let(:bind) do
          nil
        end
      end
    end

    context 'bound via #public_send' do
      include_examples 'create_and_bind' do
        let(:target) do
          class Target
            attr_accessor :o
          end

          Target.new.tap { |t| t.o = :STDOUT }
        end

        let(:bind) do
          false
        end
      end
    end

    context 'bound via #instance_variables' do
      include_examples 'create_and_bind' do
        let(:target) do
          class Target
            def initialize
              @o = :STDOUT
            end
          end

          Target.new
        end

        let(:bind) do
          :to_instance_variables
        end
      end
    end

    context 'bound via #local_variables' do
      include_examples 'create_and_bind' do
        o = :STDOUT

        target = self.instance_eval { binding }

        let(:target) do
          target
        end

        let(:bind) do
          :to_local_variables
        end
      end
    end
  end

  describe 'accessing a bound option' do
    shared_examples_for 'read_and_write' do
      it 'reads and writes' do
        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: :STDOUT)
        writer.call(:o, STDERR)
        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: STDERR)
      end
    end

    let(:options) do
      OptBind.new(target: target, bind: bind) do |o|
        o.opt 'o --output'
      end
    end

    context 'bound via #[]' do
      include_examples 'read_and_write' do
        let(:target) do
          { o: :STDOUT }
        end

        let(:bind) do
          nil
        end

        let(:writer) do
          -> (v, x) { target[v] = x }
        end
      end
    end

    context 'bound via #public_send' do
      include_examples 'read_and_write' do
        let(:target) do
          class Target
            attr_accessor :o
          end

          Target.new.tap { |t| t.o = :STDOUT }
        end

        let(:bind) do
          false
        end

        let(:writer) do
          -> (v, x) { target.public_send "#{v}=", x }
        end
      end
    end

    context 'bound via #instance_variables' do
      include_examples 'read_and_write' do
        let(:target) do
          class Target
            def initialize
              @o = :STDOUT
            end
          end

          Target.new
        end

        let(:bind) do
          :to_instance_variables
        end

        let(:writer) do
          -> (v, x) { target.instance_variable_set "@#{v}", x }
        end
      end
    end

    context 'bound via #local_variables' do
      include_examples 'read_and_write' do
        let(:target) do
          o = :STDOUT
          target = self.instance_eval { binding }
        end

        let(:bind) do
          :to_local_variables
        end

        let(:writer) do
          -> (v, x) { target.local_variable_set v, x }
        end
      end
    end
  end

  describe 'parsing a bound option' do
    shared_examples_for 'parse' do
      it 'parses' do
        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: :STDOUT)
        expect(options.parse('--output=file.out')).to contain_exactly('--output=file.out')
        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: 'file.out')
      end
    end

    let(:options) do
      OptBind.new(target: target, bind: bind) do |o|
        o.opt 'o --output=<file>'
      end
    end

    context 'bound via #[]' do
      include_examples 'parse' do
        let(:target) do
          { o: :STDOUT }
        end

        let(:bind) do
          nil
        end
      end
    end

    context 'bound via #public_send' do
      include_examples 'parse' do
        let(:target) do
          class Target
            attr_accessor :o
          end

          Target.new.tap { |t| t.o = :STDOUT }
        end

        let(:bind) do
          false
        end
      end
    end

    context 'bound via #instance_variables' do
      include_examples 'parse' do
        let(:target) do
          class Target
            def initialize
              @o = :STDOUT
            end
          end

          Target.new
        end

        let(:bind) do
          :to_instance_variables
        end
      end
    end

    context 'bound via #local_variables' do
      include_examples 'parse' do
        let(:target) do
          o = :STDOUT
          target = self.instance_eval { binding }
        end

        let(:bind) do
          :to_local_variables
        end
      end
    end
  end
end
