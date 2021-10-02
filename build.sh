#!/bin/bash
#shopt -s nullglob dotglob

source "./cleanup.sh"
source "./cats.sh"
source "./nav.sh"
bundle exec jekyll build
cd build
git add -A && git add -u
git push origin master
