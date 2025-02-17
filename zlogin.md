- Setup `alias show-pull-requests`

<!-- https://github.com/tecfu/tty-table -->

```
npm install tty-table -g
mkdir -p ~/.config/tty-table
code ~/.config/tty-table/github-pr.json
```

- Update github-pr.json

```
[
  { "align": "left", "alias": "title", "width": 50 },
  { "align": "left", "alias": "branch", "color": "cyan", "width": 40 },
  { "align": "left", "alias": "url", "color": "green", "width": 60 }
]


```

- Run `code ~/.zshrc`

```
code ~/.zshrc
```

```
alias g='git'
alias c='clear && printf "\e[3J"'
alias e='code .'
alias show-pull-requests='gh pr list --json "title,headRefName,url" --author "kupuma-ru21" \
  | jq -r "[.[] | { title: .title, branch: .headRefName, url: .url }]" \
  | tty-table --format json --header $HOME/.config/tty-table/github-pr.json'


# refer to terminal setting
# https://bottoms-programming.com/archives/termina-git-branch-name-zsh.html#toc1
setopt prompt_subst

get_git_repo_url() {
  local repo_url=$(git remote get-url origin 2>/dev/null | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//')
  echo "$repo_url"
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
%F{green}PR: $(get_git_pr_url | sed -e "s/^$/Not Found/")%f
%F{red}Dir: %~
%F{yellow}$%f '

create-pull-request() {
  gh pr create -a kupuma-ru21 -t "$*" -b "" --draft
}

```
