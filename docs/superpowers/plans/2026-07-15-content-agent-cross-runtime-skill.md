# content-agent Cross-Runtime Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing `content-agent` skill usable on claude.ai (paid upload + free paste-in) in addition to Claude Code, by making one `SKILL.md` runtime-adaptive and adding packaging + install docs.

**Architecture:** Single source of truth is `content_agent/skills/content-agent/SKILL.md`. Three surgical edits make it degrade gracefully off Claude Code (inline planning fallback, relative path discovery, refresh graceful-degrade). A build script zips the skill folder into the claude.ai layout at `dist/content-agent-skill.zip` (committed). A new `INSTALL-claude-ai.md` documents upload + paste-in paths. READMEs get a claude.ai section and a marketplace clarification.

**Tech Stack:** Markdown, Bash (`zip`), git. No code, no test framework — verification is done via shell assertions (grep, unzip -l, python json.tool).

## Global Constraints

- Single source of truth: edit the existing `content_agent/skills/content-agent/SKILL.md` — do NOT create a second divergent copy of the skill.
- Claude Code behavior must not change: the subagent-dispatch path stays the default when the Agent/Task tool exists; only the fallback and path-discovery wording is added.
- The zip's internal layout MUST have exactly one top-level folder `content-agent/` containing `SKILL.md`, `references/`, `data/`.
- Committed artifact path is exactly `dist/content-agent-skill.zip`.
- Never overwrite a good research cache with nothing (existing refresh principle — preserve it).
- All work happens on a feature branch, not `main`.

---

### Task 0: Create the feature branch

**Files:** none (git only)

- [ ] **Step 1: Create and switch to the branch**

Run:
```bash
cd /home/reyes/Project_Agentic && git checkout -b feat/content-agent-claude-ai
```
Expected: `Switched to a new branch 'feat/content-agent-claude-ai'`

- [ ] **Step 2: Confirm branch**

Run: `git branch --show-current`
Expected: `feat/content-agent-claude-ai`

---

### Task 1: Make SKILL.md runtime-adaptive

**Files:**
- Modify: `content_agent/skills/content-agent/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: an adaptive SKILL.md that Task 2 zips verbatim and Task 4 references. The zip and paste-in doc depend on the phrase-level content added here (path discovery, inline planning fallback, refresh degrade).

This task makes three edits. Do all three, then verify, then commit once.

- [ ] **Step 1: Add a "Runtime & file locations" section**

Insert the following block immediately AFTER the `## Mode routing` section's last line (after the "If arguments are empty in weekly mode, ASK the user for the niche before continuing." line) and BEFORE `### Flags (weekly plan mode only)`:

```markdown

---

## Runtime & file locations

This skill runs on **Claude Code** and on **claude.ai**. Adapt to whichever you are:

- **Finding skill files.** `references/` and `data/` live inside this skill's own folder.
  Locate them relative to this `SKILL.md`, not at a hardcoded absolute path. On Claude Code
  that folder is under the installed plugin/skills path; on claude.ai it is alongside the
  unpacked skill in the working directory. If you cannot find a file after checking the
  skill folder and the current working directory, tell the user which file is missing
  instead of guessing a path.
- **Subagents.** Some steps below prefer a planning subagent. If your runtime provides an
  Agent/Task tool, use it. If it does not (e.g. claude.ai), do that step INLINE as an
  explicit, self-contained step — same contract, same validation gate.
- **Web access.** Only `refresh` mode needs the network. If your runtime cannot fetch the
  web, say so and fall back to cached/default research (see Refresh mode).
```

- [ ] **Step 2: Rewrite the planning-subagent step to be adaptive**

Replace this exact text in the "Weekly plan mode" numbered list (step 3):

```markdown
3. **Dispatch the planning subagent (ONE).** Use the Agent/Task tool. Pass it: the niche,
   the full research text, the START DATE, the **POST COUNT** (from `--count`, default 5),
   the **PLATFORM BIAS** (from `--platform`, or "none — you decide the mix"), and the full
   contents of `references/planner-contract.md`. Instruct it to return ONLY the 4-section
   plan for exactly POST COUNT posts.
```

with:

```markdown
3. **Produce the plan under the planner contract (ONE planning pass).** The inputs are: the
   niche, the full research text, the START DATE, the **POST COUNT** (from `--count`, default
   5), the **PLATFORM BIAS** (from `--platform`, or "none — you decide the mix"), and the full
   contents of `references/planner-contract.md`.
   - **If your runtime has an Agent/Task tool:** dispatch ONE planning subagent with those
     inputs and instruct it to return ONLY the 4-section plan for exactly POST COUNT posts.
   - **If it does not (e.g. claude.ai):** do the planning INLINE as a distinct, self-contained
     step — read `references/planner-contract.md`, then produce ONLY the 4-section plan for
     exactly POST COUNT posts before writing any post. Do not start generating posts until the
     plan exists and passes validation.
```

- [ ] **Step 3: Replace hardcoded ~/.claude paths in weekly mode step 2**

Replace this exact text (weekly mode step 2):

```markdown
2. **Load research.** Slugify the niche. If
   `~/.claude/skills/content-agent/data/research-<slug>.md` exists, use it. Otherwise use
   `~/.claude/skills/content-agent/data/research-default.md` and remember to note the
   fallback in the plan.
```

with:

```markdown
2. **Load research.** Slugify the niche. Look in this skill's `data/` directory (see
   *Runtime & file locations*). If `data/research-<slug>.md` exists, use it. Otherwise use
   `data/research-default.md` and remember to note the fallback in the plan.
```

- [ ] **Step 4: Replace hardcoded ~/.claude path in refresh mode step 3 and add graceful degrade**

Replace this exact text (refresh mode):

```markdown
3. Distill findings into the same structure as `data/research-default.md` and write
   `~/.claude/skills/content-agent/data/research-<slug>.md`, dated.
4. **If the fetch fails / no network:** report it plainly and leave any existing cache
   untouched. Never overwrite good data with nothing.
```

with:

```markdown
3. Distill findings into the same structure as `data/research-default.md` and write
   `data/research-<slug>.md` (in this skill's `data/` directory), dated.
4. **If the fetch fails, there is no network, or your runtime has no web capability:**
   report it plainly and leave any existing cache untouched. Never overwrite good data with
   nothing. On a runtime without web access, tell the user refresh isn't available there and
   that weekly mode will use `data/research-<slug>.md` if present, else `data/research-default.md`.
```

- [ ] **Step 5: Verify all edits landed and no hardcoded paths remain**

Run:
```bash
cd /home/reyes/Project_Agentic && \
echo "--- hardcoded paths (expect 0) ---" && \
grep -c '~/.claude' content_agent/skills/content-agent/SKILL.md ; \
echo "--- adaptive markers (expect >=1 each) ---" && \
grep -c 'Runtime & file locations' content_agent/skills/content-agent/SKILL.md && \
grep -c 'do the planning INLINE' content_agent/skills/content-agent/SKILL.md && \
grep -c 'no web capability' content_agent/skills/content-agent/SKILL.md
```
Expected: first count is `0`; the three following counts are each `1` or more. (`grep -c` for a zero match exits non-zero — that is fine, the printed `0` is the assertion.)

- [ ] **Step 6: Commit**

```bash
cd /home/reyes/Project_Agentic && \
git add content_agent/skills/content-agent/SKILL.md && \
git commit -m "feat(content-agent): make SKILL.md runtime-adaptive for claude.ai

Add Runtime & file locations section, inline planning fallback when no
Agent/Task tool, relative data/ path discovery, and refresh graceful-degrade.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Build script + committed zip

**Files:**
- Create: `scripts/build-skill-zip.sh`
- Create (build output, committed): `dist/content-agent-skill.zip`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: the adaptive `SKILL.md` from Task 1 and the existing `references/` + `data/` dirs.
- Produces: `dist/content-agent-skill.zip` with top-level `content-agent/` folder. Task 3 (INSTALL doc) and Task 4 (READMEs) reference this exact path.

- [ ] **Step 1: Write the build script**

Create `scripts/build-skill-zip.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# Build the claude.ai-uploadable skill zip from the single source-of-truth skill folder.
# Output layout inside the zip: content-agent/{SKILL.md,references/,data/}
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/content_agent/skills/content-agent"
DIST="$REPO_ROOT/dist"
ZIP="$DIST/content-agent-skill.zip"
STAGE="$(mktemp -d)"

trap 'rm -rf "$STAGE"' EXIT

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "error: $SRC/SKILL.md not found" >&2
  exit 1
fi

mkdir -p "$DIST"
mkdir -p "$STAGE/content-agent"
# Copy SKILL.md plus the references/ and data/ directories, preserving structure.
cp "$SRC/SKILL.md" "$STAGE/content-agent/"
cp -R "$SRC/references" "$STAGE/content-agent/"
cp -R "$SRC/data" "$STAGE/content-agent/"

rm -f "$ZIP"
( cd "$STAGE" && zip -r -q "$ZIP" content-agent )

echo "built $ZIP"
( cd "$STAGE" && zip -sf "$ZIP" >/dev/null 2>&1 ) || true
echo "--- contents ---"
unzip -l "$ZIP"
```

- [ ] **Step 2: Make it executable and run it**

Run:
```bash
cd /home/reyes/Project_Agentic && chmod +x scripts/build-skill-zip.sh && ./scripts/build-skill-zip.sh
```
Expected: prints `built .../dist/content-agent-skill.zip` and a listing that includes `content-agent/SKILL.md`, `content-agent/references/planner-contract.md`, `content-agent/references/platform-playbook.md`, `content-agent/references/medium-guide.md`, `content-agent/data/research-default.md`.

- [ ] **Step 3: Verify the zip layout precisely**

Run:
```bash
cd /home/reyes/Project_Agentic && \
echo "--- top-level dirs (expect only content-agent/) ---" && \
unzip -l dist/content-agent-skill.zip | awk '{print $4}' | grep -E '^[^/]+/$' | sort -u && \
echo "--- SKILL.md present (expect 1) ---" && \
unzip -l dist/content-agent-skill.zip | grep -c 'content-agent/SKILL.md'
```
Expected: the only top-level dir line is `content-agent/`; SKILL.md count is `1`.

- [ ] **Step 4: Un-ignore the committed zip in .gitignore**

`.gitignore` currently ignores `dist/` (line 13). Git will not descend into an ignored
directory, so add an explicit exception. Append this block to the END of `.gitignore`:

```gitignore

# Exception: ship the claude.ai-uploadable skill zip (see scripts/build-skill-zip.sh)
!dist/
dist/*
!dist/content-agent-skill.zip
```

- [ ] **Step 5: Verify git now tracks the zip and nothing else under dist/**

Run:
```bash
cd /home/reyes/Project_Agentic && \
echo "--- zip is NOT ignored (expect empty output) ---" && \
git check-ignore dist/content-agent-skill.zip || echo "OK: not ignored" && \
echo "--- status shows the zip ---" && \
git status --porcelain dist/
```
Expected: first check prints `OK: not ignored`; status shows `?? dist/content-agent-skill.zip` (and no other dist/ entries).

- [ ] **Step 6: Commit**

```bash
cd /home/reyes/Project_Agentic && \
git add scripts/build-skill-zip.sh .gitignore dist/content-agent-skill.zip && \
git commit -m "feat(content-agent): add skill-zip build script and committed artifact

scripts/build-skill-zip.sh packages the skill into the claude.ai layout
(top-level content-agent/). Commit dist/content-agent-skill.zip via a
.gitignore exception so users download it straight from GitHub.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: claude.ai install doc (upload + paste-in)

**Files:**
- Create: `content_agent/INSTALL-claude-ai.md`

**Interfaces:**
- Consumes: `dist/content-agent-skill.zip` (Task 2), the routing rules + contract text from `SKILL.md`, `references/planner-contract.md`, `references/platform-playbook.md`.
- Produces: the doc that Task 4's README section links to.

- [ ] **Step 1: Write the install doc**

Create `content_agent/INSTALL-claude-ai.md` with exactly this content:

````markdown
# Use content-agent on claude.ai

`content-agent` is a Claude **skill**, so it works on claude.ai too — not just Claude Code.
Pick the path that matches your account.

## Path A — Upload the skill (plans that support custom skills)

If your claude.ai plan lets you add custom skills (this has generally required a paid plan
— Pro/Max/Team/Enterprise — with the code-execution / files capability enabled):

1. Download **[`dist/content-agent-skill.zip`](../dist/content-agent-skill.zip)** from this repo.
2. In claude.ai go to **Settings → Capabilities → Skills** (wording may vary).
3. **Upload** the zip. It contains a single `content-agent/` folder with `SKILL.md`,
   `references/`, and `data/` — everything the skill needs.
4. Start a chat and ask for content, e.g. *"generate 5 linkedin posts for fintech"*.

This is the full-fidelity path: the reference files and research cache travel with the skill,
and planning/refresh work exactly as documented in the skill.

## Path B — Paste-in (any account, including Free)

If you can't upload custom skills, you can still run a self-contained version by pasting the
instructions into a claude.ai **Project** (or the start of a chat). Because pasted text can't
carry a file tree, the reference material is inlined below — this is a **degraded but working**
mode: no per-niche research cache and no subagent, but the same planning discipline and
formatting rules.

1. Create a new **Project** on claude.ai (or just paste this into a fresh chat).
2. Put the block below into the Project's **custom instructions**.
3. Then ask, e.g. *"generate 5 linkedin posts for fintech, anchored to next Monday"*.

---

### Paste this block

```text
You are a social content agent. When I ask for social posts for a niche, follow this exactly.

MODES (route by my request):
- "medium: <topic>" -> write ONE long-form Medium draft (title, subtitle, 3–5 sectioned
  body, honest read-time, 5 tags). Then stop.
- otherwise -> WEEKLY PLAN MODE below.

WEEKLY PLAN MODE:
1. If I didn't give a niche, ask for it. Ask which date to anchor the week to.
2. Read count/platform from my request. Default count = 5 (clamp 1–20). Optional platform
   bias = linkedin | x | facebook; if given, that platform gets the MOST posts but the
   others still appear.
3. PLAN FIRST (inline — do not write posts yet). Produce exactly these 4 sections for
   exactly <count> posts:
   1) Theme of the week — one connective sentence.
   2) Platform mix — "LinkedIn: n · X: n · Facebook: n" (totals = count) + one line of
      rationale for why that split fits THIS niche/audience. If I gave a bias, that
      platform gets the majority/plurality.
   3) The <count> angles — numbered; each has Title, Platform, Hook type (contrarian take,
      listicle, personal story, how-to, data-drop, myth-bust, behind-the-scenes, question),
      and one line "Why it travels".
   4) Weekly schedule — a table: Day | Date | Time | Platform | Post # | Title, anchored to
      my start date. Spacing rules: max 2 posts per platform per day; ≥1 day between posts
      on the same platform when count allows; when count ≥ 4 include one lighter day; spill
      into a 6th/7th day rather than putting 3+ of one platform on one day.
4. VALIDATE the plan (all 4 sections, mix totals the count, bias honored). Fix it if not.
5. GENERATE one post per angle, in schedule order. Formatting per platform:
   - LinkedIn: ~1300–1800 chars, short skim lines + whitespace, standalone hook before the
     ~210-char fold, one idea, soft CTA, 3–5 hashtags.
   - X: ≤280 chars; single post unless the idea needs a 3–7 tweet thread (render 1/, 2/…);
     0–2 hashtags; punchy first 7 words.
   - Facebook: 80–250 words, conversational/story-led, relatable opener, end on a genuine
     question; minimal/no hashtags.
   Each post: title, hook type, the copy-paste-ready body, and one line "why this travels".
   Every post must trace back to the theme.
6. Show me the theme, the mix + rationale, the schedule table, then all the posts.

Claude is the engine — never call an external API. Research is general best practice
(no live web cache in this pasted mode).
```

---

Want the sharper, file-backed experience (per-niche research cache, subagent planning, and
output written to files)? Use **Path A** above, or use the plugin in **Claude Code** (see the
main README).
````

- [ ] **Step 2: Verify the doc has both paths and the correct zip link**

Run:
```bash
cd /home/reyes/Project_Agentic && \
grep -c 'Path A' content_agent/INSTALL-claude-ai.md && \
grep -c 'Path B' content_agent/INSTALL-claude-ai.md && \
grep -c 'dist/content-agent-skill.zip' content_agent/INSTALL-claude-ai.md
```
Expected: each count is `1` or more.

- [ ] **Step 3: Commit**

```bash
cd /home/reyes/Project_Agentic && \
git add content_agent/INSTALL-claude-ai.md && \
git commit -m "docs(content-agent): add claude.ai install guide (upload + paste-in)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Update READMEs (claude.ai section + marketplace clarification)

**Files:**
- Modify: `README.md`
- Modify: `content_agent/README.md`

**Interfaces:**
- Consumes: `content_agent/INSTALL-claude-ai.md` (Task 3), `dist/content-agent-skill.zip` (Task 2).
- Produces: final user-facing docs. No task depends on this.

- [ ] **Step 1: Add a claude.ai section to the root README**

In `README.md`, immediately AFTER the "Updating later" subsection block (the fenced block
ending with `/reload-plugins` and before the `---` that precedes "## Using the content-agent"),
insert this new block:

```markdown

---

## Install on claude.ai (free & paid)

`content-agent` is a Claude **skill**, so it also runs on claude.ai — see
[`content_agent/INSTALL-claude-ai.md`](./content_agent/INSTALL-claude-ai.md).

- **Paid plans that allow custom skills:** download
  [`dist/content-agent-skill.zip`](./dist/content-agent-skill.zip) and upload it under
  **Settings → Capabilities → Skills**.
- **Free accounts (or any plan without skill uploads):** use the copy-paste block in the
  install guide — a self-contained, slightly degraded version that needs no upload.

> **Publishing note:** there's nothing special to do to "list" this on a Claude Code
> marketplace. A public GitHub repo containing `.claude-plugin/marketplace.json` *is* a
> marketplace — users just `/plugin marketplace add JoshAmpofo/Project_Agentic`. No central
> registry, no submission, no approval.
```

- [ ] **Step 2: Add a claude.ai note to the plugin README**

In `content_agent/README.md`, immediately AFTER the install fenced block (the one ending with
`Then `/reload-plugins` (or restart Claude Code).`) and BEFORE `## Modes`, insert:

```markdown
### On claude.ai (not Claude Code)

This skill also works on claude.ai. See **[INSTALL-claude-ai.md](./INSTALL-claude-ai.md)** —
upload [`../dist/content-agent-skill.zip`](../dist/content-agent-skill.zip) on a plan that
supports custom skills, or use the paste-in block on any account (including Free).

```

- [ ] **Step 3: Verify both READMEs updated**

Run:
```bash
cd /home/reyes/Project_Agentic && \
grep -c 'Install on claude.ai' README.md && \
grep -c 'Publishing note' README.md && \
grep -c 'INSTALL-claude-ai.md' content_agent/README.md
```
Expected: each count is `1` or more.

- [ ] **Step 4: Commit**

```bash
cd /home/reyes/Project_Agentic && \
git add README.md content_agent/README.md && \
git commit -m "docs: document claude.ai install and marketplace publishing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Final end-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Rebuild the zip from the final SKILL.md and confirm it's current**

Run:
```bash
cd /home/reyes/Project_Agentic && ./scripts/build-skill-zip.sh && \
git status --porcelain dist/
```
Expected: build succeeds; `git status --porcelain dist/` prints nothing (the committed zip already matches the freshly built one — if it prints a change, `git add dist/content-agent-skill.zip` and amend/commit).

- [ ] **Step 2: Validate both manifests are still valid JSON**

Run:
```bash
cd /home/reyes/Project_Agentic && \
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null && echo "marketplace.json OK" && \
python3 -m json.tool content_agent/.claude-plugin/plugin.json >/dev/null && echo "plugin.json OK"
```
Expected: `marketplace.json OK` and `plugin.json OK`.

- [ ] **Step 3: Confirm the extracted zip skill is self-consistent (no ~/.claude paths)**

Run:
```bash
cd /home/reyes/Project_Agentic && tmp="$(mktemp -d)" && \
unzip -q dist/content-agent-skill.zip -d "$tmp" && \
echo "--- files in zip ---" && find "$tmp/content-agent" -type f | sed "s|$tmp/||" && \
echo "--- hardcoded paths in zipped SKILL.md (expect 0) ---" && \
grep -c '~/.claude' "$tmp/content-agent/SKILL.md" ; rm -rf "$tmp"
```
Expected: file list includes `content-agent/SKILL.md`, all three `references/*.md`, and `data/research-default.md`; hardcoded-path count is `0`.

- [ ] **Step 4: Review the full commit set on the branch**

Run:
```bash
cd /home/reyes/Project_Agentic && git log --oneline main..HEAD
```
Expected: commits for the spec (if on branch), SKILL.md adaptive edits, build script + zip, install doc, and README updates.

---

## Self-Review

**Spec coverage:**
- Change A (SKILL.md adaptive: inline planning, path discovery, refresh degrade) → Task 1 ✓
- Change B (build script + committed zip) → Task 2 ✓ (incl. the `dist/` gitignore exception discovered during planning)
- Change C (paste-in fallback + upload doc) → Task 3 ✓
- Change D (READMEs + marketplace clarification) → Task 4 ✓
- Success criteria (same SKILL.md both runtimes; zip layout correct; zip committed & downloadable; INSTALL doc both paths; READMEs updated) → verified across Tasks 1–5 ✓

**Placeholder scan:** No TBD/TODO/"handle appropriately" — every file's full content is inlined; every verification step has an exact command and expected output.

**Type/name consistency:** Artifact path `dist/content-agent-skill.zip` and top-level folder `content-agent/` are used identically in Tasks 2, 3, 4, 5. Script name `scripts/build-skill-zip.sh` consistent throughout. Doc name `content_agent/INSTALL-claude-ai.md` consistent in Tasks 3 and 4.
