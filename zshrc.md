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
      sleep 10
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
  echo "=== Fetching local branches ==="
  current_branch=$(git branch --show-current)
  local_branches=($(git branch | sed 's/*//' | awk '{print $1}'))
  echo "Current branch: $current_branch"
  echo "Local branches: ${local_branches[*]}"

  echo "=== Fetching merged PRs ==="
  merged_prs=$(gh pr list --state merged --limit 1 --json headRefName,mergeCommit)

  echo "🔍 Raw PR data from GitHub:"
  echo "$merged_prs"

  merged_branches=()
  while IFS=$'\t' read -r branch_name merge_commit; do
    merged_branches+=("$branch_name $merge_commit")
  done < <(echo "$merged_prs" | jq -r '.[] | select(.mergeCommit != null) | "\(.headRefName)\t\(.mergeCommit.oid)"')

  echo "Merged PRs (branch name & merge commit):"
  if [[ ${#merged_branches[@]} -eq 0 ]]; then
    echo "⚠️ No valid merged PRs found. Exiting."
    return
  fi

  for branch_info in "${merged_branches[@]}"; do
    echo "  $branch_info"
  done

  echo "=== Checking branches for deletion ==="
  for branch_info in "${merged_branches[@]}"; do
    branch_name=$(echo "$branch_info" | awk '{print $1}')
    merge_commit=$(echo "$branch_info" | awk '{print $2}')

    if [[ -z "$merge_commit" || "$merge_commit" == "null" ]]; then
      echo "  ⚠️ Skipping branch: $branch_name (No merge commit found)"
      continue
    fi

    if [[ " ${local_branches[@]} " =~ " ${branch_name} " ]]; then
      echo "  Checking branch: $branch_name"

      # ローカルブランチの最初のコミットを取得
      local_first_commit=$(git rev-list --reverse "$branch_name" | head -n 1)

      # スカッシュマージ後の最も古い親コミットを取得
      pr_first_commit=$(git rev-list "$merge_commit" | tail -n 1 2>/dev/null)

      if [[ -z "$pr_first_commit" ]]; then
        echo "    ⚠️ Unable to find PR first commit for $branch_name"
        continue
      fi

      echo "    PR First Commit:   $pr_first_commit"
      echo "    Local First Commit: $local_first_commit"

      # 🔹 【新規追加】マージコミットの親コミットを取得
      merge_commit_parents=$(git rev-list --parents -n 1 "$merge_commit" | cut -d' ' -f2-)
      echo "    Merge Commit Parents: $merge_commit_parents"

      # 🔹 【新規追加】ローカルブランチの最初のコミットが `mergeCommit` の親に含まれているか確認
      if [[ ! " $merge_commit_parents " =~ " $local_first_commit " ]]; then
        echo "    ⚠️ Not deleting: $branch_name is a new branch (different history)"
        continue
      fi

      # コミットハッシュが一致する場合、削除
      if [[ "$pr_first_commit" == "$local_first_commit" && "$branch_name" != "$current_branch" ]]; then
        echo "    ✅ Deleting branch: $branch_name"
        git branch -D "$branch_name"
      else
        echo "    ❌ Not deleting: Commit hash mismatch or is current branch"
      fi
    else
      echo "  ⚠️ Skipping branch: $branch_name (Not found locally)"
    fi
  done

  echo "=== Finished ==="
}


pull-request() {
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
        echo -n "Continue? (y/N): "
        read confirm
        if [ "$confirm" != "y" ]; then
            g ch "$default_branch" && g cb "$1"
            return 1
        fi
    fi

    git pull --rebase >/dev/null 2>&1 || true

    output=$(git switch -c "$1" 2>&1)
    first_fatal=$(echo "$output" | grep -i "fatal:" | head -n 1)

    if [[ -n "$first_fatal" ]]; then
        print_error "$first_fatal"
    fi
}

git() {
  case "$1" in
    ch|revert)
      handle_git_command "true" "$@"
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
        output=$(command git "$@" --no-edit 2>&1)  # `--no-edit` を適用
    else
        output=$(command git "$@" 2>&1)  # `--no-edit` なし
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

get_commit_hashes() {
  local branches=($(git branch --format='%(refname:short)'))
  local commit_hashes=()

  for branch in $branches; do
    local commit_hash=$(git rev-parse $branch)
    commit_hashes+=($commit_hash)
  done

  echo "${commit_hashes[@]}"
}

get_first_commit_of_latest_merged_pr() {
  gh pr list --state merged --limit 10 --json number --jq '.[].number' | while read PR_NUMBER; do
    gh pr view "$PR_NUMBER" --json commits --jq '.commits[0].oid'
  done
}

compare_commit_hashes() {
  commit_hashes=($(get_commit_hashes))
  pr_commit_hashes=($(get_first_commit_of_latest_merged_pr))
  for pr_commit in "${pr_commit_hashes[@]}"; do
  for commit in "${commit_hashes[@]}"; do
  if [[ "$pr_commit" == "$commit" ]]; then
  git branch -d $(git branch --contains "$commit")
  fi
  done
  done
}
```

