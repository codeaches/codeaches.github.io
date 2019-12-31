#!/bin/sh

set -e

script/build

if test -e "./_site/index.html";then
  echo "Codeaches builds!"
  rm -Rf _site
else
  echo "Huh. That's odd. Codeaches site doesn't seem to build."
  exit 1
fi

gem build codeaches.gemspec
