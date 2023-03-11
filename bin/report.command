#!/bin/csh
cd $0:h
ruby ../ruby/reporter.rb /Users/peter/Succubus/alofmethbin.rb /Users/peter/Caches/Succubus/alofmethbin
if ($status != 0) then
  open /Users/peter/Caches/Succubus/alofmethbin/index1.html
  exit 1
endif
