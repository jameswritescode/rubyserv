## RubyServ

This is an IRC services implementation in ruby meant to make writing services and plugins easy alongside your usual IRC services.

This is also written to be TS6 compatible, specifically to work with [Charybdis](http://www.atheme.org/project/charybdis). I've tried to code it so it'll be easy to drop in new protocols, but it still may need some refactoring yet to achieve that. If you would like to use a non-TS6 IRCd please consider contributing a protocol class!

All that said, this is not meant to be a replacement for traditional services like [Atheme](https://github.com/atheme/atheme).

And **this is in development, it's not perfect**. If you find a problem, please create an issue, or open a pull request. Thanks!

### Configuration

Very simple configuration! Copy `etc/rubyserv.yml.example` to `etc/rubyserv.yml` and edit the values.

### Plugins (sevices)

See our [plugins](https://github.com/jameswritescode/rubyserv/tree/master/doc/plugins.md) document and our [RubyServ plugins](https://github.com/jameswritescode/rubyserv-plugins) repository.

## Contributing

If you want to contribute a plugin to this project, check out our [RubyServ plugins](https://github.com/jameswritescode/rubyserv-plugins) repository.

If you want to contribute to the core of RubyServ, please feel free to open a pull request!

## Acknowledgements

This was inspired by @somasonic's [RServ](https://github.com/somasonic/RServ) and @dominikh's [cinch](https://github.com/cinchrb/cinch)
