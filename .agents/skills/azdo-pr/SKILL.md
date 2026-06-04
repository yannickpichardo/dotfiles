---
name: azdo-pr
description: Azure DevOps / AzDO / ADO pull request operations with az repos pr - create PR, view PR, list PRs, review, approve, vote, add reviewers, link work items, merge, update PR status, check PR details; if organization/project defaults are missing, route through azdo-context internally
---

# Azure DevOps Pull Requests (AzDO, ADO, az repos pr)

Manage Azure DevOps pull requests via `az repos pr` commands. All commands automatically filter to the current user where applicable. If organization/project context is missing, use the `azdo-context` skill first.

## List My PRs

**Active PRs I created:**
```bash
az repos pr list --creator "$(az account show --query user.name -o tsv)" --status active -o table
```

**All my PRs (any status):**
```bash
az repos pr list --creator "$(az account show --query user.name -o tsv)" --status all -o table
```

**PRs assigned to me for review:**
```bash
az repos pr list --reviewer "$(az account show --query user.name -o tsv)" --status active -o table
```

**Find PR for current git branch:**
```bash
az repos pr list --source-branch "$(git rev-parse --abbrev-ref HEAD)" --status active -o table
```

## View PR Details

**Show specific PR (table format):**
```bash
az repos pr show --id <PR_ID> -o table
```

**Show PR with full JSON details:**
```bash
az repos pr show --id <PR_ID>
```

**Open PR in browser:**
```bash
az repos pr show --id <PR_ID> --open
```

## Create PR

**IMPORTANT: PR Description Template**

Before creating a PR, **always check if a `pull_request_template.md` file exists** in the repository (typically in `.github/`, `.azuredevops/`, `docs/`, or repo root). If it exists:
1. Read the template file
2. Use its structure and required sections for the `--description` parameter
3. Fill in all required sections (e.g., Summary, Changes, Test Plan, Breaking Changes, etc.)

Common template locations to check:
- `.github/pull_request_template.md`
- `.azuredevops/pull_request_template.md`
- `docs/pull_request_template.md`
- `pull_request_template.md` (repo root)

**Create PR from current branch:**
```bash
az repos pr create --title "Your PR Title" --description "PR description" --draft false
```

**Create PR with reviewers and work items:**
```bash
az repos pr create \
  --title "Your PR Title" \
  --description "PR description" \
  --optional-reviewers "<reviewer-email>" "<reviewer-email>" \
  --work-items 12345 67890 \
  --draft false
```

**Create draft PR:**
```bash
az repos pr create --title "WIP: Your PR Title" --description "Work in progress" --draft true
```

**Create PR and open in browser:**
```bash
az repos pr create --title "Your PR Title" --description "PR description" --open
```

**Create PR with auto-complete and delete source branch:**
```bash
az repos pr create \
  --title "Your PR Title" \
  --description "PR description" \
  --auto-complete true \
  --delete-source-branch true
```

### Post-Creation: Automatic Work Item Linking

After creating a PR, the skill automatically checks if work item linking is required and links one if necessary:

1. **Check if work item linking is a required policy:**
   ```bash
   REPO_ID=$(az repos show --query id -o tsv)
   az repos policy list --branch main --repository-id $REPO_ID \
     --query "[?type.displayName=='Work item linking'].{isBlocking:isBlocking, isEnabled:isEnabled}" -o table
   ```

2. **IF AND ONLY IF** `isBlocking: true`:
   - Invoke `azdo-tickets` skill to list current sprint work items
   - Find the most relevant work item based on PR title/description
   - If no specific match, use the ad-hoc work item
   - Link the work item to the PR:
     ```bash
     az repos pr work-item add --id <PR_ID> --work-items <WORK_ITEM_ID>
     ```

This ensures PRs always meet branch policy requirements without manual intervention.

## Update PR

**Update PR title:**
```bash
az repos pr update --id <PR_ID> --title "New Title"
```

**Update PR description:**
```bash
az repos pr update --id <PR_ID> --description "Updated description"
```

**Convert to/from draft:**
```bash
# Publish (from draft to ready)
az repos pr update --id <PR_ID> --draft false

# Convert to draft
az repos pr update --id <PR_ID> --draft true
```

**Set auto-complete:**
```bash
# Try standard auto-complete first
az repos pr update --id <PR_ID> --auto-complete true --delete-source-branch true

# If you get "Merge strategy is not allowed by policy" error, add the required merge strategy:
# For squash merge:
az repos pr update --id <PR_ID> --auto-complete true --squash true --delete-source-branch true

# For merge commit (no fast-forward):
az repos pr update --id <PR_ID> --auto-complete true --merge-commit-message "Custom message" --delete-source-branch true

# For rebase:
az repos pr update --id <PR_ID> --auto-complete true --transition-work-items true --delete-source-branch true
```

**Change PR status:**
```bash
# Abandon
az repos pr update --id <PR_ID> --status abandoned

# Reactivate
az repos pr update --id <PR_ID> --status active

# Complete (manual)
az repos pr update --id <PR_ID> --status completed
```

## PR Voting

**Approve PR:**
```bash
az repos pr set-vote --id <PR_ID> --vote approve
```

**Approve with suggestions:**
```bash
az repos pr set-vote --id <PR_ID> --vote approve-with-suggestions
```

**Wait for author:**
```bash
az repos pr set-vote --id <PR_ID> --vote wait-for-author
```

**Reject:**
```bash
az repos pr set-vote --id <PR_ID> --vote reject
```

**Reset vote:**
```bash
az repos pr set-vote --id <PR_ID> --vote reset
```

## PR Reviewers

**List reviewers on PR:**
```bash
az repos pr reviewer list --id <PR_ID> -o table
```

**Add reviewers to PR:**
```bash
az repos pr reviewer add --id <PR_ID> --reviewers "<reviewer-email>" "<reviewer-email>"
```

**Remove reviewer from PR:**
```bash
az repos pr reviewer remove --id <PR_ID> --reviewers "<reviewer-email>"
```

## PR Work Item Links

**List work items linked to PR:**
```bash
az repos pr work-item list --id <PR_ID> -o table
```

**Link work items to PR:**
```bash
az repos pr work-item add --id <PR_ID> --work-items 12345 67890
```

**Unlink work items from PR:**
```bash
az repos pr work-item remove --id <PR_ID> --work-items 12345
```

## Repository Listing

**List all repositories:**
```bash
az repos list -o table
```

**Get specific repo details:**
```bash
az repos show --repository <REPO_NAME>
```

## Common Workflows

### Create PR linked to work item
```bash
az repos pr create \
  --title "fix: resolve login issue" \
  --description "Fixes the authentication timeout bug" \
  --work-items 13930 \
  --auto-complete true \
  --delete-source-branch true
```

### Find and open my active PRs
```bash
# List them first
az repos pr list --creator "$(az account show --query user.name -o tsv)" --status active -o table

# Open specific one
az repos pr show --id <PR_ID> --open
```

## Gotchas

- **PR Templates:** Always check for `pull_request_template.md` before creating PRs and follow its structure
- **Squash Merge Detection:** When squash merge is used, check if a PR is merged by looking at the merge commit message format "Merged PR XXXX:" in the lastMergeCommit. The PR is merged if status is "completed" and lastMergeSourceCommit matches your latest commit - all commits get squashed into one.
- **Auto-Complete with Merge Policy:** If `az repos pr update --auto-complete true` fails with "Merge strategy is not allowed by policy", the repository requires squash merge. Use `--squash true` flag.
- **User filtering:** Use `$(az account show --query user.name -o tsv)` to automatically filter to current user
- **Status values:** PR statuses are: `active`, `abandoned`, `completed`, `all`
- **Output formats:** Use `-o table` for readable output, `-o json` (default) for programmatic use
- **Reviewers:** Separate multiple reviewers/work-items with spaces
- **Browser commands:** `--open` flag works but may not show output; useful for quick navigation

## Troubleshooting

**"Could not find git repository":**
- Either specify `--repository` explicitly, or run from within a git repo

**No PRs found for branch:**
- Check branch name: `git rev-parse --abbrev-ref HEAD`
- Ensure PR has been created for this branch
- Try checking all statuses: `--status all`
