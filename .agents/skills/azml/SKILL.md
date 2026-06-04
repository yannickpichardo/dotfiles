---
name: azml
description: Azure ML operations - submit jobs, track runs, poll training status, wait for completion, get metrics, check logs, monitor experiments, list compute targets
---

# Azure ML Operations

Use `az ml` CLI to interact with Azure ML workspace.

## Prerequisites

```bash
az extension add -n ml
az login
az account set --subscription <subscription-id>
az configure --defaults workspace=<workspace-name> group=<resource-group>
```

## Common operations

**Find jobs by name/experiment (fast search):**
```bash
# Search by keyword in experiment or job name (case-insensitive grep is faster than JMESPath contains)
az ml job list --max-results 100 -o table 2>&1 | grep -i "keyword"

# Example: find jobs by a domain keyword
az ml job list --max-results 100 -o table 2>&1 | grep -i "<keyword>"
```

**Submit a job:**
```bash
az ml job create --file job.yml
```

**List recent jobs:**
```bash
az ml job list --max-results 20 -o table
```

**Get job status:**
```bash
az ml job show -n <job-name> --query status -o tsv
```

**Get job summary (status, created, duration):**
```bash
az ml job show -n <job-name> --query "{Status:status, Created:creation_context.created_at, Description:description, Duration:properties.duration}" -o json 2>&1 | grep -v "experimental class"
```

**Stream job logs:**
```bash
az ml job stream -n <job-name>
```

**Wait for job completion:**
```bash
while [ "$(az ml job show -n <job-name> --query status -o tsv)" = "Running" ]; do
  echo "Job still running..."
  sleep 30
done
az ml job show -n <job-name> --query status -o tsv
```

**Get job metrics:**
```bash
az ml job show -n <job-name> --query properties.outputs -o json
```

**Download job outputs:**
```bash
az ml job download -n <job-name> --output-name <output-name> --download-path ./outputs
```

**List experiments:**
```bash
az ml job list --query "[].{Name:name, Status:status, Experiment:experiment_name}" -o table
```

**Cancel a job:**
```bash
az ml job cancel -n <job-name>
```

**List compute targets:**
```bash
az ml compute list -o table
```

**Check compute status:**
```bash
az ml compute show -n <compute-name> --query provisioning_state -o tsv
```

## Polling pattern for workflows

```bash
JOB_NAME=$(az ml job create --file job.yml --query name -o tsv)
echo "Started job: $JOB_NAME"

while true; do
  STATUS=$(az ml job show -n $JOB_NAME --query status -o tsv)
  echo "Status: $STATUS"
  
  case $STATUS in
    Completed)
      echo "Job completed successfully"
      az ml job show -n $JOB_NAME --query properties.outputs -o json
      break
      ;;
    Failed|Canceled)
      echo "Job failed or was canceled"
      az ml job stream -n $JOB_NAME
      exit 1
      ;;
    *)
      sleep 30
      ;;
  esac
done
```

## Integration with Azure DevOps

Link job name to work item in PR description or commit message for traceability.
