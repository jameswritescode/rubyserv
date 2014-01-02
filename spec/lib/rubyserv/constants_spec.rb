require 'spec_helper'

describe RubyServ do
  it 'has a revision' do
    expect(RubyServ::REVISION).to eql `git log --pretty=format:'%h' -n 1`
  end

  it 'has a version' do
    expect(RubyServ::VERSION).to eql File.read(RubyServ.root.join('VERSION')).strip
  end
end
