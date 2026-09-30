# Local Jira token

1. Sign in as `guillermo.ruiz@crisalix.com` at [Atlassian API tokens](https://id.atlassian.com/manage-profile/security/api-tokens).
2. Create a new **API token with scopes** for Jira, named for this Mac (for example `Codex en este Mac`), with an expiration of your choice.
3. Select classic scopes `read:jira-user`, `read:jira-work`, `write:jira-work`. Jira project permissions still apply, including Create Issues and Modify Reporter.
4. Run the included `scripts/jira setup`, or open the local setup launcher supplied by the configuring chat. Paste only into the native secure field. Never paste into Codex, a terminal command, a payload or an environment file.
5. Setup calls GET `/myself`, requires the active expected name/email/accountId, then stores the raw token in Keychain with synchronization disabled. No card is created. A failed check leaves an existing token unchanged.
6. `scripts/jira check` verifies the saved credential through GET `/myself`. Setup can replace an expired token; revoke old tokens in Atlassian as needed.

This Mac has its own credential. The remote `JIRA` secret was a complete Base64 Basic credential; it is neither fetched nor decoded. The local client constructs Basic Auth once from email plus raw token in memory, refuses redirects, and uses ephemeral URLSession storage.

Sources: [Atlassian tokens and scoped gateway URLs](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/), [GET /myself](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-myself/), [Jira classic scopes](https://developer.atlassian.com/cloud/jira/platform/scopes-for-oauth-2-3LO-and-forge-apps/).
