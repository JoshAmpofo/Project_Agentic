# content-agent as a cross-runtime skill — design

**Date:** 2026-07-15
**Status:** Approved

## Goal

Let people use `content-agent` on **claude.ai** (both paid accounts that can upload
custom skills, and free accounts that cannot), in addition to the existing Claude Code
plugin path. Also document that no special action is required to publish the plugin to
the Claude Code marketplace beyond a public GitHub repo.

## Key insight

`content-agent` is already authored in the universal `SKILL.md` format consumed by both
Claude Code and claude.ai. The work is **not** a rewrite. It is:

1. Making the single `SKILL.md` **runtime-adaptive** so it degrades gracefully off Claude Code.
2. Adding a **packaging path** (a downloadable `.zip`) for claude.ai users whose plan allows skill uploads.
3. Adding a **paste-in fallback** for users who cannot upload custom skills (e.g. free tier).

Single source of truth: the existing `content_agent/skills/content-agent/SKILL.md`.
The zip and paste-in doc are generated from / point at that same folder — no divergent copies.

## Marketplace question (documentation only)

Claude Code plugin marketplaces are decentralized. A **public** GitHub repo containing a
valid `.claude-plugin/marketplace.json` *is* a working marketplace — there is no central
registry to submit to and no approval process. The repo already satisfies this. The only
optional extra is listing the repo in community directories for discoverability. This will
be stated in the README; no code change is required.

## Changes

### A. `SKILL.md` runtime-adaptive edits (single file, no behavior change on Claude Code)

1. **Planning step (weekly mode, step 3).** Replace the hard requirement to "dispatch the
   planning subagent (ONE) using the Agent/Task tool" with a capability check:
   - If the runtime supports subagents (Agent/Task tool), dispatch ONE planning subagent
     with `references/planner-contract.md` as today.
   - Otherwise, perform the planning **inline** as an explicit, self-contained step using
     the same contract — produce the full 4-section plan before writing any post.
   - The validation gate (four sections present, mix totals the count, bias majority
     honored) is unchanged and applies to both paths.

2. **File paths.** Replace hardcoded `~/.claude/skills/content-agent/data/...` references
   with **discovery relative to `SKILL.md`**:
   - Locate `data/` and `references/` relative to the skill root (Claude Code: under the
     plugin/skills path; claude.ai: alongside the unpacked skill in the working directory).
   - The `refresh` write target becomes "the same `data/` directory research was loaded
     from," not an absolute `~/.claude` path.

3. **Refresh mode graceful degrade.** Attempt web research; if the runtime has no
   fetch/web capability, say so plainly and fall back to `data/research-default.md`. Never
   overwrite a good cache with nothing (extends the existing principle).

### B. Packaging — build script + committed zip

- Add `scripts/build-skill-zip.sh`: zips `content_agent/skills/content-agent/` into the
  claude.ai-expected layout — a single top-level folder `content-agent/` containing
  `SKILL.md`, `references/`, and `data/`. Output: `dist/content-agent-skill.zip`.
- **Commit** `dist/content-agent-skill.zip` so claude.ai users download it directly from
  GitHub with no tooling.
- Script is idempotent / re-runnable to regenerate the zip after `SKILL.md` changes.

### C. Paste-in fallback (any tier, incl. free)

- Add `content_agent/INSTALL-claude-ai.md` with two sections:
  1. **Upload path** (plans that allow custom skills): download
     `dist/content-agent-skill.zip` → claude.ai Settings → Capabilities → Skills → upload.
  2. **Paste-in path** (any tier): create a claude.ai **Project**, paste the skill's
     routing instructions into the Project's custom instructions. Because paste-in cannot
     carry a file tree, the planner contract and platform playbook are **inlined/summarized**
     into the paste block so it works self-contained — a degraded but functional mode. The
     doc states this tradeoff plainly.

### D. Docs

- Root `README.md` and `content_agent/README.md`: add an **"Install on claude.ai (free &
  paid)"** section pointing at the zip and `INSTALL-claude-ai.md`.
- README also states the marketplace answer: a public repo is all that's needed for Claude
  Code users.

## Out of scope (YAGNI)

- GitHub Releases automation.
- CI to auto-rebuild the zip.
- Any change to the actual content-generation logic (weekly/medium/refresh behavior stays
  the same aside from the adaptive edits above).

## Success criteria

- The same `SKILL.md` works when loaded as a Claude Code plugin skill AND when uploaded to
  claude.ai (planning degrades to inline; paths resolve; refresh degrades gracefully).
- `scripts/build-skill-zip.sh` produces `dist/content-agent-skill.zip` with the correct
  top-level `content-agent/` layout.
- `dist/content-agent-skill.zip` is committed and downloadable from GitHub.
- `content_agent/INSTALL-claude-ai.md` documents both upload and paste-in paths.
- READMEs updated with the claude.ai install section and the marketplace clarification.
