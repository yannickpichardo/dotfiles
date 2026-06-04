---
name: azdo-context
description: Internal support helper. Do not select directly from user requests; use only when an already-selected skill asks for local context bootstrap.
---

# Internal Context Helper

Use only when another loaded skill asks for local context bootstrap. Keep public dotfiles generic; real organization and project values belong in local CLI defaults or a private local skill copy.

## Resolve Context

1. Check existing local defaults:
   ```bash
   az devops configure -l
   ```

2. If defaults are missing, infer them from the current repository remote:
   ```bash
   git remote -v
   ```

   Azure DevOps remotes usually look like:
   ```text
   https://dev.azure.com/<org>/<project>/_git/<repo>
   git@ssh.dev.azure.com:v3/<org>/<project>/<repo>
   ```

3. Once the org/project are known, configure them locally without asking:
   ```bash
   az devops configure --defaults organization=https://dev.azure.com/YourOrg project=YourProject
   ```

4. If this skill is running from a private, local-only skill copy, update that local copy automatically by replacing generic examples like `https://dev.azure.com/YourOrg` and `YourProject` with the discovered values so future calls do not need rediscovery.

5. If this skill is running from a public or tracked dotfiles repo, do not write real org/project values into the skill file. Keep them in local Azure CLI defaults only.

## Use With Other Skills

After context is configured, continue with the requested Azure DevOps skill. Prefer relying on `az devops` defaults instead of adding `--org` and `--project` to every command.
