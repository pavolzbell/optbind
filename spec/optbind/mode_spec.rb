require 'spec_helper'

require 'optbind/mode'

describe OptBind do
  let(:options) { OptBind.new }

  it 'responds to parse variants' do
    expect(options).to respond_to :order
    expect(options).to respond_to :order!

    expect(options).to respond_to :permute
    expect(options).to respond_to :permute!
  end
end

describe OptBind::Arguable do
  let(:options) { ARGV }

  it 'responds to parse variants' do
    expect(options).to respond_to :order
    expect(options).to respond_to :order!

    expect(options).to respond_to :permute
    expect(options).to respond_to :permute!
  end
end
