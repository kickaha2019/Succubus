#!/bin/csh
cd $0:h
cd ..
ruby ruby/compiler.rb ./bga /Users/peter/Caches/Succubus Hugo
if ($status != 0) exit 1
cd Hugo
find public -name '*.html' -exec rm {} \;
hugo
if ($status != 0) exit 1
open Hugo/public/index.html
