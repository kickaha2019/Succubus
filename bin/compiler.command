#!/bin/csh
cd $0:h
cd ..
time ruby ruby/compiler.rb ./bga /Users/peter/Caches/Succubus
if ($status != 0) exit 1

cd ~/Temp
rm -r Hugo_public
mkdir Hugo_public

cd ~/Temp/Hugo
hugo --quiet 
if ($status != 0) exit 1
ruby ~/Succubus/ruby/relativize.rb ~/Temp/Hugo_public
if ($status != 0) exit 1
ruby ~/Succubus/ruby/to_check.rb ~/Succubus/bga ~/Temp/Hugo_public /tmp/to_check.html
if ($status != 0) exit 1
open /tmp/to_check.html
