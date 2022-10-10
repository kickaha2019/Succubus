#!/bin/csh
rm -r /tmp/Succubus
cd $0:h
time ruby ../ruby/grabber.rb /Users/peter/Succubus/bga /Users/peter/Caches/Succubus 1
