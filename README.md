# Personal Agent Skills

This repository is the source of truth for personal skills installed into:

```text
~/.agents/skills
```

Keep only authored custom skills here. Installed third-party skills, lock files, caches, and local agent state should stay outside this repository.

## Skills

- `crisalix-jira-card`: Create Jira cards in Crisalix ENG, CORE, or CRI boards with remembered defaults.

- `estetix-3d-simulator`: Work in Estetix staging instances and create Face, Breast, or Body reconstructions with photo and measurement defaults.

- `crisalix-buildkite-image`: Launch the core standalone or core_engine image build in Buildkite with the `bk` CLI, with branch, tag and message defaults from the core_engine checkout.

- `github-identity`: Perform authenticated GitHub work and pushes only as `guillerf`, verifying API identity, Git transport, and authorship of new resources.

## Global GitHub Identity Rule

`AGENTS.md` contains the GitHub identity requirement for all repositories. Install it as `~/.codex/AGENTS.md`, together with the `github-identity` skill, so the requirement is loaded even before skill selection. It requires `guillerf` and stops GitHub writes and pushes when that identity cannot be verified.

## Install Locally

Use symlinks from `~/.agents/skills` to this repository so edits are versioned here and available to the agent. Adjust the checkout path if it is not `~/development/skills`.

```bash
mkdir -p "$HOME/.agents/skills" "$HOME/.codex"
ln -s "$HOME/development/skills/crisalix-jira-card" "$HOME/.agents/skills/crisalix-jira-card"
ln -s "$HOME/development/skills/github-identity" "$HOME/.agents/skills/github-identity"
ln -s "$HOME/development/skills/AGENTS.md" "$HOME/.codex/AGENTS.md"
```

If a destination already exists, inspect and preserve it before installing. Merge the GitHub section into an existing global `AGENTS.md` rather than replacing unrelated instructions. Start a new Codex session to load new global instructions; this setup does not automatically update other computers.

## Update Workflow

1. Edit skills in this repository.
2. Test them from the agent environment.
3. Commit and push changes.
4. Pull the repository on another machine and recreate the symlinks if needed.

## Notes

- Do not commit credentials, API tokens, `.env` files, or local machine state.
- Keep skill-specific reference material inside the relevant skill folder.
- Prefer one folder per skill, with its own `SKILL.md`.
