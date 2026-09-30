---
name: crisalix-jira-card
description: Create Jira cards, tickets, tasks, bugs, stories, or spikes in Crisalix ENG, CORE, or CRI as Guillermo Ruiz through REST using this Mac's Keychain token.
---

# Crisalix Jira Card

Create requested cards through Jira Cloud REST as **Guillermo Ruiz** (`guillermo.ruiz@crisalix.com`). Never use Rovo, the Codex Jira connector, `_createjiraissue`, or Pere Calopa's credentials for this workflow. Do not create test cards unless explicitly requested. A request to create a real card authorizes that creation.

This reproduces OpenClaw's `crisalix-jira-card/SKILL.md` and `references/board-defaults.md` from `crisalito@macbook-air-de-crisalito`, adapted to this Mac. The server's protected `JIRA` secret is **not** copied or used locally.

Read [references/board-defaults.md](references/board-defaults.md) for exact project/type/field IDs, ADF examples, routing options and transitions. Prefer these defaults over metadata discovery unless creation fails, the project/type is outside ENG/CORE/CRI, or unusual fields are requested.

## Local authentication and transport

Use the included `scripts/jira` executable, resolving it against this skill directory. On this installation:

```sh
/Users/guille/.agents/skills/crisalix-jira-card/scripts/jira check
```

- Endpoint: `https://api.atlassian.com/ex/jira/82b5fe1b-d904-46bb-a485-32f01e7ea2d7/rest/api/3`.
- Basic Auth is built internally from the fixed email and raw API token retrieved from macOS Keychain. Never supply a token or Basic credential in shell arguments, environment variables, files, chat, or logs. Never run a command to print/export the Keychain secret.
- Keychain service: `com.crisalix.codex.jira.82b5fe1b-d904-46bb-a485-32f01e7ea2d7`; account: `guillermo.ruiz@crisalix.com`; synchronization disabled. The compiled client is cached in `~/Library/Caches/crisalix-jira-card/jira` and contains no secret.
- If missing/expired/rejected, ask the user to create a separate token for this Mac and launch `scripts/jira setup`. It presents a native secure field outside chat, verifies `/myself`, and only then stores the token. For this endpoint use a scoped Jira token with classic scopes `read:jira-user`, `read:jira-work`, `write:jira-work`. See [references/local-auth.md](references/local-auth.md).
- `check`, `create`, and `transition` verify `/myself`. Every write requires active Guillermo Ruiz, the expected email, and a nonempty accountId. Never bypass a failed check or fall back to a connector/server token. Allow the user to handle any macOS Keychain access prompt.

## Workflow

1. Identify ENG, CORE, or CRI; ask only if the target is ambiguous or essential context is missing.
2. Default to Task; use Bug for clearly broken behavior and Bug staging only when explicitly indicated. Preserve requested Story/Spike/Epic types.
3. Build a REST v3 `{ "fields": { ... } }` JSON file in the task's `work/` directory. Include project, issuetype, summary, and an ADF description with context, goal, and acceptance criteria. For bugs include actual/expected behavior, scope/environment and reproduction steps; do not invent missing facts.
4. Include `customfield_10275` (Why) as ADF for Tasks. Omit Why for CRI Bug; the create screen rejects it. Set optional product/area/components only when strongly implied.
5. Run `scripts/jira create /absolute/path/to/work/payload.json`. The client checks `/myself`, sets reporter to that verified accountId, performs POST `/issue`, prints the created key immediately, and fetches summary, status, **creator and reporter**. Both people must have Guillermo's verified accountId and display name. Creator is assigned by Jira; never set it in the payload.
6. If a requested state differs, run `scripts/jira transition KEY 'To Do'` or `scripts/jira transition KEY Backlog`. It checks identity and both people before writing and verifies them and the requested status afterward. Transition IDs are 11 and 111. Do not choose a new state without user intent.
7. Return issue key/link, title, final status, creator and reporter. Never claim either identity or final status is verified if read-back failed.

## Failures and recovery

- For a definitive Jira field-validation error, use `scripts/jira get '/issue/createmeta/PROJECT/issuetypes/TYPE_ID'` for the requested project/type only; correct the payload, update the reference after confirmation, and retry once. Stop if the same validation error recurs.
- After a timeout, transport failure, 5xx, or success without a key, creation may already have happened. Do not repeat POST `/issue` automatically; reconcile through read-only queries first. `scripts/jira get '/search/jql?jql=URL_ENCODED_JQL&fields=summary,creator,reporter,status'` can locate candidates. Ask if the outcome remains uncertain.
- If a created key was printed but verification failed, preserve and report that key. Use `scripts/jira read KEY` to retry read-back. Do not create a duplicate, delete the issue, silently change reporter, or transition while identity verification is unresolved.
- Authentication or creator/reporter mismatch: stop further writes and report the failure. Never switch to Pere/Rovo or import OpenClaw's secret.
- `scripts/jira self-test` runs offline mocked checks only: no network, Keychain access, or test card.
