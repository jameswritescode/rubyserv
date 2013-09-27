module RubyServ::IRC::Helper
  # Gives find_by_* functionality
  def method_missing(method, *args, &block)
    if method.to_s.start_with?('find_by_')
      collection = self.class.instance_variable_get("@#{self.class.to_s.downcase}s")
      collection.select { |item| item.send(method.to_s.sub('find_by_')) == arg[0] }
    else
      super
    end
  end
end
