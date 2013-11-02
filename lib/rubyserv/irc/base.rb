class RubyServ::IRC::Base
  class << self
    def all
      collection_variable
    end

    def first
      collection_variable.first
    end

    def last
      collection_variable.last
    end

    def create(options = {})
      collection_variable << self.new(options)
    end

    # Gives find_by_* functionality
    def method_missing(method, *args, &block)
      if method.to_s.start_with?('find_by_')
        collection = collection_variable.select { |item| item.send(method.to_s.sub('find_by_', '')) == args[0] }

        collection.count > 1 ? collection : collection.first
      else
        super
      end
    end

    private

    def collection_variable
      self.instance_variable_get("@#{self.to_s.sub('RubyServ::IRC::', '').downcase}s")
    end
  end

  def update(options = {})
    options.each do |key, value|
      method("#{key}=").call(value)
    end
  end

  def destroy
    self.class.send(:collection_variable).delete(self)
  end
end
