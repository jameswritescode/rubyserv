## RubyServ

This is an IRC services implementation in ruby meant to make writing services and plugins easy alongside your usual IRC services.

This is also written to be TS6 compatible, specifically to work with [Charybdis](http://www.atheme.org/project/charybdis).

### Configuration

Configuring is meant to be straight-forward. It connects to an IRC server with the usual link configuration, then it connects
RubyServ. If there are services in the plugins directory, then it will also include and connect those services.
