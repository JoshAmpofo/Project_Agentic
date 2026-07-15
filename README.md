# Project_Agentic

A marketplace of Claude Code agents/plugins I build. Right now it ships one plugin:

| Plugin | What it does |
|--------|--------------|
| [`content-agent`](./content_agent) | Plans and generates platform-formatted social content (LinkedIn, X, Facebook) for a niche, schedules a week of posts, and drafts Medium articles — with Claude as the generation engine, no external API calls. |

---

## Install

You need [Claude Code](https://claude.com/claude-code). Everything below is run from **inside** a Claude Code session.

**1. Add this repo as a plugin marketplace:**

```
/plugin marketplace add JoshAmpofo/Project_Agentic
```

**2. Install the content-agent plugin:**

```
/plugin install content-agent@project-agentic
```

That's it. Restart Claude Code (or run `/reload-plugins`) and the skill is live.

> Prefer clicking? Just run `/plugin`, open the **Discover** tab, find **content-agent**, and install it there.

### Updating later

When a new version is pushed:

```
/plugin marketplace update project-agentic
/reload-plugins
```

---

## Install on claude.ai (free & paid)

`content-agent` is a Claude **skill**, so it also runs on claude.ai — see
[`content_agent/INSTALL-claude-ai.md`](./content_agent/INSTALL-claude-ai.md).

- **Paid plans that allow custom skills:** download
  [`dist/content-agent-skill.zip`](./dist/content-agent-skill.zip) and upload it under
  **Settings → Capabilities → Skills**.
- **Free accounts (or any plan without skill uploads):** use the copy-paste block in the
  install guide — a self-contained, slightly degraded version that needs no upload.

---

## Using the content-agent

The plugin adds a `content-agent` skill. Claude triggers it automatically when you ask for
social content, or you can invoke it explicitly. It has **three modes**.

### 1. Weekly plan mode — the default

Generates a themed, scheduled set of posts across platforms.

```
generate posts for fintech
generate 7 linkedin posts for developer tooling
content agent: sustainable fashion --count 5 --platform x
```

- `--count N` — how many posts to generate. **Default 5**, clamped to 1–20.
- `--platform <linkedin|x|facebook>` — bias the mix so that platform gets the most posts
  (the others still appear, so you keep cross-platform reach). Omit it and the planner picks
  the best mix from the topic.

What happens:
1. Claude asks which **date** to anchor the week to.
2. A planning subagent produces a 4-part plan: theme, platform mix + rationale, the N post
   angles, and a spacing-aware weekly schedule.
3. Claude validates the plan, then writes everything to
   `./content-output/<niche>-<date>/` — a `00-PLAN.md` plus one copy-paste-ready file per
   post (`linkedin-01.md`, `x-04.md`, `facebook-03.md`, …).

### 2. Medium mode — one long-form draft

```
content agent medium: why small teams ship faster
```

Writes a single polished Medium draft (title, subtitle, sectioned body, honest read-time
estimate, 5 tags) to `./content-output/medium-<slug>-<date>.md`.

### 3. Refresh mode — sharpen the research (the only networked mode)

```
content agent refresh fintech
```

Does public web research on what's making `fintech` posts travel *right now* and caches it so
future weekly plans for that niche are sharper. If it can't reach the network it says so and
leaves any existing cache untouched.

---

## How it works (the short version)

- **Claude is the engine.** No external LLM or paid API is ever called — the only networked
  action anywhere is the web search in `refresh` mode.
- **Plan before generate.** A dedicated planning subagent designs the week under a strict
  contract (platform mix, hook types, spacing rules) before a single post is written.
- **Nothing gets clobbered.** Output folders are versioned (`-v2`, `-v3`) rather than
  overwritten.

Output always lands in `./content-output/` relative to wherever you're running Claude Code.

---

## Repo layout

```
Project_Agentic/
├── .claude-plugin/
│   └── marketplace.json          # marketplace manifest (lists the plugins)
├── content_agent/                # the plugin
│   ├── .claude-plugin/
│   │   └── plugin.json           # plugin manifest
│   ├── skills/
│   │   └── content-agent/
│   │       ├── SKILL.md          # skill instructions + mode routing
│   │       ├── references/       # planner contract, platform + medium guides
│   │       └── data/             # research cache (default + per-niche)
│   └── README.md                 # plugin-level docs
└── README.md                     # this file
```
