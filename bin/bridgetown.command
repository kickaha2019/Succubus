#!/bin/csh
cd $0:h
cd ../bridgetown
sleep 10;open http://localhost:4000 &
bin/bridgetown start
