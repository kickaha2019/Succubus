#!/bin/csh
cd $0:h
ruby ../ruby/analyser.rb /Users/peter/Succubus/bga /Users/peter/Caches/Succubus ~/temp/Succubus
open ~/temp/Succubus/index.html
