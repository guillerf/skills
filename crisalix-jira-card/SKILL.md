---
name: crisalix-jira-card
description: Create Jira cards in Crisalix ENG, CORE, or CRI boards without rediscovering required fields. Use when the user asks to create, add, open, or file a Jira card, ticket, issue, task, bug, story, spike, backlog item, or To Do card in ENG / 3ngine 3D, CORE / engine + DL, or CRI / Crisalix.
---

# Crisalix Jira Card

## Overview

Create cards in the common Crisalix Jira boards with remembered defaults. Prefer this workflow over exploratory project/field metadata calls unless creation fails, the requested project/type is outside ENG/CORE/CRI, or the user asks for unusual fields.

Read `references/board-defaults.md` when you need exact IDs, option values, payload examples, or Bug/Bug staging details.

## Fast Workflow

1. Identify the project key from the user request: `ENG`, `CORE`, or `CRI`.
2. Use `_createjiraissue` with the known cloud ID and project key.
3. Default to `Task` unless the user explicitly asks for `Bug`, `Story`, or `Spike`, or the wording clearly implies a bug report.
4. Always provide `summary` and `description`.
5. For `Task` creation, include required `customfield_10275` (`Why`) in Atlassian Document Format. Do not send `Why` for `CRI` `Bug` creation; that create screen rejects it.
6. For `Bug` or `Bug staging`, shape the description with context, actual behavior, expected behavior, environment/scope, and reproduction steps. Use the bug payload examples in `references/board-defaults.md`.
7. Add optional product/product-area/component hints only when strongly implied by the target board or request.
8. Check the returned status.
9. If the user asked for `To Do` and Jira created the card in `Backlog`, transition with id `11`.
10. Return the issue key, link, title, and final status.

## Defaults

Use these values for all three boards:

- Cloud ID: `82b5fe1b-d904-46bb-a485-32f01e7ea2d7`
- Site: `https://crisalix.atlassian.net`
- Default issue type: `Task`
- Required `Why` field for Task creation: `customfield_10275`, ADF document
- `To Do` transition id: `11`
- `Backlog` transition id: `111`

Known boards:

- `ENG`: `3ngine 3D`, project ID `10190`, board `88`
- `CORE`: `CORE (engine + DL)`, project ID `10181`, board `88`
- `CRI`: `Crisalix`, project ID `10179`, board `85`

## Required Fields

When setting `Why`, always encode it as ADF:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "Reason this work matters."
        }
      ]
    }
  ]
}
```

Known exception: do not send `customfield_10275` for `CRI` `Bug` creation unless fresh metadata confirms it is on the create screen.

## Content Shape

When the user provides rough context, turn it into:

- A concise summary.
- A description with context, problem/feedback, goal, and acceptance criteria.
- For bug reports, include actual behavior, expected behavior, environment/scope, and reproduction steps.
- A short `Why` field focused on user, product, reliability, or delivery impact only for issue types that accept or require `Why`.

Ask a follow-up only when the target project is ambiguous or the requested card would be misleading without one.

## Failure Handling

If creation fails with a required field error, fetch create metadata only for the requested project and issue type, update `references/board-defaults.md` after confirming the new field shape, and retry.
