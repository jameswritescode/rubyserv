class Sinatra::Base
  def self.compile!(verb, path, block, options = {})
    options.each_pair { |option, args| send(option, *args) }
    method_name             = "#{verb} #{path}"
    unbound_method          = generate_method(method_name, &block)
    pattern, keys           = compile path
    conditions, @conditions = @conditions, []

    generate_methods_from(@plugin)

    wrapper                 = block.arity != 0 ?
      proc { |a,p| p.unshift(RubyServ::Message.new(nil, service: @service)); unbound_method.bind(a).call(*p) } :
      proc { |a,p| unbound_method.bind(a).call }
    wrapper.instance_variable_set(:@route_name, method_name)

    [ pattern, keys, conditions, wrapper ]
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

  def self.service(value)
    @service = value
  end

  def self.plugin(value)
    @plugin = value
  end

  def self.inject_plugin_routes(plugin)
    plugin.web_routes.each do |type, route, block, service|
      self.send(type.to_sym, route, { plugin: plugin, service: service.nickname }, &block)
    end
  end

  def self.clear_plugin_routes(plugin)
    plugin.web_routes.each do |web_route|
      types = [web_route.first.to_s.upcase]
      types << 'HEAD' if web_route.first == :get

      types.each do |type|
        self.routes[type].delete_if do |sinatra_route|
          self.send(:compile, web_route[1]).first == sinatra_route.first
        end
      end
    end
  end
end
