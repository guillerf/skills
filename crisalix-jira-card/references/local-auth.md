# Local Codex on macOS

Use this transport for a local Codex session. It works from any skill checkout or
installation path on macOS; each computer needs its own locally entered token.
Do not use OpenClaw's protected `JIRA` value, even if SSH or an environment variable
with that name is available.

## Client and commands

Resolve `scripts/jira` against the directory containing the loaded `SKILL.md`.
The commands below assume that directory is the working directory; from a task
workspace use the resolved absolute client path. Payload paths refer to the task
workspace, not the skill checkout.

```sh
./scripts/jira check
./scripts/jira create /absolute/path/to/task/work/payload.json
./scripts/jira read ENG-123
./scripts/jira transition ENG-123 'To Do'
./scripts/jira transition ENG-123 Backlog
./scripts/jira get '/issue/createmeta/ENG/issuetypes/10002'
./scripts/jira self-test
```

`check` verifies /myself. `create` also assigns reporter and verifies creator and
reporter on read-back. `transition` verifies identity and both people before
writing and verifies the final state afterward. `get` is read-only.
`self-test` uses mocked responses and makes no external calls.

The launcher compiles the bundled Swift client with Apple's Swift compiler and
caches it at `~/Library/Caches/crisalix-jira-card/jira`. The cache contains no
credentials. Requires macOS, Swift compiler, and access to the user's Keychain;
an unavailable compiler or Keychain must be reported, without another transport.

## Token setup and storage

1. Sign in as `guillermo.ruiz@crisalix.com` at [Atlassian API tokens](https://id.atlassian.com/manage-profile/security/api-tokens).
2. Create a new **API token with scopes** for Jira, named for this Mac (for example `Codex en este Mac`), with an expiration of your choice.
3. Select classic scopes `read:jira-user`, `read:jira-work`, `write:jira-work`. Jira project permissions still apply, including Create Issues and Modify Reporter.
4. Run `./scripts/jira setup` from the skill directory, or use its resolved absolute path. Paste only into the native secure field. Never paste into Codex, a terminal command, a payload or an environment file.
5. Setup calls GET `/myself`, requires the active expected name/email/accountId, then stores the raw token in Keychain with synchronization disabled. No card is created. A failed check leaves an existing token unchanged.
6. `scripts/jira check` verifies the saved credential through GET `/myself`. Setup can replace an expired token; revoke old tokens in Atlassian as needed.

Keychain service: `com.crisalix.codex.jira.82b5fe1b-d904-46bb-a485-32f01e7ea2d7`.
Keychain account: `guillermo.ruiz@crisalix.com`. Synchronization is disabled.
Allow the user to handle any macOS Keychain access prompt.

The existing Keychain entry on an already configured Mac remains usable when
this skill is moved, updated, or cloned elsewhere on that same computer. Cloning
the repository onto another computer does not install a token.

The local client constructs Basic Auth once from email plus raw token in memory,
refuses redirects, and uses ephemeral URLSession storage.

Sources: [Atlassian tokens and scoped gateway URLs](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/), [GET /myself](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-myself/), [Jira classic scopes](https://developer.atlassian.com/cloud/jira/platform/scopes-for-oauth-2-3LO-and-forge-apps/).
