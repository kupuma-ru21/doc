#### custom bash or zash

- `code ~/.bash_profile` or `code ~/.zlogin`

write below
<br />
alias g='git'
<br />
alias c='clear'

---

#### git alias

- git config --global --edit
- git config --global core.editor code
- git config --global -e

[alias]
<br />
ll = !git pull
<br />
sh = "!git push --set-upstream origin \"$(git rev-parse --abbrev-ref HEAD)\""
<br />
ch = !sh -c 'git stash && git checkout $1 $2 && git pull' -
<br />
re = !git reset --hard
<br />
t = !git tag
<br />
c = !git add --all && git commit -m
<br />
rc = !git reset --soft HEAD^
<br />
rs = !git stash pop
<br />
st = !git stash
<br />
m = !git merge
<br />
cb = !git checkout -b
<br />
db = !git branch -d
<br />
lr = !git checkout .
