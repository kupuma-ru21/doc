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
sh = !git push
<br />
ch = !git checkout && !git pull
<br />
re = !git reset --hard
<br />
t = !git tag
<br />
c = !git add --all && git commit -m
