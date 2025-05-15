# Troubleshooting

## Flux: "Source artifact not found"

In first check flux ressources `k get gitrepositories -A` and `k get helmrepositories -A`\
If you have an error like "branch 'X' not found" it's certainly because you are in local branch or because the branch was been deleted from remote repository.
