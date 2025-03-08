- https://qiita.com/non0311/items/28a32d6318d8c85b688c

#### run `git config --global core.editor code && git config --global -e`

```
git config --global core.editor code && git config --global -e
```

```
[alias]
    # NOTE: "1>/dev/null 2>&1" is used to suppress the output of the command
    get-current-branch = !git rev-parse --abbrev-ref HEAD
    ll = !git pull
    sh = "!git push --set-upstream origin \"$(git get-current-branch)\""
    ch = !sh -c '(git switch $1 || (git fetch origin $1 1>/dev/null 2>&1 && git switch $1)) && git ll 1>/dev/null 2>&1' -
    a = !git add --all
    c = !sh -c 'git a && git commit -m \"$*\"' -
    cf = !sh -c 'git a && git commit -m \"chore: wip\"' -
    rc = !git reset --soft HEAD^
    rs = !git stash pop
    st = !git stash --include-untracked
    cb = !sh -c '(git fetch origin \"$(git get-current-branch)\" 1>/dev/null 2>&1 || git switch -c $1) && git ll 1>/dev/null 2>&1 && git switch -c $1' -
    db = !sh -c 'git branch -D $1 && git push origin --delete $1 --no-verify 1>/dev/null 2>&1' -
    wipe = !sh -c 'git restore . && git clean -fd' -
    rb = !git branch -m
    rmc = !git reset --hard HEAD~1
    # https://snyk.io/blog/10-git-aliases-for-faster-and-productive-git-workflow/
    b = branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate
```
