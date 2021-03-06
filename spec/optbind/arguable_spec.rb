require 'spec_helper'

describe OptBind::Arguable do
  let (:already_parsed) { false }
  let (:destructive_approach) { false }

  let(:argv) do
    %w(--output=file.out file.in)
  end

  before(:each) do
    argv.extend OptBind::Arguable
  end

  it 'is arguable by option binder' do
    expect(subject.included_modules).not_to include OptionBinder::Arguable
  end

  it 'has binder accessor' do
    expect(argv).to respond_to :binder
    expect(argv).to respond_to :binder=
    expect(argv.binder).to be_an_instance_of OptionBinder
  end

  it 'has parser reader' do
    expect(argv).to respond_to :parser
    expect(argv.parser).to be_an_instance_of OptionParser
  end

  it 'has target reader' do
    expect(argv).to respond_to :target
    expect(argv.target).to eq TOPLEVEL_BINDING
  end

  it 'is not arguable by option parser' do
    expect(argv.singleton_class.included_modules).not_to include OptionParser::Arguable
  end

  it 'has no options accessor' do
    expect(argv).not_to respond_to :options
    expect(argv).not_to respond_to :options=
  end
  it 'has no parse modes' do
    expect(argv).not_to respond_to :order
    expect(argv).not_to respond_to :order!
    expect(argv).not_to respond_to :permute
    expect(argv).not_to respond_to :permute!
  end

  context 'with OptParse::Arguable included before' do
    before(:each) do
      argv.extend OptParse::Arguable
      argv.extend OptBind::Arguable
    end

    it 'is arguable by option parser' do
      expect(argv.singleton_class.included_modules).to include OptionParser::Arguable
    end

    it 'has options accessor' do
      expect(argv).to respond_to :options
      expect(argv).to respond_to :options=
      expect(argv.options).to be_an_instance_of OptionParser
    end

    it 'has unsupported parse modes' do
      expect(argv).not_to respond_to :order
      expect(argv).not_to respond_to :permute

      expect(argv).to respond_to :order!
      expect(argv).to respond_to :permute!

      expect{ argv.order! }.to raise_error RuntimeError, 'unsupported'
      expect{ argv.permute! }.to raise_error RuntimeError, 'unsupported'
    end
  end

  shared_examples_for 'define_bound_option_and_argument' do |define|
    it 'defines bound option and argument' do
      define.call argv
      expect(argv.binder).to be_an_instance_of OptionBinder
      expect(argv.binder.bound_defaults.keys).to contain_exactly :o, :i
      expect(argv.binder.bound_variables.keys).to contain_exactly :o, :i
    end
  end

  shared_examples_for 'parse_bound_option_and_argument' do
    it 'parses bound option and argument' do
      orig = argv.dup

      unless already_parsed
        expect(argv.binder.bound_defaults).to eq o: :STDOUT, i: :STDIN
        expect(argv.binder.bound_variables).to eq o: :STDOUT, i: :STDIN
        expect(argv.binder.assigned_variables).to be_empty

        if destructive_approach
          expect(argv.parse!).to be_empty
          expect(argv).to be_empty
        else
          expect(argv.parse).to be_empty
          expect(argv).to eq orig
        end
      end

      expect(argv.binder.bound_defaults).to eq o: :STDOUT, i: :STDIN
      expect(argv.binder.bound_variables).to eq o: 'file.out', i: 'file.in'
      expect(argv.binder.assigned_variables).to eq o: 'file.out', i: 'file.in'

      if destructive_approach
        expect(argv).to be_empty
      else
        expect(argv).to eq orig
      end
    end
  end

  shared_examples_for 'define_variants' do |method = :define|
    context 'with block' do
      include_examples 'define_bound_option_and_argument', -> (argv) do
        argv.public_send method, target: { o: nil, i: nil } do
          opt 'o --output=<file>'
          arg 'i <file>'
        end
      end
    end

    context 'with block via variable' do
      include_examples 'define_bound_option_and_argument', -> (argv) do
        argv.public_send method, target: { o: nil, i: nil } do |o|
          o.opt 'o --output=<file>'
          o.arg 'i <file>'
        end
      end
    end
  end

  shared_examples_for 'define_with_target' do |method = :define|
    before(:each) do
      argv.public_send method, opts do |o|
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
            target_class = Class.new do
              attr_accessor :o, :i
            end

            target_class.new.tap { |t| t.o, t.i = :STDOUT, :STDIN }
          end

          let(:opts) do
            { target: target }
          end
        end
      end

      context 'bind: :to_class_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            Class.new do
              class_variable_set :@@o, :STDOUT
              class_variable_set :@@i, :STDIN
            end
          end

          let(:opts) do
            { target: target, bind: :to_class_variables }
          end
        end
      end

      context 'bind: :to_instance_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            target_class = Class.new do
              def initialize
                @o, @i = :STDOUT, :STDIN
              end
            end

            target_class.new
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

            self.instance_eval { binding }
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

            self.instance_eval { binding }
          end

          let(:opts) do
            { target: target, locals: true }
          end
        end
      end
    end
  end

  shared_examples_for 'bind_variants' do |method = :bind|
    if method.to_s =~ /_?parse[_!]?/
      raise "Unable to call #{method} without block, variables must be bound before parsing"
    end

    context 'with block' do
      include_examples 'define_bound_option_and_argument', -> (argv) do
        argv.public_send method, to: { o: nil, i: nil } do
          opt 'o --output=<file>'
          arg 'i <file>'
        end
      end
    end

    context 'with block via variable' do
      include_examples 'define_bound_option_and_argument', -> (argv) do
        argv.public_send method, to: { o: nil, i: nil } do |o|
          o.opt 'o --output=<file>'
          o.arg 'i <file>'
        end
      end
    end

    context 'without block' do
      include_examples 'define_bound_option_and_argument', -> (argv) do
        argv.public_send method, to: { o: nil, i: nil }
        argv.binder.opt 'o --output=<file>'
        argv.binder.arg 'i <file>'
      end
    end
  end

  shared_examples_for 'bind_to_target' do |method = :bind|
    before(:each) do
      argv.public_send method, opts do |o|
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
            target_class = Class.new do
              attr_accessor :o, :i
            end

            target_class.new.tap { |t| t.o, t.i = :STDOUT, :STDIN }
          end

          let(:opts) do
            { to: target }
          end
        end
      end

      context 'via: :class_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            Class.new do
              class_variable_set :@@o, :STDOUT
              class_variable_set :@@i, :STDIN
            end
          end

          let(:opts) do
            { to: target, via: :class_variables }
          end
        end
      end

      context 'via: :instance_variables' do
        include_examples 'parse_bound_option_and_argument' do
          let(:target) do
            target_class = Class.new do
              def initialize
                @o, @i = :STDOUT, :STDIN
              end
            end

            target_class.new
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

            self.instance_eval { binding }
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

            self.instance_eval { binding }
          end

          let(:opts) do
            { to: target, locals: true }
          end
        end
      end
    end
  end

  shared_examples_for 'bind_to_locals' do |method = :bind|
    before(:each) do
      @toplevel_binding = TOPLEVEL_BINDING
      @verbose, $VERBOSE = $VERBOSE, nil

      o, i = :STDOUT, :STDIN
      TOPLEVEL_BINDING = self.instance_eval { binding }

      argv.public_send method, opts do |o|
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

  # define

  describe '#define' do
    include_examples 'define_variants'
  end

  describe '#define' do
    include_examples 'define_with_target'
  end

  # bind

  describe '#bind' do
    include_examples 'bind_variants'
  end

  describe '#bind' do
    include_examples 'bind_to_target'
  end

  describe '#bind' do
    include_examples 'bind_to_locals'
  end

  # define_and_bind

  describe '#define_and_bind' do
    include_examples 'bind_variants', :define_and_bind
  end

  describe '#define_and_bind' do
    include_examples 'define_with_target', :define_and_bind
  end

  describe '#define_and_bind' do
    include_examples 'bind_to_target', :define_and_bind
  end

  describe '#define_and_bind' do
    include_examples 'bind_to_locals', :define_and_bind
  end

  # define_and_parse

  describe '#define_and_parse' do
    include_examples 'define_variants', :define_and_parse
  end

  describe '#define_and_parse' do
    let (:already_parsed) { true }

    include_examples 'define_with_target', :define_and_parse
  end

  # bind_and_parse

  describe '#bind_and_parse' do
    include_examples 'define_variants', :bind_and_parse
  end

  describe '#bind_and_parse' do
    let (:already_parsed) { true }

    include_examples 'bind_to_target', :bind_and_parse
  end

  describe '#bind_and_parse' do
    let (:already_parsed) { true }

    include_examples 'bind_to_locals', :bind_and_parse
  end

  # define_and_parse!

  describe '#define_and_parse!' do
    let (:destructive_approach) { true }

    include_examples 'define_variants', :define_and_parse!
  end

  describe '#define_and_parse!' do
    let (:already_parsed) { true }
    let (:destructive_approach) { true }

    include_examples 'define_with_target', :define_and_parse!
  end

  # bind_and_parse!

  describe '#bind_and_parse!' do
    let (:destructive_approach) { true }

    include_examples 'define_variants', :bind_and_parse!
  end

  describe '#bind_and_parse!' do
    let (:already_parsed) { true }
    let (:destructive_approach) { true }

    include_examples 'bind_to_target', :bind_and_parse!
  end

  describe '#bind_and_parse!' do
    let (:already_parsed) { true }
    let (:destructive_approach) { true }

    include_examples 'bind_to_locals', :bind_and_parse!
  end
end
