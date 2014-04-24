## RubyServ

[![Code Climate](https://codeclimate.com/github/jameswritescode/rubyserv.png)](https://codeclimate.com/github/jameswritescode/rubyserv) [![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/jameswritescode/rubyserv/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

This is an IRC services implementation in ruby meant to make writing services and plugins easy alongside your usual IRC services.

This is also written to be TS6 compatible, specifically to work with [Charybdis](http://www.atheme.org/project/charybdis). I've tried to code it so it'll be easy to drop in new protocols, but it still may need some refactoring yet to achieve that. If you would like to use a non-TS6 IRCd please consider contributing a protocol class!

All that said, this is not meant to be a replacement for traditional services like [Atheme](https://github.com/atheme/atheme).

And **this is in development, it's not perfect**. If you find a problem, please create an issue, or open a pull request. Thanks!

If you have any questions or problems feel free to open an issue or find newton on [irc.freenode.net](http://freenode.net) in #rubyserv. A little planning and task keeping is done on [Trello](https://trello.com/b/2sqGDjIT).

### Configuration

Very simple configuration! Copy `rubyserv.yml.example` to `rubyserv.yml` and edit the values.

### Plugins (sevices)

See our [plugins](https://github.com/jameswritescode/rubyserv/tree/master/doc/plugins.md) document and our [RubyServ plugins](https://github.com/jameswritescode/rubyserv-plugins) repository.

## Contributing

If you want to contribute a plugin to this project, check out our [RubyServ plugins](https://github.com/jameswritescode/rubyserv-plugins) repository.

If you want to contribute to the core of RubyServ, please feel free to open a pull request!

## Acknowledgements

This was inspired by [RServ](https://github.com/somasonic/RServ) and [cinch](https://github.com/cinchrb/cinch)
