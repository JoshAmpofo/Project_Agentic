---
name: content-agent
description: Use when the user wants to generate social media content (LinkedIn, X, Facebook) for an industry/niche, plan a week of posts, or draft a Medium article. Supports an optional post count (--count, default 5) and a platform bias (--platform). Plans before generating via a planning subagent; no API/LLM calls — Claude is the engine. Triggers on "content agent", "generate posts for <niche>", "generate N posts", "linkedin posts for <niche>", "draft a medium post", "plan my social content".
---

# Content Agent

Generate planned, platform-formatted social content for a niche. Claude Code is the
generation engine — **never** call an external model or API. The only networked action is
the `refresh` mode.

## Mode routing

Read the arguments. Route by the first token:
- `refresh` → **Refresh mode**
- `medium`  → **Medium mode**
- anything else (or empty) → **Weekly plan mode**

If arguments are empty in weekly mode, ASK the user for the niche before continuing.

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

### Flags (weekly plan mode only)

Parse these flags out of the arguments before treating the rest as the niche:

- `--count N` — how many posts to generate. **Default: 5.** Clamp to 1–20; if the user
  asks for more than 20, cap it and tell them. A count of 0 or negative is invalid — ask
  for a real number.
- `--platform <name>` — bias the mix toward one platform. Accept `linkedin`, `x` (also
  `twitter`), `facebook` (case-insensitive). If given, that platform should get the
  **majority** of posts while the others still appear (cross-platform reach is preserved).
  If omitted, the planner decides the whole mix from the topic.

Everything left after removing the flags is the niche. Example:
`fintech --count 7 --platform linkedin` → niche `fintech`, count `7`, biased to LinkedIn.
Also accept the natural request if flags are absent but the user clearly states a number
or platform in prose (e.g. "3 posts") — map it to the same count/platform values.

---

## Weekly plan mode  (`/content-agent <niche>`)

1. **Ask the start date.** Ask the user which date to anchor the week to (e.g. "next
   Monday" or a specific date). Wait for the answer.
2. **Load research.** Slugify the niche. Look in this skill's `data/` directory (see
   *Runtime & file locations*). If `data/research-<slug>.md` exists, use it. Otherwise use
   `data/research-default.md` and remember to note the fallback in the plan.
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
4. **Validate the plan.** Confirm all four sections are present (Theme, Platform mix, N
   angles, Weekly schedule), the mix totals the requested POST COUNT, and each angle has
   Title/Platform/Hook type/Why. If a platform bias was requested, confirm that platform
   holds the majority (or, when the count is too small for a clear majority, at least the
   plurality) of posts. If invalid, re-dispatch the planner ONCE with an explicit note on
   what was missing. If still invalid, show the user the raw plan and ASK how to proceed —
   do NOT generate from a broken plan.
5. **Create the output folder.** `./content-output/<slug>-<YYYY-MM-DD>/`. If it already
   exists, append `-v2` (then `-v3`, …). Never overwrite.
6. **Write `00-PLAN.md`** containing the planner's full output verbatim. If the default
   research was used, prepend the line:
   `> (using default playbook — run /content-agent refresh <niche> for sharper data)`
7. **Generate the posts.** For each of the N angles, read `references/platform-playbook.md`
   and write one file `<platform>-NN.md` (e.g. `linkedin-01.md`, `x-04.md`,
   `facebook-03.md`), numbered per platform in schedule order. Each file follows the
   playbook's required structure. Every post traces to the theme.
8. **Summarize** to the user: the theme, the total count, the mix + rationale (including,
   if a bias was requested, why that platform carries the most posts for this topic), the
   schedule table, and the output folder path.

---

## Medium mode  (`/content-agent medium <topic>`)

Standalone. No planner, no daily-10.
1. Read `references/medium-guide.md`.
2. Write ONE long-form draft to `./content-output/medium-<slug>-<YYYY-MM-DD>.md`
   following the guide (title, subtitle, 3–5 sectioned body, read time, 5 tags).
3. Tell the user the file path.

---

## Refresh mode  (`/content-agent refresh [niche]`)

The ONLY networked action.
1. If no niche given, ask for one.
2. Do free web searches/fetches on what makes <niche> posts go viral on LinkedIn / X /
   Facebook right now. Use only public pages — no paid APIs.
3. Distill findings into the same structure as `data/research-default.md` and write
   `data/research-<slug>.md` (in this skill's `data/` directory), dated.
4. **If the fetch fails, there is no network, or your runtime has no web capability:**
   report it plainly and leave any existing cache untouched. Never overwrite good data with
   nothing. On a runtime without web access, tell the user refresh isn't available there and
   that weekly mode will use `data/research-<slug>.md` if present, else `data/research-default.md`.
5. Confirm to the user what was updated.

---

## Hard rules

- No external LLM/API calls in any mode except the web fetch in `refresh`.
- Weekly mode generates exactly POST COUNT angles (default 5, range 1–20). The mix totals
  that count. Absent a `--platform` bias, the planner decides the split from the topic;
  with a bias, that platform gets the most posts.
- Honor the spacing rules in the contract — never flood a feed.
- Never clobber existing output; suffix `-v2`/`-v3`.
