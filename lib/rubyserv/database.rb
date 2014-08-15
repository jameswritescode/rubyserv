class RubyServ::Database
  def self.exist?(name)
    File.exist?(RubyServ.root.join('data', name))
  end

  def self.open(name)
    new(name)
  end

  def initialize(name)
    @db = SQLite3::Database.new RubyServ.root.join('data', name).to_s
  end

  def execute(sql)
    @db.execute(sql)
  end

  def create_table(name, columns = {})
    @db.execute <<-SQL
      create table #{name} (
        #{convert_columns(columns)}
      );
    SQL
  end

  private

  def convert_columns(columns)
    columns.map do |name, type|
      "#{name} #{get_type(type.to_s)}"
    end.join(',')
  end

  def get_type(type)
    case type
    when 'String'  then 'varchar(256)'
    when 'Integer' then 'int'
    end
  end
end
