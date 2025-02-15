- run `code ~/.zlogin`

```
code ~/.zlogin
```

```
alias g='git'
alias c='clear && printf "\e[3J"'
alias e='code .'

# refer to terminal setting
# https://bottoms-programming.com/archives/termina-git-branch-name-zsh.html#toc1
autoload -Uz vcs_info
setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:*' formats "branch: %b"
precmd () { vcs_info }

PROMPT='%F{red}dir: %~
%f%F{cyan}$vcs_info_msg_0_%f%F{yellow}
$%f '
```
