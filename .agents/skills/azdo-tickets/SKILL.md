---
name: azdo-tickets
description: Azure DevOps work items and sprint management - create ticket, view work item, list backlog, sprint tasks, update task status, query bugs, assign work items, check sprint progress, manage iterations
---

# Azure DevOps Work Items & Tickets

Manage Azure DevOps work items, backlog, and sprint tasks via `az boards` commands. All queries automatically filter to the current user with `@Me`.

## First-Use Local Context

This skill is kept public, so do not commit real organization or project values here. On first use, if Azure DevOps organization/project context is unknown:

1. Check existing local defaults:
   ```bash
   az devops configure -l
   ```
2. If defaults are missing, infer them from the current repository remote:
   ```bash
   git remote -v
   ```
   Azure DevOps remotes usually look like `https://dev.azure.com/<org>/<project>/_git/<repo>` or `git@ssh.dev.azure.com:v3/<org>/<project>/<repo>`.
3. Once the org/project are known, configure them locally without asking:
   ```bash
   az devops configure --defaults organization=https://dev.azure.com/YourOrg project=YourProject
   ```
4. If this skill is running from a private, local-only skill copy, update that local copy automatically by replacing generic examples like `https://dev.azure.com/YourOrg` and `YourProject` with the discovered values so future calls do not need rediscovery.
5. If this skill is running from a public or tracked dotfiles repo, do not write real org/project values into the skill file. Keep them in local Azure CLI defaults only.

## List My Work Items

**All work items assigned to me:**
```bash
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] FROM WorkItems WHERE [System.AssignedTo] = @Me" -o table
```

**Active work items (not Done/Removed):**
```bash
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] <> 'Done' AND [System.State] <> 'Removed'" -o table
```

**Work items by state:**
```bash
# New items
az boards query --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] = 'New'" -o table

# Committed/In Progress
az boards query --wiql "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] = 'Committed'" -o table
```

**Work items by type:**
```bash
# Bugs only
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.WorkItemType] = 'Bug'" -o table

# Product Backlog Items
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.WorkItemType] = 'Product Backlog Item'" -o table

# Tasks
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.WorkItemType] = 'Task'" -o table
```

**Work items with sprint/iteration:**
```bash
# Show active work items with their sprint
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.IterationPath] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] <> 'Done' AND [System.State] <> 'Removed'" -o table

# Filter by specific sprint/iteration
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.IterationPath] = 'YourProject\Sprint 71'" -o table
```

## View Work Item Details

**Show work item (table format):**
```bash
az boards work-item show --id <WORK_ITEM_ID> -o table
```

**Show work item with full JSON:**
```bash
az boards work-item show --id <WORK_ITEM_ID>
```

**Open work item in browser:**
```bash
az boards work-item show --id <WORK_ITEM_ID> --open
```

## Create Work Item

**Create a bug:**
```bash
az boards work-item create \
  --title "Bug title" \
  --type "Bug" \
  --assigned-to "<assignee-email>" \
  --description "Bug description"
```

**Create a Product Backlog Item:**
```bash
az boards work-item create \
  --title "PBI title" \
  --type "Product Backlog Item" \
  --assigned-to "<assignee-email>" \
  --description "PBI description"
```

**Create a Task:**
```bash
az boards work-item create \
  --title "Task title" \
  --type "Task" \
  --assigned-to "<assignee-email>" \
  --description "Task description"
```

**Create work item with custom fields:**
```bash
az boards work-item create \
  --title "Work item title" \
  --type "Bug" \
  --assigned-to "<assignee-email>" \
  --fields "System.Tags=urgent;hotfix" "Microsoft.VSTS.Common.Priority=1"
```

**Create and open in browser:**
```bash
az boards work-item create \
  --title "Work item title" \
  --type "Product Backlog Item" \
  --open
```

## Update Work Item

**Update state:**
```bash
az boards work-item update --id <WORK_ITEM_ID> --state "Done"
az boards work-item update --id <WORK_ITEM_ID> --state "Committed"
az boards work-item update --id <WORK_ITEM_ID> --state "New"
az boards work-item update --id <WORK_ITEM_ID> --state "Active"
```

**Update title:**
```bash
az boards work-item update --id <WORK_ITEM_ID> --title "Updated title"
```

**Update description:**
```bash
az boards work-item update --id <WORK_ITEM_ID> --description "Updated description"
```

**Update assignment:**
```bash
az boards work-item update --id <WORK_ITEM_ID> --assigned-to "<assignee-email>"
```

**Add comment/discussion:**
```bash
az boards work-item update --id <WORK_ITEM_ID> --discussion "This is a comment on the work item"
```

**Update and open in browser:**
```bash
az boards work-item update --id <WORK_ITEM_ID> --state "Done" --open
```

## Common Workflows

### Check my sprint backlog
```bash
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] <> 'Done' AND [System.State] <> 'Removed' ORDER BY [Microsoft.VSTS.Common.Priority]" -o table
```

### Find high-priority bugs
```bash
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.WorkItemType] = 'Bug' AND [Microsoft.VSTS.Common.Priority] = 1" -o table
```

### List work items for current sprint
```bash
# Replace "Sprint 71" with your current sprint
az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.IterationPath] UNDER 'YourProject\Sprint 71'" -o table
```

## Configuration

**Check current configuration:**
```bash
az devops configure -l
```

**Set default organization:**
```bash
az devops configure --defaults organization=https://dev.azure.com/YourOrg
```

**Set default project:**
```bash
az devops configure --defaults project=YourProject
```

## Gotchas

- **User filtering:** Use `@Me` in WIQL queries to automatically filter to current user
- **Work item states:** Common states are `New`, `Committed`, `Active`, `Done`, `Removed` but may vary by work item type
- **Work item types:** Common types are `Bug`, `Product Backlog Item`, `Task`, `Epic`, `Feature`
- **Output formats:** Use `-o table` for readable output, `-o json` (default) for programmatic use
- **WIQL queries:** Use double quotes for the full query, single quotes for string literals inside WIQL
- **Iteration paths:** Format is typically `ProjectName\Sprint X` or `ProjectName\Team\Sprint X`

## Troubleshooting

**"Please run 'az login' to setup account":**
```bash
az login
```

**"No default organization/project set":**
```bash
az devops configure --defaults organization=https://dev.azure.com/YourOrg project=YourProject
```

**WIQL syntax errors:**
- Ensure proper quote escaping
- Use `System.AssignedTo` not just `AssignedTo`
- Use `@Me` for current user, not literal email
- Use `UNDER` for iteration path hierarchy matching
