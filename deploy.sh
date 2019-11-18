#!/usr/bin/env sh

# Abort script when an error occurs
set -e

# build
npm run build

# change to directory dist
cd dist

git init
git add -A
git commit -m 'deploy V-4.0'

# deploy to https://<USERNAME>.github.io/<REPO>
git push -f git@github.com:remy1604/altenlab.git master:gh-pages