class Sinatra::Base
  def self.compile!(verb, path, block, options = {})
    options.each_pair { |option, args| send(option, *args) }
    method_name             = "#{verb} #{path}"
    unbound_method          = generate_method(method_name, &block)
    pattern, keys           = compile path
    conditions, @conditions = @conditions, []

    wrapper                 = block.arity != 0 ?
      proc { |a,p| p.unshift(RubyServ::Message.new(nil, service: @service)); unbound_method.bind(a).call(*p) } :
      proc { |a,p| unbound_method.bind(a).call }
    wrapper.instance_variable_set(:@route_name, method_name)

    [ pattern, keys, conditions, wrapper ]
  end

  def self.service(value)
    @service = value
  end
end
