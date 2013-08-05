module RubyServ
  VERSION  = File.read(RubyServ.root.join('VERSION'))
  REVISION = `git log --pretty=format:'%h' -n 1`
end
