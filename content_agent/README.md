# content-agent

A Claude Code plugin that plans and generates platform-formatted social content.

## Install

From inside a Claude Code session:

```
/plugin marketplace add JoshAmpofo/Project_Agentic
/plugin install content-agent@project-agentic
```

Then `/reload-plugins` (or restart Claude Code).

### On claude.ai (not Claude Code)

This skill also works on claude.ai. See **[INSTALL-claude-ai.md](./INSTALL-claude-ai.md)** —
upload [`../dist/content-agent-skill.zip`](../dist/content-agent-skill.zip) on a plan that
supports custom skills, or use the paste-in block on any account (including Free).

## Modes

| Mode | Trigger | Output |
|------|---------|--------|
| **Weekly plan** (default) | `generate posts for <niche>` | Themed, scheduled posts in `./content-output/<niche>-<date>/` |
| **Medium** | `content agent medium: <topic>` | One long-form draft `./content-output/medium-<slug>-<date>.md` |
| **Refresh** | `content agent refresh <niche>` | Updates the niche research cache (only networked mode) |

### Weekly plan flags

- `--count N` — number of posts (default **5**, range 1–20).
- `--platform <linkedin\|x\|facebook>` — bias the mix toward one platform.

```
generate 7 posts for fintech --platform linkedin
```

## Principles

- **Claude is the engine** — no external LLM/API calls (except the web search in `refresh`).
- **Plan before generate** — a planning subagent designs the week under a strict contract.
- **Never clobbers output** — folders are versioned `-v2`, `-v3`.

## Files

- `skills/content-agent/SKILL.md` — mode routing and workflow.
- `skills/content-agent/references/` — planner contract, platform playbook, Medium guide.
- `skills/content-agent/data/` — research cache (default fallback + per-niche).
