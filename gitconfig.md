- https://qiita.com/non0311/items/28a32d6318d8c85b688c

#### run `git config --global core.editor code && git config --global -e`

```
git config --global core.editor code && git config --global -e
```

```
[alias]
    get-current-branch = !git rev-parse --abbrev-ref HEAD
    ll = !git pull
    sh = "!git push --set-upstream origin \"$(git get-current-branch)\""
    shf = "!git push --set-upstream origin \"$(git get-current-branch)\" --no-verify"
    ch = !sh -c '(git checkout $1 || (git fetch origin $1 && git checkout $1)) && (git ll && git get-current-branch || git get-current-branch)' -
    a = !git add --all
    c = !sh -c 'git a && git commit -m \"$*\"' -
    cf = !sh -c 'git a && git commit --no-verify -m \"chore: wip\"' -
    rc = !git reset --soft HEAD^
    rs = !git stash pop
    st = !git stash --include-untracked
    cb = !sh -c 'git fetch origin \"$(git get-current-branch)\" && git pull && git checkout -b $1' -
    db = !sh -c 'git branch -D $1 && git push origin --delete $1 --no-verify' -
    wipe = !sh -c 'git restore . && git clean -fd' -
    rb = !git branch -m
    rmc = !git reset --hard HEAD~1
    # https://snyk.io/blog/10-git-aliases-for-faster-and-productive-git-workflow/
    b = branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate
```
