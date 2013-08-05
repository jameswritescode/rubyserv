module RubyServ
  VERSION  = File.read('../VERSION').strip
  REVISION = `git log --pretty=format:'%h' -n 1`
end
