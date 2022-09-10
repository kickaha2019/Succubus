#!/bin/csh
cd $0:h
cd ..
time ruby ruby/compiler.rb ./bga /Users/peter/Caches/Succubus ~/temp/Hugo
if ($status != 0) exit 1
cd ~/temp/Hugo_public
find . -name '*.html' -exec rm {} \;
cd ~/temp/Hugo
hugo
if ($status != 0) exit 1
ruby ~/Succubus/ruby/to_check.rb ~/Succubus/bga/to_check.yaml ~/Succubus/bga/golden_files /tmp/to_check.html
if ($status != 0) exit 1
ruby ~/Succubus/ruby/relativize.rb ~/temp/Hugo_public
if ($status != 0) exit 1
open /tmp/to_check.html
