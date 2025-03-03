- https://qiita.com/non0311/items/28a32d6318d8c85b688c

#### run `git config --global core.editor code && git config --global -e`

```
git config --global core.editor code && git config --global -e
```

```
[user]
	name = kupuma-ru21
	email = tech.kupumaru@gmail.com
[core]
	editor = code
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
    wipe = !sh -c 'git restore . && git clean -fd' -
    rb = !git branch -m
    rmc = !git reset --hard HEAD~1
    # Delete unnecessary local branches
    get-default-branch = "!sh -c 'git symbolic-ref refs/remotes/origin/HEAD | sed \"s@^refs/remotes/origin/@@\"' -"
    db = "!default_branch=$(git get-default-branch); protected_branches=$(git branch --format \"%(refname:short)\" --no-merged origin/$default_branch | tr \"\\n\" \"|\"); protected_branches=${protected_branches%|}; if [[ -z \"$protected_branches\" ]]; then git branch | grep -v \"^\\*\" | xargs git branch -D; else git branch | grep -vE \"(^\\*|$default_branch|$protected_branches)\" | xargs git branch -D; fi"
    # db = !sh -c 'git branch -D $1 && git push origin --delete $1 --no-verify' -
```
