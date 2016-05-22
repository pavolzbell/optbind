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

    context 'with PROGRAM' do
      it 'returns custom name' do
        stub_const 'PROGRAM', 'Meow'
        expect(options.program).to eq 'Meow'
      end
    end

    context 'without PROGRAM' do
      it 'returns script name' do
        expect(options.program).to eq 'meow'
      end
    end
  end

  describe '#version' do
    let(:options) { OptBind.new }

    context 'with VERSION' do
      it 'returns custom version' do
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
usage: meow [<options>]

    -h, --help
        --version

      HLP
    end

    context 'with usage' do
      it 'returns help' do
        options.use '[<options>] <file>'

        expect(options.help).to eq <<-HLP
usage: meow [<options>] <file>

    -h, --help
        --version

        HLP
      end
    end

    context 'with option' do
      it 'returns help' do
        options.opt '-o --output=<file>'

        expect(options.help).to eq <<-HLP
usage: meow [<options>]

    -o, --output=<file>
    -h, --help
        --version

        HLP
      end
    end

    context 'with simple variants' do
      it 'returns help' do
        options.use '[<options>] <file>'
        options.use '--help'
        options.use '--version'
        options.opt '-i --[no-]interactive'
        options.opt '   --trim[=<size>]'
        options.opt '-o --output=<file>'
        options.opt '-q --quiet'
        options.arg '<file>'

        expect(options.help).to eq <<-HLP
usage: meow [<options>] <file>
   or: meow --help
   or: meow --version

    -i, --[no-]interactive
        --trim[=<size>]
    -o, --output=<file>
    -q, --quiet
    -h, --help
        --version

        HLP
      end
    end

    context 'with complex variants' do
      context 'with usages and arguments' do
        it 'returns help' do
          options.use '--init <directory>...'
          options.use '[<options>] <branch>'
          options.use '[<options>] [<branch>] <file>'
          options.use '--help'
          options.use '--version'

          options.arg '<path_or_branch>'
          options.arg '[<file>]'

          expect(options.help).to eq <<-HLP
usage: meow --init <directory>...
   or: meow [<options>] <branch>
   or: meow [<options>] [<branch>] <file>
   or: meow --help
   or: meow --version

    -h, --help
        --version

          HLP
        end
      end

      context 'with short options' do
        it 'returns help' do
            options.opt '-a'
            options.opt '-v                      Be more verbose.'
            options.opt '-q -Q'
            options.opt '-e -x                   Export some stuff.'
            options.opt '-o     =(asc|desc)'
            options.opt '-s     =(v0|v1|v2)      Specifies schema version. Easy stuff.'
            options.opt '-m     =<directory>'
            options.opt '-n     =<path>          Path to file with names.'
            options.opt '-r -R  =<ref>'
            options.opt '-h -H  =<hash>          Nice hash.'
            options.opt '-c    [=<ref>]'
            options.opt '-t    [=<size>]         Trims to size, 80 by default.'
            options.opt '-w -W [=<ref>]'
            options.opt '-z -Z [=<size>]         Special size.'

            expect(options.help).to eq <<-HLP
usage: meow [<options>]

    -a
    -v                               Be more verbose.
    -q, -Q
    -e, -x                           Export some stuff.
    -o=(asc|desc)
    -s=(v0|v1|v2)                    Specifies schema version. Easy stuff.
    -m=<directory>
    -n=<path>                        Path to file with names.
    -r, -R=<ref>
    -h, -H=<hash>                    Nice hash.
    -c[=<ref>]
    -t[=<size>]                      Trims to size, 80 by default.
    -w, -W[=<ref>]
    -z, -Z[=<size>]                  Special size.
    -h, --help
        --version

          HLP
        end
      end

      context 'with long options' do
        it 'returns help' do
          options.opt '--abort'
          options.opt '--[no-]verbose                                Be more verbose.'
          options.opt '--quiet  --silent'
          options.opt '--export --dump                               Export some stuff.'
          options.opt '--order                    =(asc|desc)'
          options.opt '--schema                   =(v0|v1|v2)        Specifies schema version. Easy stuff.'
          options.opt '--main                     =<directory>'
          options.opt '--names                    =<path>            Path to file with names.'
          options.opt '--reference --ref          =<ref>'
          options.opt '--hash --schema-hash       =<hash>            Nice hash.'
          options.opt '--checkout                [=<ref>]'
          options.opt '--trim                    [=<size>]           Trims to size, 80 by default.'
          options.opt '--extra --extra-reference [=<ref>]'
          options.opt '--bucket --bucket-size    [=<size>]           Special size.'

          expect(options.help).to eq <<-HLP
usage: meow [<options>]

        --abort
        --[no-]verbose               Be more verbose.
        --quiet, --silent
        --export, --dump             Export some stuff.
        --order=(asc|desc)
        --schema=(v0|v1|v2)          Specifies schema version. Easy stuff.
        --main=<directory>
        --names=<path>               Path to file with names.
        --reference, --ref=<ref>
        --hash, --schema-hash=<hash> Nice hash.
        --checkout[=<ref>]
        --trim[=<size>]              Trims to size, 80 by default.
        --extra, --extra-reference[=<ref>]
        --bucket, --bucket-size[=<size>]
                                     Special size.
    -h, --help
        --version

          HLP
        end
      end

      context 'with mixed options' do
        it 'returns help' do
          options.opt '-q    --quiet'
          options.opt '-d    --dump                                  Dumps some stuff.'
          options.opt '-f    --repair        --fix                   Repairs and fixes stuff.'
          options.opt '-v    --[no-]validate --check'
          options.opt '-i -I --interactive'
          options.opt '-s -w --[no-]sort                             Sorts stuff. Simple as that.'
          options.opt '-P    --pfx --prefix=<string>'
          options.opt '-S    --sfx --suffix=<string>                 Sets some suffix.'
          options.opt '-r -R --root=<path>'
          options.opt '-x -X --extra=<data>                          Some extra stuff. Really good.'
          options.opt '-t    --trim[=<size>]'
          options.opt '-o    --order[=(asc|desc)]                    Orders stuff. Not as simple as that.'
          options.opt '-a -A --append[=<string>]                     Appends some stuff.'
          options.opt '-b -B --bind[=<data>]'
          options.opt '-y    --yield[=<block>]  --block'
          options.opt '-z    --fail[=<message>] --raise              Fails.'
          options.opt '-j -J --j2b --jump-to-bin[=<path>]'
          options.opt '-c -C --chk --checkout[=<ref>]                Checkouts some important stuff.'

          expect(options.help).to eq <<-HLP
usage: meow [<options>]

    -q, --quiet
    -d, --dump                       Dumps some stuff.
    -f, --repair, --fix              Repairs and fixes stuff.
    -v, --[no-]validate, --check
    -i, -I, --interactive
    -s, -w, --[no-]sort              Sorts stuff. Simple as that.
    -P, --pfx, --prefix=<string>
    -S, --sfx, --suffix=<string>     Sets some suffix.
    -r, -R, --root=<path>
    -x, -X, --extra=<data>           Some extra stuff. Really good.
    -t, --trim[=<size>]
    -o, --order[=(asc|desc)]         Orders stuff. Not as simple as that.
    -a, -A, --append[=<string>]      Appends some stuff.
    -b, -B, --bind[=<data>]
    -y, --yield, --block[=<block>]
    -z, --fail, --raise[=<message>]  Fails.
    -j, -J, --j2b[<path>],
        --jump-to-bin
    -c, -C, --chk[<ref>],            Checkouts some important stuff.
        --checkout
    -h, --help
        --version

          HLP
        end
      end
    end
  end

  describe 'creating a binder and binding an option' do
    shared_examples_for 'create_and_bind' do
      it 'creates and binds' do
        options = OptBind.new target: target, bind: bind

        expect(options.bound_defaults.key? :o).to be false
        expect(options.bound_variables.key? :o).to be false
        expect(options.assigned_variables.key? :o).to be false
        expect(options.default? :o).to be nil
        expect(options.bound? :o).to be false
        expect(options.assigned? :o).to be nil
        expect(options.opt 'o --output').to equal options
        expect(options.bound_defaults.key? :o).to be true
        expect(options.bound_variables.key? :o).to be true
        expect(options.assigned_variables.key? :o).to be false
        expect(options.default? :o).to be true
        expect(options.bound? :o).to be true
        expect(options.assigned? :o).to be false
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
          target_class = Class.new do
            attr_accessor :o
          end

          target_class.new.tap { |t| t.o = :STDOUT }
        end

        let(:bind) do
          false
        end
      end
    end

    context 'bound via #class_variables' do
      include_examples 'create_and_bind' do
        let(:target) do
          Class.new do
            class_variable_set :@@o, :STDOUT
          end
        end

        let(:bind) do
          :to_class_variables
        end
      end
    end

    context 'bound via #instance_variables' do
      include_examples 'create_and_bind' do
        let(:target) do
          target_class = Class.new do
            def initialize
              @o = :STDOUT
            end
          end

          target_class.new
        end

        let(:bind) do
          :to_instance_variables
        end
      end
    end

    context 'bound via #local_variables' do
      include_examples 'create_and_bind' do
        let(:target) do
          o = :STDOUT

          self.instance_eval { binding }
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
        def write_through(options, variable, value)
          options.instance_eval { handle! nil, value, true, variable, nil }
        end

        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: :STDOUT)
        expect(options.assigned_variables).to eq({})
        write_through options, :o, :STDERR
        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: :STDERR)
        expect(options.assigned_variables).to eq(o: :STDERR)
        writer.call :o, :STDIN
        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: :STDIN)
        expect(options.assigned_variables).to eq(o: :STDERR)
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
          target_class = Class.new do
            attr_accessor :o
          end

          target_class.new.tap { |t| t.o = :STDOUT }
        end

        let(:bind) do
          false
        end

        let(:writer) do
          -> (v, x) { target.public_send "#{v}=", x }
        end
      end
    end

    context 'bound via #class_variables' do
      include_examples 'read_and_write' do
        let(:target) do
          Class.new do
            class_variable_set :@@o, :STDOUT
          end
        end

        let(:bind) do
          :to_class_variables
        end

        let(:writer) do
          -> (v, x) { target.class_variable_set "@@#{v}", x }
        end
      end
    end

    context 'bound via #instance_variables' do
      include_examples 'read_and_write' do
        let(:target) do
          target_class = Class.new do
            def initialize
              @o = :STDOUT
            end
          end

          target_class.new
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

          self.instance_eval { binding }
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
        expect(options.assigned_variables).to eq({})
        expect(options.parse('--output=file.out')).to contain_exactly('--output=file.out')
        expect(options.bound_defaults).to eq(o: :STDOUT)
        expect(options.bound_variables).to eq(o: 'file.out')
        expect(options.assigned_variables).to eq(o: 'file.out')
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
          target_class = Class.new do
            attr_accessor :o
          end

          target_class.new.tap { |t| t.o = :STDOUT }
        end

        let(:bind) do
          false
        end
      end
    end

    context 'bound via #class_variables' do
      include_examples 'parse' do
        let(:target) do
          Class.new do
            class_variable_set :@@o, :STDOUT
          end
        end

        let(:bind) do
          :to_class_variables
        end
      end
    end

    context 'bound via #instance_variables' do
      include_examples 'parse' do
        let(:target) do
          target_class = Class.new do
            def initialize
              @o = :STDOUT
            end
          end

          target_class.new
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

          self.instance_eval { binding }
        end

        let(:bind) do
          :to_local_variables
        end
      end
    end
  end

  describe 'parsing a required option' do
    let(:options) do
      OptBind.new do |o|
        o.opt '--output=<file>'
        o.opt '--trim=<size:Integer>'
      end
    end

    context 'with missing argument' do
      it 'raises an error' do
        expect { options.parse %w(--output) }.to raise_error OptionParser::MissingArgument, 'missing argument: --output'
        expect { options.parse %w(--trim) }.to raise_error OptionParser::MissingArgument, 'missing argument: --trim'
      end
    end

    context 'with invalid argument' do
      it 'raises an error' do
        expect { options.parse %w(--output=) }.to raise_error OptionParser::InvalidArgument, 'invalid argument: --output='
        expect { options.parse %w(--trim=) }.to raise_error OptionParser::InvalidArgument, 'invalid argument: --trim='
        expect { options.parse %w(--trim=?) }.to raise_error OptionParser::InvalidArgument, 'invalid argument: --trim=?'
      end
    end
  end

  describe 'parsing an optional option' do
    let(:options) do
      OptBind.new do |o|
        o.opt '--output[=<file>]'
        o.opt '--trim[=<count:Integer>]'
      end
    end

    context 'with missing argument' do
      it 'parses' do
        expect { options.parse %w(--output) }.not_to raise_error
        expect { options.parse %w(--trim) }.not_to raise_error
      end
    end

    context 'with invalid argument' do
      it 'raises an error' do
        expect { options.parse %w(--trim=) }.to raise_error OptionParser::InvalidArgument, 'invalid argument: --trim='
        expect { options.parse %w(--trim=?) }.to raise_error OptionParser::InvalidArgument, 'invalid argument: --trim=?'
      end
    end
  end

  describe 'parsing an unknown option' do
    let(:options) do
      OptBind.new
    end

    it 'raises an error' do
      expect { options.parse %w(--trim) }.to raise_error OptionParser::InvalidOption, 'invalid option: --trim'
      expect { options.parse %w(--trim=) }.to raise_error OptionParser::InvalidOption, 'invalid option: --trim='
      expect { options.parse %w(--trim=?) }.to raise_error OptionParser::InvalidOption, 'invalid option: --trim=?'
    end
  end
end
