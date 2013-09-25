class RubyServ::Event
  def initialize
    @events = []
  end

  def add(object, method, name)
    @events << [object, method, name.downcase]
  end

  def delete(object, method, name)
    @events.delete [object, method, name.downcase]
  end

  def unregister(object)
    @events.delete_if { |event| event[0] == object }
  end
end
