#!/bin/zsh

default_branch=$(git get-default-branch)
protected_branches=$(git get-pushed-branches-with-diff-remote | tr '\n' '|')
protected_branches=$(git branch --format \"%(refname:short)\" --no-merged origin/$default_branch | tr \"\\n\" \"|\")

echo "protected_branches: $protected_branches"


echo "protected_branches: $protected_branches"

protected_branches=${protected_branches%|}

if [[ -z "$protected_branches" ]]; then
  git branch | grep -v "^\*" | xargs git branch -D
else
  git branch | grep -vE "(^\*|$default_branch|$protected_branches)" | xargs git branch -D
fi
