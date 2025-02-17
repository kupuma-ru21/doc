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
setopt prompt_subst

get_git_repo_url() {
  local repo_url=$(git remote get-url origin 2>/dev/null | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//')
  echo "$repo_url"
}

get_git_my_prs_url() {
  local repo_url=$(get_git_repo_url)
  local username=$(gh api user --jq '.login' 2>/dev/null)
  if [[ -n "$repo_url" && -n "$username" ]]; then
    echo "$repo_url/pulls/$username"
  else
    echo ""
  fi
}

get_git_branch() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo "$branch"
}

get_git_pr_url() {
  local branch=$(get_git_branch)
  local pr_url=$(gh pr list --json url,headRefName -q '.[] | select(.headRefName=="'"$branch"'") | .url' 2>/dev/null)
  echo "$pr_url"
}

PROMPT='%F{cyan}Branch: $(get_git_branch | sed -e "s/^$/Not Found/")%f
%F{blue}Repo: $(get_git_repo_url | sed -e "s/^$/Not Found/")%f
%F{magenta}MyPRs: $(get_git_my_prs_url | sed -e "s/^$/Not Found/")%f
%F{green}PR: $(get_git_pr_url | sed -e "s/^$/Not Found/")%f
%F{red}Dir: %~
%F{yellow}$%f '

pull-request() {
  gh pr create -a kupuma-ru21 -t "$*" -b "" --draft
}

```
