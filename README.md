## RubyServ

This is an IRC services implementation in ruby meant to make writing services and plugins easy alongside your usual IRC services.

This is also written to be TS6 compatible, specifically to work with [Charybdis](http://www.atheme.org/project/charybdis).

### Configuration

Configuring is meant to be straight-forward. It connects to an IRC server with the usual link configuration, then it connects
RubyServ.

**Proposed configuration for services**

```ruby
class SomeServ
  configure do |config|
    config.nickname = 'SomeServ'
    # ...
  end

  command /pattern/, options do |input, group, ...|
    # do something
  end
end
```

### Acknowledgements

This was inspired by [somasonic's RServ](https://github.com/somasonic/RServ) and [dominikh's cinch](https://github.com/cinchrb/cinch)
