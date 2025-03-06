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
zstyle ':vcs_info:git:*' stagedstr " [staged]"
zstyle ':vcs_info:git:*' unstagedstr " [changed]"
zstyle ':vcs_info:*' formats "%F{cyan}Branch: %b%f%F{208}%u%f%F{magenta}%c%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
zstyle ':vcs_info:*' nvcsformats "%F{cyan}Not a Git Repo%f"
precmd () { vcs_info }

PROMPT='%F{cyan}$vcs_info_msg_0_%f
%F{red}Dir:%~%f
%F{yellow}$%f '

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

get_git_pr_url() {
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  local pr_url=$(gh pr list --json url,headRefName -q '.[] | select(.headRefName=="'"$branch"'") | .url' 2>/dev/null)
  echo "$pr_url"
}

meta() {
  local repo_url=$(get_git_repo_url)
  local my_prs_url=$(get_git_my_prs_url)
  local pr_url=$(get_git_pr_url)

  local BLUE="\033[0;34m"
  local MAGENTA="\033[0;35m"
  local GREEN="\033[0;32m"

  echo -e "${BLUE}Repo: ${repo_url:-Not Found}"
  echo -e "${MAGENTA}MyPRs: ${my_prs_url:-Not Found}"
  echo -e "${GREEN}PR: ${pr_url:-Not Found}"
}

pull-request() {
  g sh
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  gh pr create -a kupuma-ru21 -t "$branch" -b ""
  gh pr merge $(get_git_pr_url)
  gh issue close ${branch##*-}
  g ch main
  g db ${local branch}
}

```
