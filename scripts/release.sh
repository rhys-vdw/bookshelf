#!/bin/bash -e

git checkout master

get_property() {
  echo $(node -p "p=require('./${1}').${2};")
}

delete_property() {
  echo "$(node -p "p=require('./${1}');delete p.${2};JSON.stringify(p, null, 2)")" > $1
  echo "deleted '${2}' from './${1}'"
}

set_property() {
  echo "$(node -p "p=require('./${1}');p.${2}=${3};JSON.stringify(p, null, 2)")" > $1
  echo "set '${2}' to '${3}' in './${1}'"
}

update_version() {
  echo "$(set_property ${1} 'version' "'${2}'")"
  echo "Updated ${1} version to ${2}"
}

# Remove the postinstall script, because we're going to build everything here.
current_version="$(get_property 'package.json' 'version')"

printf "Please ensure that the version number has been updated in bookshelf.js and src/bookshelf.js before continuing.\n"
printf "Next version (current is $current_version)? "
read next_version

if ! [[ $next_version =~ ^[0-9]\.[0-9]+\.[0-9](-.+)? ]]; then
  echo "Version must be a valid semver string, e.g. 1.0.2 or 2.3.0-beta.1"
  exit 1
fi

git add -u
npm run build
npm run jsdoc

# Remove the postinstall script because we'll be including the built files in
# this commit.
original_postinstall="$(get_property 'package.json' 'scripts.postinstall')"
delete_property 'package.json' 'scripts.postinstall'

# We must force add because these are usually ignored.
git add --force --all index.html docs build

# Update version in package.json before running tests (tests will catch if the
# version number is out of sync).
update_version 'package.json' $next_version

npm test

git commit -am "Release $next_version."
git tag $next_version

echo skipped: git push origin master
echo skipped: git push origin master --tags

echo "# Publishing docs"

git checkout gh-pages
git merge master
echo skipped: git push origin gh-pages
git checkout master

echo skipped: npm publish

# Now clean up those force added files, we'll have to add another commit.
echo $(git rm -r --cached .)
set_property 'package.json' 'scripts.postinstall' "'$original_postinstall'"
echo $(git add .)
echo $(git commit -m "Remove build, lib and docs after $next_version release.")

echo skipped: git push origin master
