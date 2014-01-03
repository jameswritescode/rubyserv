require 'spec_helper'

describe RubyServ::Database do
  include FakeFS::SpecHelpers

  before { FileUtils.mkdir_p('data') }

  context '::use' do
    it "creates a database if one doesn't exist" do
      path = RubyServ.root.join('data', 'test.json')

      expect(File.exist?(path)).to be_false

      RubyServ::Database.use('test')

      expect(File.exist?(path)).to be_true
    end

    it 'does not create a database if one exists' do
      FileUtils.touch('data/test.json')

      File.open('data/test.json', 'w') { |file| file.write('{}') }
      File.should_not_receive(:open)

      RubyServ::Database.use('test')
    end

    it 'creates an empty json hash when new database is created' do
      RubyServ::Database.use('test')

      expect(File.read('data/test.json')).to eql '{}'
    end
  end

  it 'converts string keys to symbols' do
    db       = RubyServ::Database.use('test')
    db.users = [{ 'name' => 'james' }, { 'name' => 'robert', 'extra' => { 'colors' => { 'favorite' => 'blue' } } }]

    expect(db.users.first.include?(:name)).to be_true
    expect(db.users.last.include?(:extra)).to be_true
    expect(db.users.last[:extra].include?(:colors)).to be_true
    expect(db.users.last[:extra][:colors].include?(:favorite)).to be_true
  end

  it 'sets and gets a value' do
    db        = RubyServ::Database.use('test')
    db.name   = 'james'
    db.people = 'james', 'robert'

    expect(db.name).to eql 'james'
    expect(db.people).to eql ['james', 'robert']
  end

  it 'saves set json' do
    db      = RubyServ::Database.use('test')
    db.name = 'james'
    db.save

    expect(File.read('data/test.json')).to eql '{"name":"james"}'
  end
end
