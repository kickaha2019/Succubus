#!/bin/csh
cd $0:h
cd ..
time ruby ruby/compiler.rb ./bga /Users/peter/Caches/Succubus ~/Temp/Hugo
if ($status != 0) exit 1
cd ~/Temp/Hugo_public
find . -name '*.html' -exec rm {} \;
cd ~/Temp/Hugo
hugo --quiet 
if ($status != 0) exit 1
ruby ~/Succubus/ruby/to_check.rb ~/Succubus/bga/to_check.yaml ~/Succubus/bga/golden_files ~/Temp/Hugo/content/generated.csv /tmp/to_check.html
if ($status != 0) exit 1
ruby ~/Succubus/ruby/relativize.rb ~/Temp/Hugo_public
if ($status != 0) exit 1
open /tmp/to_check.html
