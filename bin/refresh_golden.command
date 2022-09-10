#!/bin/csh
cd $0:h
cd ..
ruby ruby/refresh_golden.rb ./bga/to_check.yaml  ./bga/golden_files
