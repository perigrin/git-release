git-release
-----------

`git-release` is a little porcelain for automating releases of a git
repository on a cluster of remote servers. 

This code is ALPHA CODE please use at YOUR OWN RISK.

The basic idea is make sure `git-release` is in your path. Then in a git enabled directory run:

    git config --add release.url ssh://user@example.org/myapp
    
then you can run

    `git release`
    
and `git-release` will update the current directory (via `git pull`), run
`prove -l t/` on your test directory and then ssh into example.org as user and
run `git pull` in the myapp directory.

