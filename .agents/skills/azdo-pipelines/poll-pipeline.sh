#!/bin/bash
# Azure DevOps Pipeline Polling Script
# Polls a pipeline build until completion and reports result

set -e

USAGE="Usage: $0 --build-id <ID> [--org <ORG_URL>] [--project <PROJECT>] [--interval <SECONDS>] [--timeout <SECONDS>]"

# Default values
INTERVAL=10
TIMEOUT=3600  # 1 hour default timeout
ORG=""
PROJECT=""
BUILD_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --build-id)
      BUILD_ID="$2"
      shift 2
      ;;
    --org)
      ORG="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --interval)
      INTERVAL="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    -h|--help)
      echo "$USAGE"
      echo ""
      echo "Options:"
      echo "  --build-id <ID>       Build/run ID to poll (required)"
      echo "  --org <URL>           Azure DevOps organization URL"
      echo "  --project <NAME>      Project name"
      echo "  --interval <SECONDS>  Polling interval (default: 10)"
      echo "  --timeout <SECONDS>   Maximum wait time (default: 3600)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "$USAGE"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$BUILD_ID" ]; then
  echo "Error: --build-id is required"
  echo "$USAGE"
  exit 1
fi

# Build az pipelines command
CMD="az pipelines runs show --id $BUILD_ID"
if [ -n "$ORG" ]; then
  CMD="$CMD --org $ORG"
fi
if [ -n "$PROJECT" ]; then
  CMD="$CMD --project $PROJECT"
fi

echo "Polling build $BUILD_ID (interval: ${INTERVAL}s, timeout: ${TIMEOUT}s)..."
echo ""

START_TIME=$(date +%s)
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  # Get current build status
  BUILD_INFO=$($CMD 2>&1)

  if [ $? -ne 0 ]; then
    echo "Error querying build: $BUILD_INFO"
    exit 1
  fi

  STATUS=$(echo "$BUILD_INFO" | grep -o '"status": "[^"]*"' | head -1 | sed 's/"status": "\([^"]*\)"/\1/')
  RESULT=$(echo "$BUILD_INFO" | grep -o '"result": "[^"]*"' | head -1 | sed 's/"result": "\([^"]*\)"/\1/')
  BUILD_NUMBER=$(echo "$BUILD_INFO" | grep -o '"buildNumber": "[^"]*"' | head -1 | sed 's/"buildNumber": "\([^"]*\)"/\1/')
  DEFINITION_NAME=$(echo "$BUILD_INFO" | grep -o '"name": "[^"]*"' | grep -v "Azure Pipelines" | head -1 | sed 's/"name": "\([^"]*\)"/\1/')

  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))

  echo "[$(date '+%H:%M:%S')] Status: $STATUS | Result: ${RESULT:-pending} | Elapsed: ${ELAPSED}s"

  # Check if build is complete
  if [ "$STATUS" = "completed" ]; then
    echo ""
    echo "============================================"
    echo "Build completed!"
    echo "============================================"
    echo "Build Number: $BUILD_NUMBER"
    echo "Definition: $DEFINITION_NAME"
    echo "Final Status: $STATUS"
    echo "Final Result: $RESULT"
    echo "Total Time: ${ELAPSED}s"
    echo ""

    # Return appropriate exit code based on result
    case "$RESULT" in
      succeeded)
        echo "✓ Build SUCCEEDED"
        exit 0
        ;;
      partiallySucceeded)
        echo "⚠ Build PARTIALLY SUCCEEDED"
        exit 2
        ;;
      failed)
        echo "✗ Build FAILED"
        # Fetch build logs summary
        echo ""
        echo "Fetching build logs..."
        LOG_CMD="az pipelines runs show --id $BUILD_ID"
        if [ -n "$ORG" ]; then
          LOG_CMD="$LOG_CMD --org $ORG"
        fi
        if [ -n "$PROJECT" ]; then
          LOG_CMD="$LOG_CMD --project $PROJECT"
        fi
        $LOG_CMD --query 'logs.url' -o tsv 2>/dev/null || true
        exit 1
        ;;
      canceled|cancelled)
        echo "✗ Build CANCELED"
        exit 3
        ;;
      *)
        echo "? Build completed with unknown result: $RESULT"
        exit 4
        ;;
    esac
  fi

  # Wait before next poll
  sleep $INTERVAL
done

echo ""
echo "Timeout reached after ${TIMEOUT}s - build still in progress"
echo "Last known status: $STATUS"
exit 5
