require 'spec_helper'

describe RubyServ::Database do
  include FakeFS::SpecHelpers

  context '.use' do
    it "creates a database if one doesn't exist" do
      path = RubyServ.root.join('data', 'test.json')

      FileUtils.mkdir_p('data')

      expect(File.exist?(path)).to be_false

      RubyServ::Database.use('test')

      expect(File.exist?(path)).to be_true
    end

    it 'does not create a database if one exists' do
      FileUtils.mkdir_p('data')
      FileUtils.touch('data/test.json')

      File.should_not_receive(:open)

      RubyServ::Database.use('test')
    end
  end
end
