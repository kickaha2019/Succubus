#!/bin/csh
cd $0:h
cd ..
ruby ruby/compiler.rb ./bga /Users/peter/Caches/Succubus ~/temp/Hugo
if ($status != 0) exit 1
cd ~/temp/Hugo
find public -name '*.html' -exec rm {} \;
hugo
if ($status != 0) exit 1
open ~/temp/Hugo_public/index.html
