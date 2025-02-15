- run `code ~/.zshrc`

```
code ~/.zshrc
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
zstyle ':vcs_info:*' formats "Branch: %b"
precmd () { vcs_info }

get_git_repo_url() {
  local repo_url=$(git remote get-url origin 2>/dev/null | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//')
  if [[ -n "$repo_url" ]]; then
    echo "Repo: $repo_url"
  else
    echo "Repo: Not Found"
  fi
}

get_git_pr_url() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    local pr_url=$(gh pr list --json url,headRefName -q '.[] | select(.headRefName=="'"$branch"'") | .url' 2>/dev/null)
    if [[ -n "$pr_url" ]]; then
      echo "PR: $pr_url"
    else
      echo "PR: Not Created"
    fi
  fi
}

pull-request() {
  gh pr create -a kupuma-ru21 -t "$*" -b "" --draft
}

PROMPT='%F{red}Dir: %~
%f%F{cyan}$vcs_info_msg_0_%f
%F{blue}$(get_git_repo_url)%f
%F{green}$(get_git_pr_url)%f
%F{yellow}$%f '
```
