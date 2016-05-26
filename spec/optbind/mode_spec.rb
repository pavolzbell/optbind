require 'spec_helper'

require 'optbind/mode'

# TODO test unique behavior of each mode

describe OptBind do
  let(:options) do
    OptBind.new target: {} do |o|
      o.opt 'o --output=<file>'
    end
  end

  let(:argv) { %w(--output=file master) }

  it 'responds to order' do
    expect(options).to respond_to :order
    expect(options).to respond_to :order!
  end

  it 'responds to permute' do
    expect(options).to respond_to :permute
    expect(options).to respond_to :permute!
  end

  it 'responds to parse' do
    expect(options).to respond_to :parse
    expect(options).to respond_to :parse!
  end

  describe '#order' do
    it 'parses' do
      orig = argv.dup
      expect(options.order argv).to contain_exactly('master')
      expect(options.target).to eq(o: 'file')
      expect(argv).to eq orig
    end
  end

  describe '#order!' do
    it 'parses' do
      expect(options.order! argv).to contain_exactly('master')
      expect(options.target).to eq(o: 'file')
      expect(argv).to contain_exactly('master')
    end
  end

  describe '#permute' do
    it 'parses' do
      orig = argv.dup
      expect(options.permute argv).to contain_exactly('master')
      expect(options.target).to eq(o: 'file')
      expect(argv).to eq orig
    end
  end

  describe '#permute!' do
    it 'parses' do
      expect(options.permute! argv).to contain_exactly('master')
      expect(options.target).to eq(o: 'file')
      expect(argv).to contain_exactly('master')
    end
  end

  describe '#parse' do
    it 'parses' do
      orig = argv.dup
      expect(options.parse argv).to contain_exactly('master')
      expect(options.target).to eq(o: 'file')
      expect(argv).to eq orig
    end
  end

  describe '#parse!' do
    it 'parses' do
      expect(options.parse! argv).to contain_exactly('master')
      expect(options.target).to eq(o: 'file')
      expect(argv).to contain_exactly('master')
    end
  end
end

describe OptBind::Arguable do
  let(:argv) do
    argv = %w(--output=file master)
    argv.extend OptBind::Arguable
    argv.bind(to: {}) { opt 'o --output=<file>' }
    argv
  end

  it 'responds to order' do
    expect(argv).to respond_to :order
    expect(argv).to respond_to :order!
  end

  it 'responds to permute' do
    expect(argv).to respond_to :permute
    expect(argv).to respond_to :permute!
  end

  it 'responds to parse' do
    expect(argv).to respond_to :parse
    expect(argv).to respond_to :parse!
  end

  describe '#order' do
    it 'parses' do
      orig = argv.dup
      expect(argv.order).to contain_exactly('master')
      expect(argv.target).to eq(o: 'file')
      expect(argv).to eq orig
    end
  end

  describe '#order!' do
    it 'parses' do
      expect(argv.order!).to contain_exactly('master')
      expect(argv.target).to eq(o: 'file')
      expect(argv).to contain_exactly('master')
    end
  end

  describe '#permute' do
    it 'parses' do
      orig = argv.dup
      expect(argv.permute).to contain_exactly('master')
      expect(argv.target).to eq(o: 'file')
      expect(argv).to eq orig
    end
  end

  describe '#permute!' do
    it 'parses' do
      expect(argv.permute!).to contain_exactly('master')
      expect(argv.target).to eq(o: 'file')
      expect(argv).to contain_exactly('master')
    end
  end

  describe '#parse' do
    it 'parses' do
      orig = argv.dup
      expect(argv.parse).to contain_exactly('master')
      expect(argv.target).to eq(o: 'file')
      expect(argv).to eq orig
    end
  end

  describe '#parse!' do
    it 'parses' do
      expect(argv.parse!).to contain_exactly('master')
      expect(argv.target).to eq(o: 'file')
      expect(argv).to contain_exactly('master')
    end
  end
end
