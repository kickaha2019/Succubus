#!/bin/csh
cd $0:h
cd ../hugo
sleep 10;open http://localhost:1313/experiment &
hugo server -D
