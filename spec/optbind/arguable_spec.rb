require 'spec_helper'

describe OptBind::Arguable do
  let(:argv) do
    %w(--output=file.out)
  end

  before(:each) do
    argv.extend OptParse::Arguable
    argv.extend OptBind::Arguable
  end

  shared_examples_for 'parse' do
    it 'parses bound option' do
      expect(argv.binder.bound_defaults).to eq(o: STDOUT)
      expect(argv.binder.bound_variables).to eq(o: STDOUT)
      expect(argv.parse!).to eq []
      expect(argv.binder.bound_defaults).to eq(o: STDOUT)
      expect(argv.binder.bound_variables).to eq(o: 'file.out')
      expect(argv).to eq []
    end
  end

  shared_examples_for 'define' do
    before(:each) do
      argv.define opts do |o|
        o.opt 'o --output=<file>'
      end
    end

    context 'target: self' do
      context 'automatically bind to #public_send' do
        include_examples 'parse' do
          let(:opts) do
            self.singleton_class.instance_eval { attr_accessor :o }
            self.o = STDOUT
            { target: self }
          end
        end
      end

      context 'bind: :to_instance_variables' do
        include_examples 'parse' do
          let(:opts) do
            self.instance_eval { @o = STDOUT }
            { target: self, bind: :to_instance_variables }
          end
        end
      end
    end

    context 'target: object' do
      context 'automatically bind to #[]' do
        include_examples 'parse' do
          let(:target) do
            { o: STDOUT }
          end

          let(:opts) do
            { target: target }
          end
        end
      end

      context 'automatically bind to #public_send' do
        include_examples 'parse' do
          let(:target) do
            class Target
              attr_accessor :o
            end

            Target.new.tap { |t| t.o = STDOUT }
          end

          let(:opts) do
            { target: target }
          end
        end
      end

      context 'bind: :to_instance_variables' do
        include_examples 'parse' do
          let(:target) do
            class Target
              def initialize
                @o = STDOUT
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
        include_examples 'parse' do
          let(:target) do
            o = STDOUT
            target = self.instance_eval { binding }
          end

          let(:opts) do
            { target: target, bind: :to_local_variables }
          end
        end
      end

      context 'locals: true' do
        include_examples 'parse' do
          let(:target) do
            o = STDOUT
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
      end
    end

    context 'to: self' do
      context 'automatically via #public_send' do
        include_examples 'parse' do
          let(:opts) do
            self.singleton_class.instance_eval { attr_accessor :o }
            self.o = STDOUT
            { to: self }
          end
        end
      end

      context 'via: :instance_variables' do
        include_examples 'parse' do
          let(:opts) do
            self.instance_eval { @o = STDOUT }
            { to: self, via: :instance_variables }
          end
        end
      end
    end

    context 'to: target' do
      context 'automatically via #[]' do
        include_examples 'parse' do
          let(:target) do
            { o: STDOUT }
          end

          let(:opts) do
            { to: target }
          end
        end
      end

      context 'automatically via #public_send' do
        include_examples 'parse' do
          let(:target) do
            class Target
              attr_accessor :o
            end

            Target.new.tap { |t| t.o = STDOUT }
          end

          let(:opts) do
            { to: target }
          end
        end
      end

      context 'via: :instance_variables' do
        include_examples 'parse' do
          let(:target) do
            class Target
              def initialize
                @o = STDOUT
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
        include_examples 'parse' do
          let(:target) do
            o = STDOUT
            target = self.instance_eval { binding }
          end

          let(:opts) do
            { to: target, via: :local_variables }
          end
        end
      end

      context 'locals: true' do
        include_examples 'parse' do
          let(:target) do
            o = STDOUT
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

      o = STDOUT
      TOPLEVEL_BINDING = self.instance_eval { binding }

      argv.bind opts do |o|
        o.opt 'o --output=<file>'
      end
    end

    after(:each) do
      TOPLEVEL_BINDING = @toplevel_binding
      $VERBOSE = @verbose
    end

    context 'to: :locals' do
      include_examples 'parse' do
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
    include_examples 'bind'
  end

  describe '#define_and_bind' do
    include_examples 'bind_to_locals'
  end
end
