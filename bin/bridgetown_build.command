#!/bin/csh
cd $0:h
cd ../bridgetown
bin/bridgetown build -d=~/temp/bridgetown
open ~/temp/bridgetown/index.html
