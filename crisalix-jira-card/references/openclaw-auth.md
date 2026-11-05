# OpenClaw Gateway transport

Use this transport only inside an OpenClaw deployment with protected
Gateway-hosted exec and egress access. The server being macOS does not select the
local Keychain client. The included Swift client is for local Codex, not a way
to read or import OpenClaw's secret.

## Protected authentication

- Use the deployment's existing protected team-store secret named `JIRA`.
- Before the first request, list **secret metadata only** through the runtime's
  protected secret tooling. Confirm `JIRA` is restricted to the intended hosts
  `api.atlassian.com` and `crisalix.atlassian.net`. Do not read or display its value.
- `JIRA` is the complete Base64 Basic credential for
  `guillermo.ruiz@crisalix.com:<API token>`. Have the Gateway inject/use it as
  `Authorization: Basic $JIRA` through its protected exec/egress mechanism.
  Do **not** Base64-encode it again, decode it for inspection, or treat it as a
  raw API token.
- Execute the request code in the protected Gateway environment. Ordinary SSH
  exec or a local shell is not equivalent and does not automatically inherit
  the secret or proxy access.
- Never interpolate a resolved credential into a visible tool argument or
  shell command line. Do not use shell tracing, curl verbose output, environment
  dumps, debug header logs, or files containing the credential.
- If the protected tools, host restrictions, or secret are unavailable, stop
  and report the missing capability. Do not export the secret, provision it
  through chat, or substitute the local Mac's Keychain token.

Use the actual protected tool interface supplied by that OpenClaw deployment;
tool names and injection APIs may vary. This skill does not invent a secret
retrieval command or require the credential to be exposed to an ordinary process.

## REST execution

Base URL:
`https://api.atlassian.com/ex/jira/82b5fe1b-d904-46bb-a485-32f01e7ea2d7/rest/api/3`

Send `Accept: application/json` and, for JSON writes,
`Content-Type: application/json`. Keep credentials on the approved endpoint;
do not follow redirects with the Authorization header.

Implement the shared workflow in `SKILL.md` through Gateway-hosted REST requests:

1. GET `/myself` **before every write**. Require active Guillermo Ruiz, the
   expected email, and a nonempty accountId; retain that accountId for verification.
2. For creation, insert `fields.reporter = { "accountId": verifiedAccountId }`
   into the payload from the board reference. Never set creator.
3. POST `/issue`. Preserve the returned key before any subsequent request.
4. GET `/issue/{key}?fields=summary,status,creator,reporter`. Check that both
   creator and reporter have the verified accountId and display name Guillermo Ruiz.
   If either fails, report the key and stop all writes.
5. When a different state was requested, recheck `/myself` and the issue's
   creator/reporter, POST `/issue/{key}/transitions` with the transition ID, and
   GET the same issue fields again to verify both people and the final status.

Do not retry an uncertain creation automatically. Use read-only reconciliation
as described in `SKILL.md`; a read-back failure must not cause another creation.
Report only useful issue data or sanitized errors, never authentication material.

## Installation and credential separation

Install or link the **whole** `crisalix-jira-card/` directory from the repository
into the skill location used by that OpenClaw deployment. Include its references;
copying only `SKILL.md` leaves the transport and board instructions incomplete.
The installation path is deployment-specific and is not embedded in the skill.

Updating this directory requires no credential migration. The existing protected
`JIRA` secret stays in the server's store; local Codex tokens stay in each Mac's
Keychain. This skill does not grant permission to change either secret.
