---
name: crisalix-buildkite-image
description: "Launch Crisalix Docker image builds in Buildkite with the bk CLI: the core standalone image (core_engine + core-app, entire pipeline) or the core_engine image. Fills the core_engine branch, tag and message from the conversation or the local core_engine checkout."
---

# Crisalix Buildkite Image

Launch image builds with the Buildkite CLI (`bk`). A request to build or launch one of these images authorizes creating that build: resolve the values, launch once, and report. Don't wait for the build; it takes 5–10 minutes.

## 1. Pick the pipeline

| Request | Pipeline | `-b` (build branch) | Env vars |
| --- | --- | --- | --- |
| core standalone image, standalone, entire pipeline, core-app standalone | `crisalix/build-core-app-standalone-image-entire-pipeline` | Not passed | `CORE_ENGINE_BRANCH`, `CORE_APP_BRANCH`, `TAG`, optional `CACHE_TAG` |
| core_engine image, core engine image | `crisalix/build-core-engine-image` | The core_engine branch | `CORE_ENGINE_BRANCH`, `TAG`, optional `CACHE_TAG` |

Ask if the request doesn't say which image ("imagen de core" alone is ambiguous).

Why the branches differ:
- **Standalone:** the pipeline's repository is core-app and its default branch is fine. Its first step triggers `build-core-engine-image` with `branch: ${CORE_ENGINE_BRANCH}`, and the core-app step checks out `CORE_APP_BRANCH`.
- **core_engine image:** the `docker/Dockerfile` copies the sources from the build's checkout, and `CORE_ENGINE_BRANCH` only ends up as an image label. Without `-b`, the image would contain `develop` labelled as another branch.

## 2. Resolve the values

For each value, use what the user said in the request, then what the conversation or working context establishes, then the default. Ask only when a required value can't be resolved.

| Value | Default |
| --- | --- |
| core_engine branch | The branch in context: the current repo or worktree when it is a core_engine checkout, or a core_engine branch you just pushed. Otherwise the active branch of `$CORE_ENGINE_DIR`. |
| core-app branch (standalone only) | `master` |
| `TAG` | The core_engine branch with every run of characters other than letters, digits, `_`, `.` and `-` replaced by `-`, leading `.` or `-` removed, at most 128 characters. |
| `CACHE_TAG` | Empty: don't pass it, and the pipelines use `latest`. Never send `CACHE_TAG=` with an empty value. |
| Message (`-m`) | The core_engine branch with hyphens replaced by spaces. |

`TAG` and the message follow the chosen core_engine branch, including one the user gave, unless the user also gave them. Example: `feature/idr-training` → `TAG=feature-idr-training`, message `feature/idr training`.

```bash
[ -n "$CORE_ENGINE_DIR" ] || source "$HOME/.crisalix_env" >/dev/null 2>&1
repo=$CORE_ENGINE_DIR   # or the core_engine checkout/worktree from the conversation
branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD)   # "HEAD" means detached: ask for the branch
tag=$(printf %s "$branch" | sed -E 's/[^A-Za-z0-9_.-]+/-/g; s/^[.-]+//' | cut -c1-128)
message=$(printf %s "$branch" | sed -E 's/-+/ /g; s/^ +| +$//g')
```

If `CORE_ENGINE_DIR` is still empty and no branch is in context, ask for the branch.

Validation:
- `TAG` and `CACHE_TAG` must match `^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$`. If the user gave an invalid one, propose the sanitized value and ask; don't change it silently.
- Branch names can't contain whitespace.
- Use `TAG=latest` only when the user asks for it and the core_engine branch is `develop`. The core_engine Makefile rejects `latest` on any other branch.

## 3. Check that GitHub has the branch

Buildkite builds what is on origin, not the local checkout. Run this in the core_engine checkout that holds the branch:

```bash
if git -C "$repo" fetch --quiet origin "$branch" 2>/dev/null; then
  remote_sha=$(git -C "$repo" rev-parse --verify --quiet "refs/remotes/origin/$branch")
  local_sha=$(git -C "$repo" rev-parse --verify --quiet "refs/heads/$branch")
  [ -n "$local_sha" ] && git -C "$repo" rev-list --count "$remote_sha..$local_sha"   # unpushed commits
else
  echo "$branch is not on origin"
fi
git -C "$repo" status --porcelain --untracked-files=no   # only meaningful if $branch is checked out
```

- **Not on origin:** don't launch. Tell the user to push the branch, and push it only if they ask.
- **Unpushed commits:** ask whether to launch anyway or push first.
- **Uncommitted changes:** launch, and say in the report that they aren't in the image.

## 4. Launch

Run exactly one `bk build create`, with values quoted:

```bash
# Core standalone image
bk build create --yes --no-input -i \
  -p crisalix/build-core-app-standalone-image-entire-pipeline \
  -m "$message" \
  -e CORE_ENGINE_BRANCH="$branch" -e CORE_APP_BRANCH="$core_app_branch" -e TAG="$tag"

# core_engine image
bk build create --yes --no-input -i \
  -p crisalix/build-core-engine-image \
  -b "$branch" \
  -m "$message" \
  -e CORE_ENGINE_BRANCH="$branch" -e TAG="$tag"
```

Append `-e CACHE_TAG="$cache_tag"` only when the user gave a cache tag.

The user ran this command for the standalone image and it worked:

```bash
bk build create -p crisalix/build-core-app-standalone-image-entire-pipeline -m "cli test" -i -e CORE_ENGINE_BRANCH=develop -e CORE_APP_BRANCH=master -e TAG=cli-test
```

Flags:
- `-i` (`--ignore-branch-filters`) is required. The pipelines have "Build branches" disabled, and the API rejects builds without it with `422 Branches have been disabled for this pipeline`. The web "New Build" button skips that filter.
- `--yes --no-input` skips the `[Y/N]` prompt, which would otherwise hang a shell without a TTY.
- `-b` only for the core_engine image. The standalone build runs on its pipeline's default branch.
- No `-w`: it opens the browser. Add it only if the user asks to open the build.

`bk` prints the build URL on stdout.

## 5. Report

Give the build URL and the values sent: pipeline, `CORE_ENGINE_BRANCH`, `CORE_APP_BRANCH` (standalone), `TAG`, `CACHE_TAG` (or "not sent, uses latest") and the message. Add any warnings from step 3. Say the build takes 5–10 minutes, and don't describe the image as built.

## Follow-up commands

Use these only when the user asks to check, follow or cancel a build:

```bash
bk build view <number> -p crisalix/<pipeline>            # state and jobs
bk build watch <number> -p crisalix/<pipeline>           # blocks until the build finishes
bk build list -p crisalix/<pipeline> --limit 5           # recent builds
bk job log <job-id> --agent                              # a job's log, condensed for agents
bk build cancel <number> -p crisalix/<pipeline>          # only on request
```

## Failures

| Problem | What to do |
| --- | --- |
| `bk: command not found` | Ask before installing: `brew install buildkite/buildkite/bk@3` |
| `401` or another authentication error | Ask the user to run `bk auth login --org crisalix`, which is interactive and opens the browser. `bk auth status` shows the current session. |
| `422 Branches have been disabled` | `-i` is missing. |
| `404 No pipeline found` | Check the pipeline slug against the table in step 1. |
| Timeout, or no URL in the output | The build may already exist. Don't run `bk build create` again. Look for it with `bk build list -p crisalix/<pipeline> --limit 5`, and ask if it's still unclear. |

The Crisalix Buildkite Raycast extension (`CrisalixSA/raycast-extensions`, `extensions/buildkite`) launches the same pipelines with the same branch and tag rules. When a pipeline or variable changes, update both.
