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

## `match(/pattern/, options = {}, &block)`

**Parameters:**

* `/pattern/ (Regexp) (Required)`
* `options   (Hash)   (Optional)`
* `&block    (????)   (Required)`

**Supported `options`:**

* `skip_prefix    (default: false)`
* `skip_callbacks (default: false)`

**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  # ...
  match(/some (\S+)/) do |m, param|
    m.reply "some #{param} called by #{m.user.nickname}"
  end
  # ...
end
```

When greating groups when in the pattern (in this case, `(\S+)`) match will take a param for each group. So:

`match(/some (\S+) (\S+)/)` would yield you: `|m, first, second|`

## `event(event, options = {}, &block)`

**Parameters:**

* `event`   (Symbol) (Required)`
* `options` (Hash)   (Optional)`
* `&block   (????)   (Required)`

**Supported `options`:**

* `skip_callbacks (default: false)`

**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  # ...
  event :privmsg do |m|
    m.reply "#{m.user.nickname} someone said something!"
  end
  # ...
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

  # ...
  web :post, '/testing/:name' do |m, name|
    m.client.message('#channel', "name: #{name}")
  end
  # ...
end
```

`web` can take one parameter similar to `event` and `match` that returns a `RubyServ::Message` object, but is currently only useful for `m.client`.

Additional parameters work like Sinatra's typical `get '/:param' do |param|` as shown in the example.

Be unique with your routes per service, or you'll be looking at clashes.

## `before(method, options = {})`

`before` acts like `before_action` in rails. The the method specified after before is executed before events and matches.

**Parameters:**

* `method  (Symbol) (Required)`
* `options (Hash)   (Optional)`

**Supported `options`:**

* `skip (Array or String) (Optional)`

`skip` can take these values: `matchers`, `events`

It can be an array or string, however specifying both types will pretty much make the `before` useless anyway.

**Example:**

```ruby
module SomeServ
  include RubyServ::Plugin

  before :init
  before :init, skip: :events
  before :init, skip: [:events, :matchers]

  match(/.../) do |m|
    # ...
  end

  def init
    # ...
  end
end
```

Be warned that right now any instance variables defined in `before` will then exist for all other matchers and events, regardless if the before is set to ignore one or the other.
