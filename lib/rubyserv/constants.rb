module RubyServ
  VERSION  = File.read(RubyServ.root.join('VERSION')).strip
  REVISION = `git log --pretty=format:'%h' -n 1`
  PLUGINS  = []

  OWNER  = { symbol: '~', name: 'owner' }
  ADMIN  = { symbol: '&', name: 'admin' }
  OP     = { symbol: '@', name: 'op' }
  HALFOP = { symbol: '%', name: 'halfop' }
  VOICE  = { symbol: '+', name: 'voice' }
end
