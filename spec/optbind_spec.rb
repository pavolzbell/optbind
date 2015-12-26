require 'spec_helper'

describe OptBind do
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
          { o: STDOUT }
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

          Target.new.tap { |t| t.o = STDOUT }
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
              @o = STDOUT
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
        o = STDOUT

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
        expect(options.bound_defaults).to eq(o: STDOUT)
        expect(options.bound_variables).to eq(o: STDOUT)
        writer.call(:o, STDERR)
        expect(options.bound_defaults).to eq(o: STDOUT)
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
          { o: STDOUT }
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

          Target.new.tap { |t| t.o = STDOUT }
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
              @o = STDOUT
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
          o = STDOUT
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
        expect(options.bound_defaults).to eq(o: STDOUT)
        expect(options.bound_variables).to eq(o: STDOUT)
        expect(options.parse('--output=file.out')).to contain_exactly('--output=file.out')
        expect(options.bound_defaults).to eq(o: STDOUT)
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
          { o: STDOUT }
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

          Target.new.tap { |t| t.o = STDOUT }
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
              @o = STDOUT
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
          o = STDOUT
          target = self.instance_eval { binding }
        end

        let(:bind) do
          :to_local_variables
        end
      end
    end
  end
end
