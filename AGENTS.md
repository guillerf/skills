# Personal agent instructions

## GitHub identity — all repositories

- All authenticated GitHub work requested by Guille must use **`guillerf`** (Guillermo Ruiz / Guille Ruiz), including reads, pushes, pull requests, issues, reviews, comments, releases, Actions, and repository changes.
- For any GitHub or push request, read `~/.agents/skills/github-identity/SKILL.md` before acting and follow its identity checks. If that installation is missing, locate this repository's `github-identity/SKILL.md`; do not bypass verification.
- Use the local `gh` CLI. Never use the GitHub App/MCP connector or credentials belonging to `prcalopa` / Pere Calopa or another person for these requests.
- Before the first authenticated read and immediately before every GitHub write or push, verify `/user` through the effective credentials and require login `guillerf`. For pushes, also verify the actual Git SSH/HTTPS transport; a correct `gh` identity or Git author alone is insufficient.
- If the required identity or permissions cannot be verified, stop and report the blocker. Never continue as another account. Read newly created resources back to verify author `guillerf` and the requested state before reporting success.
