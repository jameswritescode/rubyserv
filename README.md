## RubyServ

This is an IRC services implementation in ruby meant to make writing services and plugins easy alongside your usual IRC services.

This is also written to be TS6 compatible, specifically to work with [Charybdis](http://www.atheme.org/project/charybdis).

### Configuration

Configuring is meant to be straight-forward. It connects to an IRC server with the usual link configuration, then it connects
RubyServ.

**Proposed configuration for services**

Directory structure:

```text
plugins/
    someserv.rb
    otherserv.rb
    someserv/
        command.rb
        othercommand.rb
```

Each plugin will have a top-level file that "configures" the service itself. Then there will be directories named after each service that a file can be created for each command.

I'm thinking command creation will be heavily based off of [cinch's plugin system](https://github.com/cinchrb/cinch/tree/master/examples/plugins), making files look similar to this:

```ruby
class Command
	match /^some pattern$/ # match(pattern, *args)
    
    help "does something" # similar to rake's `desc` method
    
    # *args for match could include `method:` which can 
    # define which method to use if not execute
    def execute(input)
   	    # do something
    end
end
```

In the core of RubyServ, when services are loaded and created, they will read the plugins/*.rb files, then read the plugins/service_name/*.rb files to add the commands.

### Acknowledgements

This was inspired by [somasonic's RServ](https://github.com/somasonic/RServ) and [dominikh's cinch](https://github.com/cinchrb/cinch)
