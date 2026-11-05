---
name: crisalix-jira-card
description: Create Jira cards, tickets, tasks, bugs, stories, or spikes in Crisalix ENG, CORE, or CRI as Guillermo Ruiz through REST, from local Codex or an OpenClaw Gateway.
---

# Crisalix Jira Card

Create requested cards through Jira Cloud REST as **Guillermo Ruiz** (`guillermo.ruiz@crisalix.com`). Never use Rovo, the Codex Jira connector, `_createjiraissue`, or Pere Calopa's credentials. Do not create test cards unless explicitly requested. A request to create a card authorizes that creation.

Use the same creation rules and board defaults in both environments. Credentials belong to each deployment and are never included in this skill or transferred between computers.

## Choose the transport

Select by the **current agent runtime**, not OS, hostname, or the mere presence of an environment variable: an OpenClaw server can also run macOS.

| Runtime | Authentication and execution | Reference |
| --- | --- | --- |
| Local Codex on macOS | This computer's API token in Keychain; included `scripts/jira` client | [references/local-auth.md](references/local-auth.md) |
| OpenClaw with its protected Gateway exec/egress capability | Deployment's protected `JIRA` Basic credential; Gateway-hosted REST requests | [references/openclaw-auth.md](references/openclaw-auth.md) |

Read only the authentication reference for the active runtime, plus [references/board-defaults.md](references/board-defaults.md) for project/type/field IDs, ADF examples, routing options and transitions. Resolve supporting paths relative to this skill's loaded directory; do not assume a particular user's home or checkout path.

If the runtime or secure transport is unavailable or ambiguous, stop before writing and report what is missing. Do not fall back between credentials or connectors. In particular, a local Codex session with SSH access to OpenClaw still uses its local token; SSH availability does not select the Gateway transport.

## Shared identity and API contract

- Base URL: `https://api.atlassian.com/ex/jira/82b5fe1b-d904-46bb-a485-32f01e7ea2d7/rest/api/3`.
- Use Basic Auth through the chosen secure transport. Never print, log, decode for inspection, export, or pass a credential in command arguments. Local tokens are raw API tokens; OpenClaw's `JIRA` is already Base64 encoded. Do not confuse the two formats.
- Before **each Jira write**, call GET `/myself` through that transport. Require `active: true`, display name `Guillermo Ruiz`, email `guillermo.ruiz@crisalix.com`, and a nonempty `accountId`. Stop on a mismatch or missing identity evidence.
- Set `fields.reporter.accountId` to that verified accountId. Jira assigns creator; never set `fields.creator`.
- After creation, fetch `summary,status,creator,reporter`. Both creator and reporter must have Guillermo's verified accountId and display name. A mismatch stops further writes.
- The local client enforces these checks automatically. In OpenClaw, perform the same checks with Gateway-hosted requests as described in its reference.

## Shared creation workflow

1. Identify ENG, CORE, or CRI; ask only if the target is ambiguous or essential context is missing. Prefer remembered defaults over metadata discovery unless creation fails, the project/type is outside these boards, or unusual fields are requested.
2. Default to Task; use Bug for clearly broken behavior and Bug staging only when explicitly indicated. Preserve requested Story/Spike/Epic types.
3. Build a REST v3 `{ "fields": { ... } }` JSON payload in the current task's scratch/work directory. Include project, issuetype, summary, and an ADF description with context, goal, and acceptance criteria. For bugs include actual/expected behavior, scope/environment and reproduction steps; do not invent missing facts. Honor explicitly requested placeholder content.
4. Include `customfield_10275` (Why) as ADF for Tasks. Omit Why for CRI Bug; its create screen rejects it. Set optional product/area/components only when strongly implied.
5. Verify identity, set reporter, and POST `/issue` through the selected transport. Preserve the returned key immediately, then GET `/issue/{key}?fields=summary,status,creator,reporter` and verify both people.
6. If a requested state differs, verify identity again and check creator/reporter before POST `/issue/{key}/transitions`. Transition IDs: `11` for To Do and `111` for Backlog. Fetch the issue afterward and verify both people and the requested final status. Do not choose a new state without user intent.
7. Return issue key/link, title, final status, creator and reporter. Never claim identity or final status is verified if read-back failed.

## Failures and recovery

- For a definitive Jira field-validation error, GET `/issue/createmeta/PROJECT/issuetypes/TYPE_ID` for the requested project/type only. Correct the payload, update the board reference after confirming the field shape, recheck identity, and retry once. Stop if the same validation error recurs.
- After a timeout, transport failure, 5xx, or success without a key, creation may already have happened. Do not repeat POST `/issue` automatically; reconcile through read-only queries first. GET `/search/jql?jql=URL_ENCODED_JQL&fields=summary,creator,reporter,status` can locate candidates. Ask if the outcome remains uncertain.
- If a created key is known but verification failed, preserve and report it, then retry only read-back. Do not create a duplicate, delete the issue, silently change reporter, or transition while verification is unresolved.
- Authentication or creator/reporter mismatch: stop further writes and report the failure. Never switch to Pere/Rovo, another computer's token, or a different transport to bypass it.
- Validate local client behavior with `scripts/jira self-test`: offline mocked checks only, no network, Keychain access, or test card.
