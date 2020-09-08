# EXPERIMENTAL mono repository for the OSCAR project

## Goals

The purpose of this mono repository is ... TODO


## How this repository was made

Using `git-subtree`, see <https://manpages.debian.org/testing/git-man/git-subtree.1.en.html>
or <https://www.atlassian.com/git/tutorials/git-subtree>

However, this should not matter to us at all, unless we decide to maintain some repository
both as part of the monorepo and as a standalone repo.



## How to install `git-subtree`

To experiment with this repo, you don't need `git-subtree`, but you might want to install
it for further experiments...

While the `git-subtree` command is bundled with `git` as part of its `contrib`
directory, unfortunately many git distributions do not install it. But it's rather
easy to install it manually:

1. download <https://raw.githubusercontent.com/git/git/master/contrib/subtree/git-subtree.sh>
2. make it executable: `chmod a+x git-subtree.sh`
2. rename it to `git-subtree` and copy it to a directory in your PATH, e.g. if you have `~/bin`
   in your PATH then you can do this:

        cp git-subtree.sh  ~/bin/git-subtree
