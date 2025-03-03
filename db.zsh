#!/bin/zsh

default_branch=$(git get-default-branch)
protected_branches=$(git get-pushed-branches-with-diff-remote | tr '\n' '|')
protected_branches=${protected_branches%|}

git for-each-ref --format="%(refname:short)" refs/heads | while read branch; do
  if ! git ls-remote --heads origin "$branch" | grep -q "$branch"; then
    echo "$branch"
  fi
done


if [[ -z "$protected_branches" ]]; then
  git branch | grep -v "^\*" | xargs git branch -D
else
  git branch | grep -vE "(^\*|$default_branch|$protected_branches)" | xargs git branch -D
fi
