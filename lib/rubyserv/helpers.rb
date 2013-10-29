module RubyServ
  extend self

  def root
    Pathname.new(File.dirname(__FILE__) + '/../..').expand_path
  end

  def format_number(number)
    number < 1000 ? number : number.to_s.to_str.split('.')[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  end
end
