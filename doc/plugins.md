# Plugins

Plugins are centric to the RubyServ ecosystem because it is what handles how your services will function.

Plugins go into the `plugins` directory, and the best example of one of the plugins is `RubyServ` itself, found in `plugins/core.rb`.

The only thing **required** in a plugin are `include RubyServ::Plugin` and `configure`. The `module` name doesn't matter, but stay out of the `RubyServ` namespace to avoid namespace clashes.

## `configure(&block)`

`configure` is a very important method that is used to configure what the bots nickname, hostname, realname, etc, are.

**Parameters:**

* `nickname (String) (Required)`
* `hostname (String) (Optional)`
* `username (String) (Optional)`
* `realname (String) (Optional)`
* `channels (Array)  (Optional)`
* `prefix   (String) (Optional)`

**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  configure do |config|
    config.nickname = 'SomeServ'
    config.hostname = 'someserv.does.something'
    # ...
  end
end
```

## `match(/pattern/, options)`

**Parameters:**

* `/pattern/ (Regexp) (Required)`
* `options   (Hash)   (Required)`

**Supported `options`:**

* `method`        (Required)
* `skip_prefix    (default: false)`
* `skip_callbacks (default: false)`

**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  match(/some (\S+)/, method: :some)

  def some(m, param)
    m.reply "some #{param} called by #{m.user.nickname}"
  end
end
```

When greating groups when in the pattern (in this case, `(\S+)`) match will take a param for each group. So:

`match(/some (\S+) (\S+)/, method: :some)` would yield you: `def some(m, first, second)`

## `event(event, options)`

**Parameters:**

* `event`   (Symbol) (Required)`
* `options` (Hash)   (Optional)`

**Supported `options`:**

* `skip_callbacks (default: false)`

**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  event(:privmsg, method: :notify)

  def notify(m)
    m.reply "#{m.user.nickname} said something!"
  end
end
```

## `web(request_type, route, &block)`

`web` definitions are translated to Sinatra routes, so if you are familiar with Sinatra some of it's magic is available to you.

**Parameters:**

* `request_type (Symbol) (Required)`
* `route`       (String) (Required)`
* `&block`      (????)   (Required)`

**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  web(:post, '/testing/:name') do |m, name|
    m.client.message('#channel', "name: #{name}")
  end
end
```

`web` can take one parameter similar to `event` and `match` that returns a `RubyServ::Message` object, but is currently only useful for `m.client`.

Additional parameters work like Sinatra's typical `get '/:param' do |param|` as shown in the example.

Be unique with your routes per service, or you'll be looking at clashes.

## `before(method, options || &block)`

`before` acts like `before_action` in rails. The the method specified after before is executed before events and matches.

**Parameters:**

The first parameter can be a method name, or a block. One or the other are
required. If a block is used, you cannot specify any options.

**Supported `options`:**

* `only   (Array or String) (Optional)`
* `except (Array or String) (Optional)`

`only` and `except` act like the rails versions, too.


**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  before :is_oper?, only: :quit

  def is_oper?(m)
    m.user.oper?
  end

  before do |m|
    m.user.admin?
  end
end
```

Be warned that right now any instance variables defined in `before` will then exist for all other matchers and events, regardless if the before is set to ignore one or the other.
