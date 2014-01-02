class RubyServ::Database
  def initialize(path)
    @path     = path
    @database = JSON.parse(File.read(@path), symbolize_names: true)
  end

  def destroy
    FileUtils.rm @path
  end

  def [](key)
    @database[key.to_sym]
  end

  def []=(key, value)
    @database[key.to_sym] = value
  end

  def save
    File.open(@path, 'w') { |file| file.write(@database.to_json) }
  end

  class << self
    def use(database)
      self.new(find_or_create_database(database))
    end

    private

    def find_or_create_database(database)
      path = RubyServ.root.join('data', "#{database}.json")

      File.open(path, 'w') { |file| file.write('{}') } unless File.exist?(path)

      path
    end
  end
end
