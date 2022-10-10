#!/bin/csh
rm -r /tmp/Succubus
cd $0:h

time ruby ../ruby/analyser.rb /Users/peter/Succubus/bga /Users/peter/Caches/Succubus
if ($status != 0) exit 1

#time ruby ../ruby/dumper.rb /Users/peter/Succubus/bga /Users/peter/Caches/Succubus ~/temp/Succubus 0 1
#if ($status != 0) exit 1

open /tmp/Succubus/index.html
