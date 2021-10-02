#!/bin/bash
#shopt -s nullglob dotglob

source "./cleanup.sh"
source "./cats.sh"
source "./nav.sh"
bundle exec jekyll serve
