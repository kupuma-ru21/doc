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

YELLOW="%F{yellow}"
ORANGE="%F{214}"
CYAN="%F{cyan}"
MAGENTA="%F{magenta}"
RESET="%f"

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr " [staged]"
zstyle ':vcs_info:git:*' unstagedstr " [changed]"
zstyle ':vcs_info:*' formats "${YELLOW}Branch: %b${RESET}%F{208}%u${RESET}${MAGENTA}%c${RESET}"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
zstyle ':vcs_info:*' nvcsformats "${YELLOW}Not a Git Repo${RESET}"
precmd () { vcs_info }

PROMPT='%F${YELLOW}$vcs_info_msg_0_%f
%F${CYAN}Dir: %~%f
%F${ORANGE}$%f '

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
  PR_URLS_WITH_CONFLICT=$(gh pr list --author @me --base main --state open --json url,mergeable -q '.[] | select(.mergeable=="CONFLICTING") | .url')
  local SEPARATOR="-----"
  if [ -n "$PR_URLS_WITH_CONFLICT" ]; then
  local RED="\033[1;31m"
  echo "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥"
  echo -e "${RED}⚠️  Conflicting PRs found:"
  echo -e "${RED}${SEPARATOR}"
  echo "$PR_URLS_WITH_CONFLICT" | awk -v sep="$SEPARATOR" '{print "👉 " $0 "\n" sep}'
  echo "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥"
  else
  local repo_url=$(get_git_repo_url)
  local my_prs_url=$(get_git_my_prs_url)
  local pr_url=$(get_git_pr_url)

  local BLUE="\033[0;34m"
  local MAGENTA="\033[0;35m"
  local GREEN="\033[0;32m"

  echo -e "${BLUE}${SEPARATOR}"
  echo -e "${BLUE}Repo: ${repo_url:-Not Found}"
  echo -e "${BLUE}${SEPARATOR}"

  echo -e "${MAGENTA}${SEPARATOR}"
  echo -e "${MAGENTA}MyPRs: ${my_prs_url:-Not Found}"
  echo -e "${MAGENTA}${SEPARATOR}"

  echo -e "${GREEN}${SEPARATOR}"
  echo -e "${GREEN}PR: ${pr_url:-Not Found}"
  echo -e "${GREEN}${SEPARATOR}"
  fi
}

pull-request() {
  g sh
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  gh pr create -a @me -t "$branch" -b ""
  gh pr merge $(get_git_pr_url) --squash
  gh issue close ${branch##*-}
  g ch main
}

delete-branches-merged-squash() {
  main_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
  while true; do
    deleted=false
    for branch in $(git branch --format='%(refname:short)' | grep -v "^$main_branch$"); do
      if git cherry -v "$main_branch" "$branch" | grep -qE "^- [0-9a-f]"; then
        g db "$branch"
        deleted=true
      fi
    done
    if [ "$deleted" = false ]; then
      break
    fi
  done
}
```
