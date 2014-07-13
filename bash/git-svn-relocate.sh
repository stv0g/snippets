#!/bin/sh
 
# Must be called with two command-line args.
# Example: git-svn-relocate.sh http://old.server https://new.server
if [ $# -ne 2 ]
then
  echo "Please invoke this script with two command-line arguments (old and new SVN URLs)."
  exit $E_NO_ARGS
fi 

# Prepare URLs for regex search and replace.
oldUrl=`echo $1 | awk '{gsub("[\\\.]", "\\\\\\\&");print}'`
newUrl=`echo $2 | awk '{gsub("[\\\&]", "\\\\\\\&");print}'`

filter="sed \"s|^git-svn-id: $oldUrl|git-svn-id: $newUrl|g\""
git filter-branch --msg-filter "$filter" -- --all

sed -i.backup -e "s|$oldUrl|$newUrl|g" .git/config

rm -rf .git/svn
git svn rebase
