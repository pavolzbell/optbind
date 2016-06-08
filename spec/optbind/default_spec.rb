require 'spec_helper'

describe OptBind do
  before(:each) do
    require 'optbind/default'

    stub_const 'PROGRAM', 'meow'
  end

  describe '#help' do
    context 'with complex variants' do
      context 'with mixed options and defaults' do
        let(:target) do
          {
            q: false,
            d: true,
            f: nil,
            v: true,
            i: false,
            s: nil,
            P: 'common-',
            S: '-0',
            r: '/',
            x: nil,
            t: 120,
            o: :desc,
            a: nil,
            b: 'to-locals',
            y: nil,
            z: 'unknown error',
            j: nil,
            c: 'master'
          }
        end

        let(:options) do
          OptBind.new target: target
        end

        it 'returns help' do
          options.opt 'q -q    --quiet'
          options.opt 'd -d    --dump                                  Dumps some stuff'
          options.opt 'f -f    --repair        --fix                   Repairs and fixes stuff'
          options.opt 'v -v    --[no-]validate --check'
          options.opt 'i -i -I --interactive'
          options.opt 's -s -w --[no-]sort                             Sorts stuff, simple as that'
          options.opt 'P -P    --pfx --prefix=<string>'
          options.opt 'S -S    --sfx --suffix=<string>                 Sets some suffix'
          options.opt 'r -r -R --root=<path>'
          options.opt 'x -x -X --extra=<data>                          Some extra stuff, really good'
          options.opt 't -t    --trim[=<size>]'
          options.opt 'o -o    --order[=(asc|desc)]                    Orders stuff, not as simple as that'
          options.opt 'a -a -A --append[=<string>]                     Appends some stuff'
          options.opt 'b -b -B --bind[=<data>]'
          options.opt 'y -y    --yield[=<block>]  --block'
          options.opt 'z -z    --fail[=<message>] --raise              Fails'
          options.opt 'j -j -J --j2b --jump-to-bin[=<path>]'
          options.opt 'c -c -C --chk --checkout[=<ref>]                Checkouts some important stuff'

          expect(options.help).to eq <<-HLP
usage: meow [<options>]

    -q, --quiet                      Default false
    -d, --dump                       Dumps some stuff, default true
    -f, --repair, --fix              Repairs and fixes stuff
    -v, --[no-]validate, --check     Default true
    -i, -I, --interactive            Default false
    -s, -w, --[no-]sort              Sorts stuff, simple as that
    -P, --pfx, --prefix=<string>     Default common-
    -S, --sfx, --suffix=<string>     Sets some suffix, default -0
    -r, -R, --root=<path>            Default /
    -x, -X, --extra=<data>           Some extra stuff, really good
    -t, --trim[=<size>]              Default 120
    -o, --order[=(asc|desc)]         Orders stuff, not as simple as that, default desc
    -a, -A, --append[=<string>]      Appends some stuff
    -b, -B, --bind[=<data>]          Default to-locals
    -y, --yield, --block[=<block>]
    -z, --fail, --raise[=<message>]  Fails, default unknown error
    -j, -J, --j2b[<path>],
        --jump-to-bin
    -c, -C, --chk[<ref>],            Checkouts some important stuff, default master
        --checkout
    -h, --help
        --version

          HLP
        end
      end
    end
  end
end
