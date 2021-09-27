#!/bin/bash
#shopt -s nullglob dotglob

source "./nav.sh"
bundle exec jekyll build
cd build
git add -A && git add -u
git push origin master
