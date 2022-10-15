#!/bin/csh
ruby ~/Succubus/ruby/to_check.rb ~/Succubus/bga  ~/Temp/Hugo_public /tmp/to_check.html
if ($status != 0) exit 1
open /tmp/to_check.html
