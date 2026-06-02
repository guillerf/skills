# Personal Agent Skills

This repository is the source of truth for personal skills installed into:

```text
/Users/guille/.agents/skills
```

Keep only authored custom skills here. Installed third-party skills, lock files, caches, and local agent state should stay outside this repository.

## Skills

- `crisalix-jira-card`: Create Jira cards in Crisalix ENG, CORE, or CRI boards with remembered defaults.

## Install Locally

Use symlinks from `/Users/guille/.agents/skills` to this repository so edits are versioned here and available to the agent immediately.

```bash
mkdir -p /Users/guille/.agents/skills
ln -s /Users/guille/development/skills/crisalix-jira-card /Users/guille/.agents/skills/crisalix-jira-card
```

If the skill already exists as a real directory, move or back it up before creating the symlink.

## Update Workflow

1. Edit skills in this repository.
2. Test them from the agent environment.
3. Commit and push changes.
4. Pull the repository on another machine and recreate the symlinks if needed.

## Notes

- Do not commit credentials, API tokens, `.env` files, or local machine state.
- Keep skill-specific reference material inside the relevant skill folder.
- Prefer one folder per skill, with its own `SKILL.md`.
