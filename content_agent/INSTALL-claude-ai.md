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
