module RubyServ
  def self.root
    Pathname.new(File.dirname(__FILE__) + '/../..').expand_path
  end
end
