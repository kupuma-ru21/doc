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
  update_vscode_excludes
  pkill -f show-git-progress
  while true; do
    c
    show-git-progress
    sleep 60
  done

  pkill -f delete-branches-merged

  (
    while true; do
      delete-branches-merged
      sleep 30
    done
  ) 1>/dev/null 2>&1 &

  pkill -f remove-vscode-caches

  (
    while true; do
      remove-vscode-caches
      sleep 600
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
  while read -r line; do
    branch_name=$(echo "$line" | cut -d':' -f1)
    commit_hash=$(echo "$line" | cut -d':' -f2)
    echo "🔍 Searching PRs for branch: $branch_name, hash: $commit_hash"
    pr_result=$(gh pr list --search "$commit_hash" --head "$branch_name" --state merged)
    if [[ -n "$pr_result" ]]; then
      echo "✅ PR found for branch: $branch_name. Deleting branch..."
      git branch -D "$branch_name" && echo "🗑 Deleted local branch: $branch_name"
      git push origin --delete "$branch_name" && echo "🗑 Deleted remote branch: $branch_name"
    else
      echo "❌ No merged PR found for branch: $branch_name. Skipping deletion."
    fi
  done < <(get_hashes_by_last_commits_from_local_branches)
}

get_hashes_by_last_commits_from_local_branches() {
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
  branch_hashes=()
  while read -r branch; do
    commit_hash=$(git log -n 1 --pretty=format:"%H" "$branch")
    branch_hashes+=("$branch:$commit_hash")  # "ブランチ名:ハッシュ" の形式で追加
  done < <(git branch --format='%(refname:short)' | grep -v "^${default_branch}$")

  for entry in "${branch_hashes[@]}"; do
    echo "$entry"
  done
}

remove-vscode-caches() {
  rm -rf ~/Library/Application\ Support/Code/Cache
  rm -rf ~/Library/Application\ Support/Code/CachedData
  rm -rf ~/Library/Application\ Support/Code/User/workspaceStorage
}

update_vscode_excludes() {
  local settings_path="$HOME/Library/Application Support/Code/User/settings.json"
  local gitignore_patterns

  gitignore_patterns=$(find . -type f -name ".gitignore" -exec cat {} + | \
    sed -E '/^#/d; /^\s*$/d; s#\*\*/##g; s#/$##' | sort -u | sed 's#^/##' | grep -vE '^\.env$')

  local excludes_json="{ \"**/.git\": true, \"**/.DS_Store\": true, \"**/generated\": true"
  local watcher_excludes_json="{ \"**/.git\": true, \"**/generated\": true"
  local search_excludes_json="{ \"**/.git\": true, \"**/.DS_Store\": true, \"**/generated\": true"

  while read -r pattern; do
    [[ -n "$pattern" ]] || continue
    excludes_json+=", \"**/$pattern\": true"
    watcher_excludes_json+=", \"**/$pattern\": true"
    search_excludes_json+=", \"**/$pattern\": true"
  done <<< "$gitignore_patterns"

  excludes_json+=" }"
  watcher_excludes_json+=" }"
  search_excludes_json+=" }"

  if [[ -n "$gitignore_patterns" ]]; then
    jq '."files.exclude" = $excludes | ."files.watcherExclude" = $watcher_excludes | ."search.exclude" = $search_excludes' \
      --argjson excludes "$excludes_json" \
      --argjson watcher_excludes "$watcher_excludes_json" \
      --argjson search_excludes "$search_excludes_json" \
      "$settings_path" > temp.json && mv temp.json "$settings_path"
  fi
}

pull-request() {
  g sh
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  gh pr create --assignee @me --web
  g ch main
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
    git pull --rebase --no-autostash origin $(g get-current-branch)
  else
    git pull --rebase --no-autostash origin "$1"
  fi
}


git() {
  case "$1" in
    ch|revert)
      output="$(handle_git_command "true" "$@" 2>&1)"
      ret=$?
      if echo "$output" | grep -q "fatal: invalid upstream"; then
        return $ret
      elif echo "$output" | grep -q "fatal: couldn't find remote ref"; then
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
