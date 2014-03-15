class Sinatra::Base
  def self.compile!(verb, path, block, options = {})
    options.each_pair { |option, args| send(option, *args) }
    method_name             = "#{verb} #{path}"
    unbound_method          = generate_method(method_name, &block)
    pattern, keys           = compile path
    conditions, @conditions = @conditions, []

    generate_methods_from(options[:plugin])

    wrapper                 = block.arity != 0 ?
      proc { |a,p| p.unshift(rubyserv_message_object(options)); unbound_method.bind(a).call(*p) } :
      proc { |a,p| unbound_method.bind(a).call }
    wrapper.instance_variable_set(:@route_name, method_name)

    [ pattern, keys, conditions, wrapper ]
  end

  def self.rubyserv_message_object(options = {})
    RubyServ::Message.new(nil, service: options[:plugin].nickname)
  end

  def self.generate_methods_from(plugin)
    plugin.instance_methods.each do |method|
      define_method method do |*args|
        plugin.method(method).call(*args)
      end unless self.methods.include?(method.to_sym)
    end
  end

  def self.destroy_methods_from(plugin)
    plugin.instance_methods.each do |method|
      remove_method method.to_sym
    end
  end

  def self.plugin(*)
  end

  def self.inject_plugin_routes(plugin)
    RubyServ::Matcher.(plugin, :routes).each do |type, route, block|
      self.send(type.to_sym, route, { plugin: plugin }, &block)
    end
  end

  def self.clear_plugin_routes(plugin)
    RubyServ::Matcher.(plugin, :routes).each do |request_type, route|
      types = [request_type.to_s.upcase]
      types << 'HEAD' if request_type == :get

      types.each do |type|
        self.routes[type].delete_if do |sinatra_route|
          self.send(:compile, route).first == sinatra_route.first
        end
      end
    end
  end
end
