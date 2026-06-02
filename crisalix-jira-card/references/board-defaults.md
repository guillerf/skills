# Crisalix Jira Board Defaults

Use this reference for fast Jira card creation in the common Crisalix boards.

## Atlassian

- Cloud ID: `82b5fe1b-d904-46bb-a485-32f01e7ea2d7`
- Site URL: `https://crisalix.atlassian.net`

## Boards And Projects

| Key | Project name | Project ID | Board URL |
| --- | --- | --- | --- |
| `ENG` | `3ngine 3D` | `10190` | `https://crisalix.atlassian.net/jira/software/c/projects/ENG/boards/88` |
| `CORE` | `CORE (engine + DL)` | `10181` | `https://crisalix.atlassian.net/jira/software/c/projects/CORE/boards/88` |
| `CRI` | `Crisalix` | `10179` | `https://crisalix.atlassian.net/jira/software/c/projects/CRI/boards/85` |

## Issue Types

All three projects support:

- `Task`, issue type ID `10002`
- `Story`, issue type ID `10001`
- `Bug`, issue type ID `10004`
- `Bug staging`, issue type ID `10100`
- `Epic`, issue type ID `10000`
- `Spike`, issue type ID `10212`

Default to `Task` unless the user explicitly asks for another type.

Use `Bug` when the user clearly reports broken behavior in production-like context. Use `Bug staging` only if the user specifically says it is a staging bug or asks for that issue type.

## Required Fields

For `Task` creation in `ENG`, `CORE`, and `CRI`, the required fields are:

- `summary`
- `description`
- `issuetype`
- `project`
- `customfield_10275` (`Why`)

For `CRI` `Bug` creation (`Bug`, issue type ID `10004`), the create screen requires:

- `summary`
- `issuetype`
- `project`

Always still provide a useful Markdown `description`. Do not send `customfield_10275` (`Why`) for `CRI` `Bug` creation; Jira rejects it because it is not on that create screen.

`customfield_10275` must be sent as Atlassian Document Format:

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

## Status And Transitions

- `Backlog` status ID: `10100`
- `To Do` status ID: `10000`
- `To Do` transition ID: `11`
- `Backlog` transition ID: `111`

If the user asks for a card in `To Do`, create the issue first, then transition with id `11` if the returned status is `Backlog`.

## Optional Fields

### Product Area

Field: `customfield_10557`

Common option IDs:

- `3D Simulator`: `10642`
- `Business Platform`: `10643`
- `Patient App`: `10644`
- `Website (crisalix.com)`: `10645`
- `APIs`: `10647`
- `CRM`: `10639`
- `Partners`: `10640`
- `Alix AI`: `10705`
- `VR`: `10706`
- `AI Chatbots`: `10969`

For ENG simulator work, set `3D Simulator` when clearly applicable. For CORE or CRI, set this only when the area is obvious from the request.

For CRI bugs about saved simulations, simulation loading, viewer state, or before/after simulation behavior, `3D Simulator` is usually appropriate.

Payload:

```json
{
  "customfield_10557": [
    {
      "id": "10642"
    }
  ]
}
```

### Product

Field: `customfield_10192`

Common option IDs:

- `DoctorApp`: `10279`
- `PatientApp`: `10280`
- `CRM`: `10281`
- `Corporate website`: `10286`
- `AR`: `10353`
- `Data Manager`: `10340`
- `Galderma`: `10295`
- `Natrelle`: `10296`
- `Core web-service (Core/DL)`: `10285`
- `SSO`: `10383`
- `Public API`: `10404`

For CORE cards, `Core web-service (Core/DL)` may be appropriate when the request is about core engine or DL work. Do not set product if unsure.

For CRI iPad app or patient-profile issues, use `DoctorApp` when the flow is the clinician app/patient profile. Use `PatientApp` only when the user clearly means the patient-facing app.

### Components

Field: `components`

Useful CRI component IDs for bug routing:

- `DoctorApp (outside viewer)`: `10423`
- `DoctorApp (viewer)`: `10419`
- `PatientApp`: `10424`

Set components only when the request clearly identifies the product area.

## Task Create Payload Pattern

```json
{
  "cloudId": "82b5fe1b-d904-46bb-a485-32f01e7ea2d7",
  "projectKey": "CORE",
  "issueTypeName": "Task",
  "summary": "Short task title",
  "description": "Markdown description with context, goal, and acceptance criteria.",
  "additional_fields": {
    "customfield_10275": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Short impact statement."
            }
          ]
        }
      ]
    }
  }
}
```

Add product/product-area fields inside `additional_fields` only when useful and obvious.

## CRI Bug Create Payload Pattern

```json
{
  "cloudId": "82b5fe1b-d904-46bb-a485-32f01e7ea2d7",
  "projectKey": "CRI",
  "issueTypeName": "Bug",
  "summary": "Short bug title",
  "description": "Markdown description with context, actual behavior, expected behavior, scope, and steps to reproduce.",
  "additional_fields": {
    "components": [
      {
        "id": "10423"
      }
    ],
    "customfield_10192": [
      {
        "id": "10279"
      }
    ],
    "customfield_10557": [
      {
        "id": "10642"
      }
    ]
  }
}
```

Omit any optional routing field when it is not strongly implied. Do not include `customfield_10275` in this bug payload.
