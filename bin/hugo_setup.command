#!/bin/csh
cd ~/temp
chmod -R 777 Hugo
rm -r Hugo
hugo new site Hugo
cd Hugo
git init
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke

