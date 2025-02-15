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
    cb = !git checkout -b
    db = !sh -c 'git branch -D $1 && git push origin --delete $1 --no-verify' -
    lr = !sh -c 'git checkout . && git clean -f' -
    rb = !git branch -m
    rmc = !git reset --hard HEAD~1
    create-pr = !gh pr create -a kupuma-ru21
```
