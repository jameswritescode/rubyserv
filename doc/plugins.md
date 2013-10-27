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

* `prefix (default: true)`

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
  web :post, '/testing' do
    RubyServ::IRC::Client.find_by_nickname(@nickname).first.message('#channel', 'there was a POST to /testing!')
  end
  # ...
end
```

Be unique with your routes per service, or you'll be looking at clashes.
