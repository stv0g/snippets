#!/bin/bash
# git-svn-switch
# by Justen Hyde based on this blog post:
#
# http://translate.org.za/blogs/wynand/en/content/changing-your-svn-repository-address-git-svn-setup
#
# Use at your own risk. For the love of cthulhu, back
# your repo up before letting this loose on it.
 
if [ $# -ne 1 ]; then
	echo "Usage: `basename $0` {new subversion url}"
	exit -1
fi
 
if [[ $1 = "--help" || $1 = "-h" ]]; then
	echo
	echo "Usage: `basename $0` {new subversion url}"
	echo
	echo " Changes the url of the subversion repository a git-svn repo is connected to."
	echo " Analogous to svn switch. Potentially a weapon of mass destruction. Use with care."
	echo " Run this from within your git repo. You only need one argument: the new url of the svn repo."
	echo " git-svn-switch will attempt to verify that the url is at least a svn repo before starting the switch"
	echo " but don't depend on it to stop you from doing summat daft."
	echo
	exit 1
fi
 
# get the current subversion url
SRC=`git svn info --url`
if [ -n "$SRC" ]; then
	FROM=`echo $SRC | sed "s|/trunk||"`
	REPO=`svn info $1`
	echo "Checking $REPO is actually a subversion repository..."
	if [ -n "$REPO" ]; then
		echo "The new URL looks valid."
		echo "Rewriting the git history with the new url..."
		SED_FILTER="sed 's;git-svn-id: "$FROM";git-svn-id: "$1";g'"
		git gc
		git filter-branch --msg-filter "$SED_FILTER" $(cat .git/packed-refs | awk '// {print $2}' | grep -v 'pack-refs')
#Couple of pointless checkouts - on some repos the log changes seem to need flushing by an operation like this
		git checkout trunk
		git checkout master
		echo "Rebuild git-svn internals and updating the repo"
		rm -rf .git/svn
		sed -i~ 's|'$FROM'|'$1'|g' .git/config
		git svn rebase
	else
		echo "Error: $1 Does not appear to be a subversion repository."
	fi
else
	echo "Error: This doesn't appear to be a git working directory, or it's a git repo that hasn't been created using a git-svn bridge"
fi
