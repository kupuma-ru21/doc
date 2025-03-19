- https://qiita.com/non0311/items/28a32d6318d8c85b688c

#### run `git config --global core.editor code && git config --global -e`

```
git config --global core.editor code && git config --global -e
```

```
[alias]
    get-current-branch = !git rev-parse --abbrev-ref HEAD
	ll = !zsh -i -c \"git-pull \\\"$1\\\"\"
    fix-conflict = !git add . && GIT_EDITOR=true git rebase --continue
    sh = "!git push -u --force-with-lease origin \"$(git get-current-branch)\""
    ch = !sh -c '(git switch $1 || (git fetch origin $1 && git switch $1)) && git ll' -
    a = !git add --all
    c = !sh -c 'git a && git commit -m \"$*\"' -
    cf = !sh -c 'git a && git commit -m \"chore: wip\"' -
    rc = !git reset --soft HEAD^
    rs = !git stash pop
    st = !git stash --include-untracked
	cb = !zsh -i -c \"create-new-branch \\\"$1\\\"\"
    delete-branch-both-local-remote = !sh -c '(git branch -D $1 || git push origin --delete $1 --no-verify) && git push origin --delete $1 --no-verify' -
    db = !sh -c 'git ch main && git delete-branch-both-local-remote $1' -
    wipe = !sh -c 'git restore . && git clean -fd' -
    rb = !git branch -m
    rmc = !git reset --hard HEAD~1
    # https://snyk.io/blog/10-git-aliases-for-faster-and-productive-git-workflow/
    b = branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset): %(color:red)(%(committerdate:relative)) %(color:green)[%(authorname)]' --sort=-committerdate
	pr = !zsh -i -c \"pull-request\"
    df=!git diff --name-only --staged
```
