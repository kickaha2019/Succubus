#!/bin/csh
cd $0:h
time ruby ../ruby/analyser.rb /Users/peter/Succubus/bga /Users/peter/Caches/Succubus ~/temp/Succubus
if ($status != 0) exit 1
open ~/temp/Succubus/index.html
