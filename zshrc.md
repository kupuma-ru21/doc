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
%F${CYAN}Path: %F${CYAN}$(echo "$PWD" | sed -E "s|^$VSCODE_WORKSPACE|root|")%f
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
  pkill -f show-git-progress
  while true; do
    c
    show-git-progress
    sleep 60
  done &

  pkill -f delete-branches-merged

  (
    while true; do
      delete-branches-merged
      sleep 20
    done
  ) 1>/dev/null 2>&1 &
}

show-git-progress() {
  git fetch origin "$(get_default_branch)" 1>/dev/null 2>&1

  PR_URLS_WITH_CONFLICT=$(gh pr list --author @me --base main --state open --json url,mergeable,createdAt \
  -q 'sort_by(.createdAt) | .[] | select(.mergeable=="CONFLICTING") | .url')

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

delete-branches-merged() {
  local_commit_hashes=$(get_hashes_by_first_commits_from_local_branches | sort | tr -d '\r')
  pr_commit_hashes=$(get_hashes_by_first_commits_from_pr_branches | sort | tr -d '\r')
  common_hashes=$(comm -12 <(printf '%s\n' "$local_commit_hashes") <(printf '%s\n' "$pr_commit_hashes"))
  while read -r commit_hash; do
    [[ -z "$commit_hash" ]] && continue
    git branch --contains "$commit_hash" | tr -d '\r' | while read -r branch; do
      [[ -z "$branch" ]] && continue
      git delete-branch-both-local-remote "$branch"
    done
  done <<< "$common_hashes"
}

get_hashes_by_first_commits_from_local_branches() {
  git for-each-ref --format='%(objectname)' refs/heads/
}

get_hashes_by_first_commits_from_pr_branches() {
  gh pr list --state merged --limit 50 --json number --jq '.[].number' | xargs -n1 -I{} gh pr view {} --json commits --jq '.commits[0].oid' | sort
}

pull-request() {
  g sh
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  gh pr create --assignee @me --draft --template $(get-pull-request-template-file) --web
  g ch main
}

get-pull-request-template-file() {
  # REF: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates#pull-request-templates
  # > You can store your pull request template in the repository's visible root directory, the docs folder, or the hidden .github directory.
  ROOT_DIR=$(git rev-parse --show-toplevel)
  TARGET_DIRS=(
    "$ROOT_DIR/.github"
    "$ROOT_DIR"
    "$ROOT_DIR/docs"
  )
  for DIR in "${TARGET_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
      FILE_PATH=$(find "$DIR" -maxdepth 1 -iname "pull_request_template.md" 2>/dev/null)
      if [ -n "$FILE_PATH" ]; then
        FILENAME=$(basename "$FILE_PATH")
        echo "$FILENAME"
        return 0
      fi
    fi
  done
  return 1
}


pull-request-force() {
  g sh
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  gh pr create -a @me -t "$branch" -b ""
  gh pr merge $(get_git_pr_url) --squash
  gh issue close ${branch##*-}
  g ch main
}

create-new-branch() {
    default_branch=$(get_default_branch)
    current_branch=$(g get-current-branch)
    if [ "$current_branch" != "$default_branch" ]; then
        print_warning "Sure? Making a new branch from branch: ($current_branch)"
        while true; do
            echo -n "Continue? (y/N): "
            old_stty_cfg=$(stty -g)
            stty -icanon -echo
            confirm=$(dd bs=1 count=1 2>/dev/null | tr '[:upper:]' '[:lower:]')
            stty "$old_stty_cfg"
            echo "$confirm"
            if [[ "$confirm" == "y" ]]; then
                break
            elif [[ "$confirm" == "n" ]]; then
                g ch "$default_branch" && g cb "$1"
                return 1
            else
                print_warning "Invalid input. Please press 'y' or 'n'."
            fi
        done
    fi
    git ll >/dev/null 2>&1 || true
    output=$(git switch -c "$1" 2>&1)
    first_fatal=$(echo "$output" | grep -i "fatal:" | head -n 1)
    if [[ -n "$first_fatal" ]]; then
        print_error "$first_fatal"
    fi
}

git-pull() {
  if [[ -z "$1" ]]; then
    git pull origin $(g get-current-branch)
  else
    git rebase --no-autostash --no-ff origin/"$1"
  fi
}


git() {
  case "$1" in
    ch|revert)
      output="$(handle_git_command "true" "$@" 2>&1)"
      ret=$?
      if echo "$output" | grep -q "fatal: invalid upstream"; then
        return $ret
      else
        echo "$output"
        return $ret
      fi
      ;;
    sh)
      handle_git_command "false" "$@"
      ;;
    db)
      command git "$@" 1>/dev/null 2>&1
      ;;
    *)
      command git "$@"
      ;;
  esac
}

handle_git_command() {
    local no_edit_flag="$1"
    shift
    if [[ "$no_edit_flag" == "true" ]]; then
        output=$(command git "$@" --no-edit 2>&1)
    else
        output=$(command git "$@" 2>&1)
    fi
    if echo "$output" | grep -i -q -E "fatal:|error:"; then
        print_error "$output"
    fi
}

print_error() {
    local message="$1"
    echo -e "\033[1;97;41m[ ERROR ] $message\033[0m"
}

print_warning() {
    local message="$1"
    echo -e "\033[1;97;103m[ WARNING ] $message \033[0m"
}

get_default_branch() {
  git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@"
}
```
