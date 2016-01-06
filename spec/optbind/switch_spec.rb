require 'spec_helper'

describe OptBind::Switch do
  describe '.parser_opts_from_hash' do
    context 'with no arguments' do
      it 'returns nothing' do
        expect(subject.parser_opts_from_hash).to contain_exactly [], nil
        expect(subject.parser_opts_from_hash({})).to contain_exactly [], nil
      end
    end

    context 'with style or mode' do
      it 'returns style' do
        expect(subject.parser_opts_from_hash style: :REQUIRED).to contain_exactly [:REQUIRED], nil
        expect(subject.parser_opts_from_hash mode: :OPTIONAL).to contain_exactly [:OPTIONAL], nil

        expect(subject.parser_opts_from_hash style: :OPTIONAL, mode: :REQUIRED).to contain_exactly [:OPTIONAL], nil
        expect(subject.parser_opts_from_hash mode: :OPTIONAL, style: :REQUIRED).to contain_exactly [:REQUIRED], nil
      end

      it 'ignores case' do
        expect(subject.parser_opts_from_hash style: :required).to contain_exactly [:REQUIRED], nil
      end

      it 'handles strings' do
        expect(subject.parser_opts_from_hash style: 'REQUIRED').to contain_exactly [:REQUIRED], nil
        expect(subject.parser_opts_from_hash mode: 'OPTIONAL').to contain_exactly [:OPTIONAL], nil
      end
    end

    context 'with pattern or type' do
      it 'returns pattern' do
        expect(subject.parser_opts_from_hash pattern: //).to contain_exactly [//], nil
        expect(subject.parser_opts_from_hash type: Object).to contain_exactly [Object], nil

        expect(subject.parser_opts_from_hash pattern: //, type: Object).to contain_exactly [//], nil
        expect(subject.parser_opts_from_hash type: Object, pattern: //).to contain_exactly [//], nil
      end
    end

    context 'with values' do
      it 'returns values' do
        expect(subject.parser_opts_from_hash values: %w(on off)).to contain_exactly [%w(on off)], nil
        expect(subject.parser_opts_from_hash values: { on: 1, off: 0 }).to contain_exactly [{ on: 1, off: 0 }], nil
      end
    end

    context 'with long or longs' do
      it 'returns longs' do
        expect(subject.parser_opts_from_hash long: '--v').to contain_exactly %w(--v), nil
        expect(subject.parser_opts_from_hash long: '--verbose').to contain_exactly %w(--verbose), nil
        expect(subject.parser_opts_from_hash longs: %w(--v --verbose)).to contain_exactly %w(--v --verbose), nil
      end

      it 'fixes shorts and unknowns' do
        expect(subject.parser_opts_from_hash long: 'v').to contain_exactly %w(--v), nil
        expect(subject.parser_opts_from_hash long: '-v').to contain_exactly %w(--v), nil

        expect(subject.parser_opts_from_hash long: 'verbose').to contain_exactly %w(--verbose), nil
        expect(subject.parser_opts_from_hash long: '-verbose').to contain_exactly %w(--verbose), nil

        expect(subject.parser_opts_from_hash longs: %w(v s)).to contain_exactly %w(--v --s), nil
        expect(subject.parser_opts_from_hash longs: %w(-v -s)).to contain_exactly %w(--v --s), nil

        expect(subject.parser_opts_from_hash longs: %w(verbose silent)).to contain_exactly %w(--verbose --silent), nil
        expect(subject.parser_opts_from_hash longs: %w(-verbose -silent)).to contain_exactly %w(--verbose --silent), nil
      end

      it 'handles symbols' do
        expect(subject.parser_opts_from_hash longs: %i(v s)).to contain_exactly %w(--v --s), nil
        expect(subject.parser_opts_from_hash longs: %i(verbose silent)).to contain_exactly %w(--verbose --silent), nil
      end
    end

    context 'with short or shorts' do
      it 'returns shorts' do
        expect(subject.parser_opts_from_hash short: '-v').to contain_exactly %w(-v), nil
        expect(subject.parser_opts_from_hash short: '-verbose').to contain_exactly %w(-verbose), nil
        expect(subject.parser_opts_from_hash shorts: %w(-v -verbose)).to contain_exactly %w(-v -verbose), nil
      end

      it 'fixes longs and unknowns' do
        expect(subject.parser_opts_from_hash short: 'v').to contain_exactly %w(-v), nil
        expect(subject.parser_opts_from_hash short: '--v').to contain_exactly %w(-v), nil

        expect(subject.parser_opts_from_hash short: 'verbose').to contain_exactly %w(-verbose), nil
        expect(subject.parser_opts_from_hash short: '--verbose').to contain_exactly %w(-verbose), nil

        expect(subject.parser_opts_from_hash shorts: %w(v s)).to contain_exactly %w(-v -s), nil
        expect(subject.parser_opts_from_hash shorts: %w(--v --s)).to contain_exactly %w(-v -s), nil

        expect(subject.parser_opts_from_hash shorts: %w(verbose silent)).to contain_exactly %w(-verbose -silent), nil
        expect(subject.parser_opts_from_hash shorts: %w(--verbose --silent)).to contain_exactly %w(-verbose -silent), nil
      end

      it 'handles symbols' do
        expect(subject.parser_opts_from_hash shorts: %i(v s)).to contain_exactly %w(-v -s), nil
        expect(subject.parser_opts_from_hash shorts: %i(verbose silent)).to contain_exactly %w(-verbose -silent), nil
      end
    end

    context 'with name or names' do
      it 'returns longs and shorts' do
        expect(subject.parser_opts_from_hash name: '-v').to contain_exactly %w(-v), nil
        expect(subject.parser_opts_from_hash name: '-verbose').to contain_exactly %w(-verbose), nil

        expect(subject.parser_opts_from_hash name: '--v').to contain_exactly %w(--v), nil
        expect(subject.parser_opts_from_hash name: '--verbose').to contain_exactly %w(--verbose), nil

        expect(subject.parser_opts_from_hash names: %w(-v --verbose)).to contain_exactly %w(-v --verbose), nil
      end

      it 'fixes unknowns' do
        expect(subject.parser_opts_from_hash name: 'v').to contain_exactly %w(-v), nil
        expect(subject.parser_opts_from_hash name: 'verbose').to contain_exactly %w(--verbose), nil

        expect(subject.parser_opts_from_hash names: %w(v verbose)).to contain_exactly %w(-v --verbose), nil
      end

      it 'handles symbols' do
        expect(subject.parser_opts_from_hash names: %i(v verbose)).to contain_exactly %w(-v --verbose), nil
      end
    end

    context 'with argument' do
      it 'returns argument' do
        expect(subject.parser_opts_from_hash argument: '=<path>').to contain_exactly %w(=<path>), nil
        expect(subject.parser_opts_from_hash argument: '=[<path>]').to contain_exactly %w(=[<path>]), nil
        expect(subject.parser_opts_from_hash argument: '[=<path>]').to contain_exactly %w(=[<path>]), nil
      end

      it 'handles symbols' do
        expect(subject.parser_opts_from_hash argument: :'=<path>').to contain_exactly %w(=<path>), nil
      end
    end

    context 'with description' do
      it 'returns description' do
        expect(subject.parser_opts_from_hash description: 'Be more verbose').to contain_exactly ['Be more verbose'], nil
      end

      it 'handles array of strings' do
        expect(subject.parser_opts_from_hash description: %w(Be more verbose)).to contain_exactly ['Be more verbose'], nil
      end
    end

    context 'with handler or block' do
      it 'returns handler' do
        handler = -> {}

        expect(subject.parser_opts_from_hash &handler).to contain_exactly [], handler
        expect(subject.parser_opts_from_hash handler: handler).to contain_exactly [], handler
        expect(subject.parser_opts_from_hash handler: -> {}, &handler).to contain_exactly [], handler
      end
    end
  end

  describe '.parser_opts_from_string' do
    context 'with no arguments' do
      it 'returns nothing' do
        expect(subject.parser_opts_from_string).to contain_exactly [], nil
        expect(subject.parser_opts_from_string '').to contain_exactly [], nil
      end
    end

    context 'with shorts and longs' do
      it 'returns shorts and longs' do
        expect(subject.parser_opts_from_string '-v').to contain_exactly %w(-v), nil
        expect(subject.parser_opts_from_string '-v -s').to contain_exactly %w(-v -s), nil

        expect(subject.parser_opts_from_string '--verbose').to contain_exactly %w(--verbose), nil
        expect(subject.parser_opts_from_string '--verbose --silent').to contain_exactly %w(--verbose --silent), nil

        expect(subject.parser_opts_from_string '-v --verbose').to contain_exactly %w(-v --verbose), nil
        expect(subject.parser_opts_from_string '-q -s --quiet --silent').to contain_exactly %w(-q -s --quiet --silent), nil
        expect(subject.parser_opts_from_string '-q -s --[no-]quiet --[no-]silent').to contain_exactly %w(-q -s --[no-]quiet --[no-]silent), nil
      end

      context 'with argument' do
        it 'returns shorts, longs, style, and argument' do
          expect(subject.parser_opts_from_string '-f =<path>').to contain_exactly [:REQUIRED, '-f', '=<path>'], nil
          expect(subject.parser_opts_from_string '-f --file =<path>').to contain_exactly [:REQUIRED, '-f', '--file', '=<path>'], nil
          expect(subject.parser_opts_from_string '-f -p --file --path =<path>').to contain_exactly [:REQUIRED, '-f', '-p', '--file', '--path', '=<path>'], nil

          expect(subject.parser_opts_from_string '-f [=<path>]').to contain_exactly [:OPTIONAL, '-f', '=[<path>]'], nil
          expect(subject.parser_opts_from_string '-f --file [=<path>]').to contain_exactly [:OPTIONAL, '-f', '--file', '=[<path>]'], nil
          expect(subject.parser_opts_from_string '-f -p --file --path [=<path>]').to contain_exactly [:OPTIONAL, '-f', '-p', '--file', '--path', '=[<path>]'], nil

          expect(subject.parser_opts_from_string '-f --file=<path>').to contain_exactly [:REQUIRED, '-f', '--file', '=<path>'], nil
          expect(subject.parser_opts_from_string '-f -p --file --path=<path>').to contain_exactly [:REQUIRED, '-f', '-p', '--file', '--path', '=<path>'], nil

          expect(subject.parser_opts_from_string '-f --file[=<path>]').to contain_exactly [:OPTIONAL, '-f', '--file', '=[<path>]'], nil
          expect(subject.parser_opts_from_string '-f -p --file --path[=<path>]').to contain_exactly [:OPTIONAL, '-f', '-p', '--file', '--path', '=[<path>]'], nil
        end

        context 'with description' do
          it 'returns shorts, longs, style, argument, and description' do
            expect(subject.parser_opts_from_string '-f =<path> Path to file.').to contain_exactly [:REQUIRED, '-f', '=<path>', 'Path to file.'], nil
            expect(subject.parser_opts_from_string '-f --file =<path> Path to file.').to contain_exactly [:REQUIRED, '-f', '--file', '=<path>', 'Path to file.'], nil
            expect(subject.parser_opts_from_string '-f -p --file --path =<path> Path to file.').to contain_exactly [:REQUIRED, '-f', '-p', '--file', '--path', '=<path>', 'Path to file.'], nil

            expect(subject.parser_opts_from_string '-f [=<path>] Path to file.').to contain_exactly [:OPTIONAL, '-f', '=[<path>]', 'Path to file.'], nil
            expect(subject.parser_opts_from_string '-f --file [=<path>] Path to file.').to contain_exactly [:OPTIONAL, '-f', '--file', '=[<path>]', 'Path to file.'], nil
            expect(subject.parser_opts_from_string '-f -p --file --path [=<path>] Path to file.').to contain_exactly [:OPTIONAL, '-f', '-p', '--file', '--path', '=[<path>]', 'Path to file.'], nil

            expect(subject.parser_opts_from_string '-f --file=<path> Path to file.').to contain_exactly [:REQUIRED, '-f', '--file', '=<path>', 'Path to file.'], nil
            expect(subject.parser_opts_from_string '-f -p --file --path=<path> Path to file.').to contain_exactly [:REQUIRED, '-f', '-p', '--file', '--path', '=<path>', 'Path to file.'], nil

            expect(subject.parser_opts_from_string '-f --file[=<path>] Path to file.').to contain_exactly [:OPTIONAL, '-f', '--file', '=[<path>]', 'Path to file.'], nil
            expect(subject.parser_opts_from_string '-f -p --file --path[=<path>] Path to file.').to contain_exactly [:OPTIONAL, '-f', '-p', '--file', '--path', '=[<path>]', 'Path to file.'], nil
          end
        end
      end

      context 'with description' do
        it 'returns shorts, longs, and description' do
          expect(subject.parser_opts_from_string '-v Be more verbose').to contain_exactly ['-v', 'Be more verbose'], nil
          expect(subject.parser_opts_from_string '--verbose Be more verbose').to contain_exactly ['--verbose', 'Be more verbose'], nil
        end
      end
    end

    context 'with argument' do
      context 'with type' do
        it 'returns argument and type' do
          expect(subject.parser_opts_from_string '=<value:Numeric>').to contain_exactly [:REQUIRED, Numeric, '=<value>'], nil
          expect(subject.parser_opts_from_string '[=<value:Numeric>]').to contain_exactly [:OPTIONAL, Numeric, '=[<value>]'], nil
        end
      end

      context 'with values' do
        it 'returns argument and values' do
          expect(subject.parser_opts_from_string '=(on|off)').to contain_exactly [:REQUIRED, %w(on off), '=(on|off)'], nil
          expect(subject.parser_opts_from_string '[=(on|off)]').to contain_exactly [:OPTIONAL, %w(on off), '=[(on|off)]'], nil
        end
      end

      context 'with regexp' do
        it 'returns argument and regexp' do
          expect(subject.parser_opts_from_string '=<indent:\d+>').to contain_exactly [:REQUIRED, /\d+/, '=<indent>'], nil
          expect(subject.parser_opts_from_string '[=<indent:\d+>]').to contain_exactly [:OPTIONAL, /\d+/, '=[<indent>]'], nil
        end
      end
    end

    context 'with description' do
      it 'returns description' do
        expect(subject.parser_opts_from_string 'Be more verbose').to contain_exactly ['Be more verbose'], nil
      end
    end

    context 'with handler or block' do
      it 'returns handler' do
        handler = -> {}

        expect(subject.parser_opts_from_string &handler).to contain_exactly [], handler
      end
    end
  end
end
