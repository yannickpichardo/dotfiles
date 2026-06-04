---
name: azdo-pipelines
description: Azure DevOps / AzDO / ADO pipeline operations with az pipelines - list pipelines, view pipeline runs, poll pipeline status, wait for completion, get pipeline results from PR, check build logs, monitor CI/CD status; if organization/project defaults are missing, route through azdo-context internally
---

# Azure DevOps Pipelines (AzDO, ADO, az pipelines)

Manage Azure DevOps pipelines and builds via `az pipelines` commands. Includes helpers for polling pipeline status and retrieving pipeline runs from PR context. If organization/project context is missing, use the `azdo-context` skill first.

## List Pipelines

**List all pipelines:**
```bash
az pipelines list -o table
```

**List pipelines with details:**
```bash
az pipelines list -o json
```

**Show specific pipeline definition:**
```bash
az pipelines show --id <PIPELINE_ID> -o table
```

## List Pipeline Runs

**List recent pipeline runs:**
```bash
az pipelines runs list -o table
```

**List recent runs (limit to top N):**
```bash
az pipelines runs list --top 10 -o table
```

**Filter runs by status:**
```bash
# In progress
az pipelines runs list --status inProgress -o table

# Completed
az pipelines runs list --status completed -o table

# Canceled
az pipelines runs list --status canceling -o table
```

**Filter runs by result:**
```bash
# Succeeded only
az pipelines runs list --result succeeded -o table

# Failed only
az pipelines runs list --result failed -o table

# Partially succeeded
az pipelines runs list --result partiallySucceeded -o table
```

**Filter runs by pipeline/definition:**
```bash
az pipelines runs list --pipeline-ids <PIPELINE_ID> -o table
```

**Filter runs by reason (trigger type):**
```bash
# Pull request triggered builds
az pipelines runs list --reason pullRequest -o table

# CI/continuous integration builds
az pipelines runs list --reason individualCI -o table

# Manual runs
az pipelines runs list --reason manual -o table

# Scheduled runs
az pipelines runs list --reason schedule -o table
```

**Combine filters:**
```bash
# Recent PR builds, succeeded only
az pipelines runs list --reason pullRequest --result succeeded --top 5 -o table
```

## View Pipeline Run Details

**Show specific run (table format):**
```bash
az pipelines runs show --id <BUILD_ID> -o table
```

**Show run with full JSON details:**
```bash
az pipelines runs show --id <BUILD_ID>
```

**Extract specific fields:**
```bash
# Status and result
az pipelines runs show --id <BUILD_ID> --query '{status: status, result: result, buildNumber: buildNumber}' -o table

# Timing information
az pipelines runs show --id <BUILD_ID> --query '{queued: queueTime, started: startTime, finished: finishTime}' -o table

# Requester and branch
az pipelines runs show --id <BUILD_ID> --query '{requestedFor: requestedFor.displayName, branch: sourceBranch, reason: reason}' -o table
```

## Get Pipelines from PR Context

**Get builds associated with a PR:**

1. **List PR policies (includes build status):**
```bash
az repos pr policy list --id <PR_ID> -o table
```

This shows all policy evaluations including builds. Look for the "Build" policy type and extract the "Build ID".

Example output:
```
Evaluation ID                         Policy                           Blocking    Status    Expired    Build ID
------------------------------------  -------------------------------  ----------  --------  ---------  ----------
e9339b5b-fcb3-46d3-8b9f-e7601d20b64c  Build                            True        Approved  False      16832
```

2. **Extract build IDs programmatically:**
```bash
# Get all build IDs from PR policies
az repos pr policy list --id <PR_ID> --query "[?configuration.type.displayName=='Build'].context.buildId" -o tsv

# Get build status from PR policies with build info
az repos pr policy list --id <PR_ID> --query "[?configuration.type.displayName=='Build'].{buildId: context.buildId, policyStatus: status, buildName: context.buildDefinitionName, blocking: configuration.isBlocking}" -o table
```

3. **Find PR builds by source branch:**
```bash
# Get PR source branch first
SOURCE_BRANCH=$(az repos pr show --id <PR_ID> --query sourceRefName -o tsv)

# Find builds for that branch
az pipelines runs list --branch "$SOURCE_BRANCH" --reason pullRequest -o table
```

4. **Find builds by PR number in merge branch:**
```bash
# PR builds use refs/pull/<PR_ID>/merge format
az pipelines runs list --branch "refs/pull/<PR_ID>/merge" --reason pullRequest -o table
```

## Poll Pipeline Status (Wait for Completion)

**Use the polling helper script to wait for a pipeline to complete:**

```bash
~/.claude/skills/azdo-pipelines/poll-pipeline.sh --build-id <BUILD_ID> [OPTIONS]
```

**Options:**
- `--build-id <ID>` - Build/run ID to poll (required)
- `--org <URL>` - Azure DevOps organization URL (e.g., https://dev.azure.com/YourOrg)
- `--project <NAME>` - Project name
- `--interval <SECONDS>` - Polling interval in seconds (default: 10)
- `--timeout <SECONDS>` - Maximum wait time in seconds (default: 3600)

**Examples:**

Poll with default settings (10s interval, 1 hour timeout):
```bash
~/.claude/skills/azdo-pipelines/poll-pipeline.sh --build-id 16832 \
  --org https://dev.azure.com/YourOrg \
  --project YourProject
```

Poll with custom interval and timeout:
```bash
~/.claude/skills/azdo-pipelines/poll-pipeline.sh --build-id 16832 \
  --org https://dev.azure.com/YourOrg \
  --project YourProject \
  --interval 5 \
  --timeout 1800
```

**Exit codes:**
- `0` - Build succeeded
- `1` - Build failed
- `2` - Build partially succeeded
- `3` - Build canceled
- `4` - Build completed with unknown result
- `5` - Timeout reached

**Example workflow - Wait for PR pipeline:**
```bash
# Get the PR's build ID
BUILD_ID=$(az repos pr policy list --id <PR_ID> --query "[?configuration.type.displayName=='Build'].context.buildId | [0]" -o tsv)

# Poll until completion
~/.claude/skills/azdo-pipelines/poll-pipeline.sh --build-id $BUILD_ID \
  --org https://dev.azure.com/YourOrg \
  --project YourProject

# Check exit code
if [ $? -eq 0 ]; then
  echo "Pipeline succeeded - safe to merge"
else
  echo "Pipeline failed - investigate before merging"
fi
```

## Manual Polling (Without Helper Script)

**Check status once:**
```bash
az pipelines runs show --id <BUILD_ID> --query '{status: status, result: result}' -o table
```

**Poll in a simple loop:**
```bash
while true; do
  STATUS=$(az pipelines runs show --id <BUILD_ID> --query status -o tsv)
  RESULT=$(az pipelines runs show --id <BUILD_ID> --query result -o tsv)
  echo "Status: $STATUS | Result: $RESULT"
  
  if [ "$STATUS" = "completed" ]; then
    echo "Build completed with result: $RESULT"
    break
  fi
  
  sleep 10
done
```

## View Build Logs

**Get logs URL:**
```bash
az pipelines runs show --id <BUILD_ID> --query 'logs.url' -o tsv
```

**Note:** The Azure CLI doesn't provide direct log content retrieval. To view actual logs:
1. Use the logs URL with Azure DevOps REST API
2. Open the build in browser: Navigate to the org/project and use the build ID
3. Use `az pipelines runs show --id <BUILD_ID> --open` (if supported by your CLI version)

## Common Workflows

### Check if PR pipelines are passing

```bash
# Get PR ID (if working from a git branch)
PR_ID=$(az repos pr list --source-branch "$(git rev-parse --abbrev-ref HEAD)" --status active --query '[0].pullRequestId' -o tsv)

# Get build IDs from PR policies
az repos pr policy list --id $PR_ID --query "[?configuration.type.displayName=='Build'].{buildId: context.buildId, policyStatus: status, buildName: context.buildDefinitionName}" -o table

# Check specific build
BUILD_ID=$(az repos pr policy list --id $PR_ID --query "[?configuration.type.displayName=='Build'].context.buildId | [0]" -o tsv)
az pipelines runs show --id $BUILD_ID --query '{status: status, result: result, buildNumber: buildNumber}' -o table
```

### Wait for PR pipeline then report status

```bash
# From PR ID
BUILD_ID=$(az repos pr policy list --id 2564 --query "[?configuration.type.displayName=='Build'].context.buildId | [0]" -o tsv)

# Poll until complete
~/.claude/skills/azdo-pipelines/poll-pipeline.sh --build-id $BUILD_ID \
  --org https://dev.azure.com/YourOrg \
  --project YourProject

# Capture result
RESULT=$?
if [ $RESULT -eq 0 ]; then
  echo "✓ PR pipeline passed successfully"
elif [ $RESULT -eq 1 ]; then
  echo "✗ PR pipeline failed - check logs before merging"
  az pipelines runs show --id $BUILD_ID --query 'logs.url' -o tsv
elif [ $RESULT -eq 2 ]; then
  echo "⚠ PR pipeline partially succeeded - review before merging"
fi
```

### Monitor recent failures

```bash
# List recent failed builds
az pipelines runs list --result failed --top 10 -o table

# Get details on a specific failure
az pipelines runs show --id <BUILD_ID> --query '{definition: definition.name, result: result, reason: reason, requestedFor: requestedFor.displayName, finishTime: finishTime}' -o table
```

### Check PR pipeline status without polling

```bash
# Quick status check
PR_ID=2564
BUILD_ID=$(az repos pr policy list --id $PR_ID --query "[?type.displayName=='Build'].buildId | [0]" -o tsv)
az pipelines runs show --id $BUILD_ID --query '{buildNumber: buildNumber, status: status, result: result, definition: definition.name}' -o json
```

## Pipeline Run Status Values

**Status (execution state):**
- `inProgress` - Currently running
- `completed` - Finished (check `result` for outcome)
- `canceling` - Being canceled
- `postponed` - Delayed
- `notStarted` - Queued but not started
- `none` - No status

**Result (outcome - only when status is completed):**
- `succeeded` - All tasks passed
- `failed` - One or more tasks failed
- `partiallySucceeded` - Some tasks failed but not critical ones
- `canceled` - Build was canceled
- `none` - No result yet (still in progress)

**Reason (trigger type):**
- `pullRequest` - Triggered by PR
- `individualCI` - Triggered by direct commit
- `batchedCI` - Triggered by batched commits
- `manual` - Manually triggered
- `schedule` - Triggered by schedule
- `buildCompletion` - Triggered by another build

## Understanding Pipeline Results

**When checking if a pipeline is "done":**
- Check `status == "completed"`

**When determining if a pipeline "passed":**
- `result == "succeeded"` → Passed
- `result == "partiallySucceeded"` → Partial (some non-critical failures)
- `result == "failed"` → Failed
- `result == "canceled"` → Canceled

**For PR merge decisions:**
- Only `succeeded` is typically safe for auto-merge
- `partiallySucceeded` requires manual review
- `failed` or `canceled` should block merge

## Gotchas

- **PR Build Association:** PR builds are linked through PR policies (`az repos pr policy list`), not directly queryable by PR ID in pipelines commands
- **Build ID vs Definition ID:** Build/run ID is unique per execution; Definition/Pipeline ID is the template
- **Merge Branch Format:** PR builds use `refs/pull/<PR_ID>/merge` as the source branch, not the feature branch ref
- **Policy Status vs Build Status:** PR policy status (`Approved`/`Rejected`) reflects whether the build policy passed, not the build's current state - always check the actual build status
- **Multiple Builds per PR:** A PR can trigger multiple builds (different pipelines, re-runs). Policy list shows the most recent for each pipeline
- **Status vs Result:** `status` tells you if it's running; `result` tells you how it finished. Only check `result` when `status == "completed"`
- **Polling Timeout:** Default timeout is 1 hour - adjust based on your typical pipeline duration
- **Organization/Project Context:** If `az devops configure` has defaults set, `--org` and `--project` are optional; otherwise run the first-use local context steps above

## Troubleshooting

**"No builds found for PR":**
- Check PR policies: `az repos pr policy list --id <PR_ID> -o table`
- Verify PR has triggered builds (some PRs may skip CI based on branch policies)
- Try searching by merge branch: `az pipelines runs list --branch "refs/pull/<PR_ID>/merge" -o table`

**"Build ID not found in policy list":**
- Build may not be a required policy
- Check all PR builds: `az pipelines runs list --reason pullRequest --top 20 -o table` and match by timing/branch

**"Poll script exits with code 5 (timeout)":**
- Increase timeout: `--timeout 7200` (2 hours)
- Check if build is actually stuck (may need manual cancellation)
- Verify build is progressing: `az pipelines runs show --id <BUILD_ID> --query '{status: status, queueTime: queueTime, startTime: startTime}'`

**"Permission denied" on poll script:**
- Make executable: `chmod +x ~/.claude/skills/azdo-pipelines/poll-pipeline.sh`

**Windows path issues with poll script:**
- Use Git Bash or WSL
- Or call via: `bash ~/.claude/skills/azdo-pipelines/poll-pipeline.sh --build-id <ID> ...`

**"Could not find organization/project":**
- Explicitly pass `--org` and `--project` flags
- Or configure defaults: `az devops configure --defaults organization=https://dev.azure.com/YourOrg project=YourProject`
