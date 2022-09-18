#### rename git to g

- code ~/.bash_profile
- input a and enter for edit
- write 「alias g='git'」

---

#### git alias

- git config --global --edit

[alias]
<br />
ll = !git pull
<br />
sh = "!git push --set-upstream origin \"$(git rev-parse --abbrev-ref HEAD)\""
<br />
ch = !sh -c 'git fetch $1 $2 && git checkout $2' -
<br />
re = !git reset --hard
<br />
t = !git tag
<br />
c = !git add --all && git commit -m
