class RubyServ::Database
  def initialize(path)
    @path     = path
    @database = JSON.parse(File.read(@path), symbolize_names: true)
  end

  def save
    File.open(@path, 'w') { |file| file.write(@database.to_json) }

    self
  end

  def method_missing(name, *args, &block)
    if name =~ /\A.*=\z/
      args                           = convert_keys_to_symbols!(args)
      @database[name[0...-1].to_sym] = args.one? ? args.first : args
    else
      @database[name]
    end
  end

  private

  def convert_keys_to_symbols!(data)
    case data
    when Hash
      data.inject({}) do |symbolized_hash, (key, value)|
        symbolized_hash[key.to_sym] = convert_keys_to_symbols!(value)
        symbolized_hash
      end
    when Array then data.map { |object| convert_keys_to_symbols!(object) }
    else data
    end
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
