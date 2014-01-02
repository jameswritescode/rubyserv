module RubyServ::Database
  extend self

  def use(database)
    @path = find_or_create_database(database)

    self
  end

  def read
    JSON.parse(File.read(@path))
  end

  def destroy
    FileUtils.rm @path
  end

  private

  def find_or_create_database(database)
    path = RubyServ.root.join('data', "#{database}.json")

    File.open(path, 'w') { |file| file.write('{}') } unless File.exist?(path)

    path
  end
end
