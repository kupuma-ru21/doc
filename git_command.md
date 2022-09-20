#### rename git to g

- `code ~/.bash_profile` or `code ~/.zlogin`
- write `alias g='git'`

---

#### git alias

- git config --global --edit

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
