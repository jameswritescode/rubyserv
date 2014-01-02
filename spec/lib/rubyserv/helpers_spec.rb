require 'spec_helper'

describe RubyServ do
  it 'root path is the same as the base of the directory' do
    expect(RubyServ.root).to eql Pathname.new(File.dirname(__FILE__) + '/../../..').expand_path
  end

  it 'formats number correctly' do
    expect(described_class.format_number(1000)).to eql '1,000'
    expect(described_class.format_number(10000)).to eql '10,000'
  end
end
