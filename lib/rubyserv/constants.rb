module RubyServ
  VERSION  = File.read(RubyServ.root.join('VERSION')).strip
  REVISION = `git log --pretty=format:'%h' -n 1`
end
