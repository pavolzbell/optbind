require 'spec_helper'

describe OptBind::Arguable do
  let(:argv) do
    %w(--output=file.out file.in)
  end

  before(:each) do
    argv.extend OptParse::Arguable
    argv.extend OptBind::Arguable
  end

  it 'has binder' do
    expect(argv).to respond_to :binder
    expect(argv.binder).to be_an_instance_of OptionBinder
  end

  it 'has parser' do
    expect(argv).to respond_to :parser
    expect(argv.parser).to be_an_instance_of OptionParser
  end

  it 'has options' do
    expect(argv).to respond_to :options
    expect(argv.options).to be_an_instance_of OptionParser
  end

  shared_examples_for 'parse_bound_option_and_argument' do
    it 'parses bound option' do
      expect(argv.binder.bound_defaults).to eq(o: :STDOUT, i: :STDIN)
      expect(argv.binder.bound_variables).to eq(o: :STDOUT, i: :STDIN)
      expect(argv.parse!).to eq []
      expect(argv.binder.bound_defaults).to eq(o: :STDOUT, i: :STDIN)
      expect(argv.binder.bound_variables).to eq(o: 'file.out', i: 'file.in')
      expect(argv).to eq []
    end
  end

  shared_examples_for 'define' do
    before(:each) do
      argv.define opts do |o|
        o.opt 'o --output=<file>'
        o.arg 'i <file>'
      end
    end

    context 'target: self' do
      context 'automatically bind to #public_send' do
        include_examples 'parse_bound_option_and_argument' do
          let(:opts) do
            self.singleton_class.instance_eval { attr_accessor :o, :i }
            self.o, self.i = :STDOUT, :STDIN
            { target: self }
          end
        end
      end

      context 'bind: :to_instance_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:opts) do
            self.instance_eval { @o, @i = :STDOUT, :STDIN }
            { target: self, bind: :to_instance_variables }
          end
        end
      end
    end

    context 'target: object' do
      context 'automatically bind to #[]' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            { o: :STDOUT, i: :STDIN }
          end

          let(:opts) do
            { target: target }
          end
        end
      end

      context 'automatically bind to #public_send' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            class Target
              attr_accessor :o, :i
            end

            Target.new.tap { |t| t.o, t.i = :STDOUT, :STDIN }
          end

          let(:opts) do
            { target: target }
          end
        end
      end

      context 'bind: :to_instance_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            class Target
              def initialize
                @o, @i = :STDOUT, :STDIN
              end
            end

            Target.new
          end

          let(:opts) do
            { target: target, bind: :to_instance_variables }
          end
        end
      end

      context 'bind: :to_local_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            o, i = :STDOUT, :STDIN
            target = self.instance_eval { binding }
          end

          let(:opts) do
            { target: target, bind: :to_local_variables }
          end
        end
      end

      context 'locals: true' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            o, i = :STDOUT, :STDIN
            target = self.instance_eval { binding }
          end

          let(:opts) do
            { target: target, locals: true }
          end
        end
      end
    end
  end

  shared_examples_for 'bind' do
    before(:each) do
      argv.bind opts do |o|
        o.opt 'o --output=<file>'
        o.arg 'i <file>'
      end
    end

    context 'to: self' do
      context 'automatically via #public_send' do
        include_examples 'parse_bound_option_and_argument' do
          let(:opts) do
            self.singleton_class.instance_eval { attr_accessor :o, :i }
            self.o, self.i = :STDOUT, :STDIN
            { to: self }
          end
        end
      end

      context 'via: :instance_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:opts) do
            self.instance_eval { @o, @i = :STDOUT, :STDIN }
            { to: self, via: :instance_variables }
          end
        end
      end
    end

    context 'to: target' do
      context 'automatically via #[]' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            { o: :STDOUT, i: :STDIN }
          end

          let(:opts) do
            { to: target }
          end
        end
      end

      context 'automatically via #public_send' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            class Target
              attr_accessor :o, :i
            end

            Target.new.tap { |t| t.o, t.i = :STDOUT, :STDIN }
          end

          let(:opts) do
            { to: target }
          end
        end
      end

      context 'via: :instance_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            class Target
              def initialize
                @o, @i = :STDOUT, :STDIN
              end
            end

            Target.new
          end

          let(:opts) do
            { to: target, via: :instance_variables }
          end
        end
      end

      context 'via: :local_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            o, i = :STDOUT, :STDIN
            target = self.instance_eval { binding }
          end

          let(:opts) do
            { to: target, via: :local_variables }
          end
        end
      end

      context 'locals: true' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            o, i = :STDOUT, :STDIN
            target = self.instance_eval { binding }
          end

          let(:opts) do
            { to: target, locals: true }
          end
        end
      end
    end
  end

  shared_examples_for 'bind_to_locals' do
    before(:each) do
      @toplevel_binding = TOPLEVEL_BINDING
      @verbose, $VERBOSE = $VERBOSE, nil

      o, i = :STDOUT, :STDIN
      TOPLEVEL_BINDING = self.instance_eval { binding }

      argv.bind opts do |o|
        o.opt 'o --output=<file>'
        o.arg 'i <file>'
      end
    end

    after(:each) do
      TOPLEVEL_BINDING = @toplevel_binding
      $VERBOSE = @verbose
    end

    context 'to: :locals' do
      include_examples 'parse_bound_option_and_argument' do
        let(:opts) do
          { to: :locals }
        end
      end
    end
  end

  describe '#define' do
    include_examples 'define'
  end

  describe '#bind' do
    include_examples 'bind'
  end

  describe '#bind' do
    include_examples 'bind_to_locals'
  end

  describe '#define_and_bind' do
    include_examples 'define'
  end

  describe '#define_and_bind' do
    include_examples 'bind'
  end

  describe '#define_and_bind' do
    include_examples 'bind_to_locals'
  end
end
