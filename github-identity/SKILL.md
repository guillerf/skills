---
name: github-identity
description: Perform GitHub work for Guille only as guillerf. Use for authenticated GitHub queries, git pushes, pull requests, issues, reviews, comments, releases, Actions, or repository changes.
---

# GitHub Identity

Use GitHub account **`guillerf`**, belonging to **Guillermo Ruiz / Guille Ruiz**, for all requested GitHub operations. Never use Pere Calopa's account (`prcalopa`), another person's credentials, or a shared connector identity. The authenticated login is authoritative; a Git author name, email, repository owner, or successful authentication alone does not prove the right account.

## API and CLI identity

1. Use the local `gh` CLI for GitHub work. Do not use the GitHub App/MCP connector for GitHub requests; its authentication can belong to someone else independently of `gh`.
2. Before the first authenticated read and immediately before **every GitHub write or push**, run:

   ```sh
   gh api --hostname github.com user --jq .login
   ```

   Require the result to be exactly `guillerf`. Perform the operation on the same machine and through the same authenticated environment. For a different GitHub host, verify `/user` on that exact host rather than assuming GitHub.com authentication applies.
3. If an already-configured `guillerf` account needs selecting, use `gh auth switch --hostname github.com --user guillerf`, then repeat the API check. This does not override `GH_TOKEN` or `GITHUB_TOKEN`; the effective API response must still pass. If the right identity cannot be verified, stop and report the authentication blocker. Never fall back to a different identity to bypass missing access or scopes.
4. Keep tokens in the existing secure credential store. Do not print or copy tokens, inspect credential contents, include credentials in command arguments, or put them in this repository.

## Git pushes

The CLI and Git transports can authenticate as different users. The API check above is necessary but does not prove who will push.

- Inspect the requested remote's actual push URLs with `git remote get-url --push --all REMOTE`. If there are multiple push targets, verify each one before any push.
- **SSH:** Verify the exact SSH user, host or alias, port, and key options used by the push, including any `GIT_SSH_COMMAND` or `core.sshCommand` override. For a default GitHub remote, use `ssh -o BatchMode=yes -T git@github.com`. Require the GitHub greeting to identify **`Hi guillerf!`**. GitHub normally exits with code **1** after successful authentication because it does not provide shell access. A greeting for another user or a deploy key does not pass. Do not disable host-key checking.
- **HTTPS:** Use credentials from the verified `gh` account for that specific command. For GitHub.com, a command-scoped helper can be selected with `git -c credential.helper= -c 'credential.https://github.com.helper=!gh auth git-credential' push ...`. Ensure an inherited HTTP Authorization header or another transport override cannot substitute a different account. If the effective transport cannot be verified, stop rather than assuming it matches `gh`.
- Preserve existing remotes and credentials. Do not rewrite them or weaken SSH checks to make a push succeed. Run only the push the user requested, with the verified transport. Verify the resulting remote ref against the intended commit afterward.

## Verify results

- After creating a PR, issue, review, comment, or release, read it back and verify its author login is `guillerf`, together with the requested state such as draft status. For PRs, `gh pr view URL --json author,isDraft,url,headRefName` provides the relevant evidence.
- Editing an existing resource does not change its original author; verify the effective API identity before the edit and the requested state afterward.
- If creation times out or verification fails, preserve any returned URL/ID and reconcile through reads before retrying. If the author is wrong, stop further writes and report it. Do not silently create a replacement, delete a resource, or change its ownership.
- Link a PR to the current host/thread when its workflow requires it, after creation through the verified GitHub account. Linking is not evidence of GitHub authorship.
- Validate this skill with read-only identity and SSH checks. Do not create test PRs, comments, issues, or pushes unless the user explicitly requests those actions.
