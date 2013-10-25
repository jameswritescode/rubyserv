## RubyServ

This is an IRC services implementation in ruby meant to make writing services and plugins easy alongside your usual IRC services.

This is also written to be TS6 compatible, specifically to work with [Charybdis](http://www.atheme.org/project/charybdis).

### Configuration

Very simple configuration! Copy `etc/rubyserv.yml.example` to `etc/rubyserv.yml` and edit the values.

### Plugins (sevices)

You can create plugins in `plugins`, and a good example of how to create a plugin is in the RubyServ plugin itself (`Core`).

**Examples:**

```ruby
module SomeServ
  configure do |config|
    config.nickname = 'SomeServ'
    config.hostname = 'someserv.rubyserv.int'
    # ...
  end

  match(/^hello (\S+)/) do |m, name|
    m.say("hello #{name}!")
  end
end
```

Each plugin must be a `module`, and require a `configure` block with at least the `nickname` of the service it'll be creating.

`match` blocks can be used to match `PRIVMSG` to the services themselves, or to channels they are in.

### Acknowledgements

This was inspired by @somasonic's [RServ](https://github.com/somasonic/RServ) and @dominikh's [cinch](https://github.com/cinchrb/cinch)
