# Why open-org-spec

*Not a technical doc. This is for anyone asking "why would we do this?" before they're ready to read the getting-started guide.*

---

## 1. What a second brain is

A system outside your head that captures, organises, and surfaces what you'd otherwise forget or keep in private notes. Working memory stays free for thinking, not remembering.

The personal version is well known. What's less obvious is what happens when an organisation has one.

---

## 2. Why most organisations don't have one

Decisions live in someone's head, or in an email thread, or in a slide deck no one re-reads. New people can't catch up without scheduling calls. The same conversation happens three times because no one remembers the first two. AI tools can't help, because the context they need is locked in DMs, drives, and pasted screenshots.

The result: organisations operate from individual memory, not shared memory. Coordination cost grows with headcount.

---

## 3. From personal to organisational

Now imagine a second brain that isn't yours — it's the organisation's. Everyone contributes. Everyone reads.

Missions, decisions, projects, feedback, governance — one place, plain markdown, version-controlled. The knowledge is in the system, not in any one person.

When that person leaves, or joins, or goes on holiday, the organisation doesn't lose a week catching up.

---

## 4. What it looks like in practice

Not a description. A walk through the surface.

**A project anyone can follow without a status meeting.**

```
projects/pricing-model-v2/
  spec.md           ← objective, owner, close criterion
  updates.md        ← append-only progress ledger
  decisions/
    2026-03-12-drop-annual-tier.md
```

Anyone who wants to know where things stand reads `updates.md`. No Slack ping, no assembled deck, no meeting.

**A cross-functional disagreement resolved in writing.**

```
ai-factory/feedback.md

## 2026-04-24 | Rag → Alex — Ownership gap: attribution logic

[Rag] Attribution is failing for edge cases in the B2B path.
This needs a decision before the Q2 release.

→ Alex

---

## 2026-04-26 | Alex → Rag — Re: attribution logic [resolved]

Decision: B2B attribution follows the simplified rule in decisions/2026-04-26-b2b-attribution.md.
```

Five days. Three contributors. No meeting. The resolution is findable forever — not in someone's inbox.

**A role spec so the next person mirrors the pattern.**

```
clusters/growth/cross-cluster-coordinator.md

**Owner:** Jamie Park
**Function:** Driver

Responsible for coordinating demand signals across clusters before
the monthly planning cycle. Feeds into ai-factory/inbox.md by the
25th of each month.
```

When Jamie moves on, the next person doesn't start from scratch. The pattern is written down.

**A returning contributor oriented in seconds.**

```
$ /catchup

Last active: 12 days ago.
Since then: 3 decisions merged, 2 projects moved to in-progress,
1 feedback entry addressed to you in clusters/growth/feedback.md.

Top priority: decisions/2026-05-01-pricing-model-approved.md needs
your acknowledgement before implementation begins.
```

No reading every diff. No pinging someone to ask what changed.

---

## 5. Why now — and why AI makes this leverage

An organisational second brain is useful for humans alone. With AI, it becomes leverage.

An agent operating on a well-structured repo can:
- Orient a returning contributor in seconds
- Draft a spec for an owner's review rather than starting from a blank page
- Check whether a proposal conforms to governance automatically
- Surface stale decisions and non-conformant specs before they compound

*The person thinks. The agent checks.* That math only works if the knowledge lives in the system, not in someone's head.

The more the organisation writes down, the more useful the agent becomes. The more useful the agent becomes, the more the organisation writes down.

---

## What open-org-spec is

A lightweight standard for building this kind of surface. It defines the conventions — where things live, what they look like, how decisions are recorded — so that:

1. Any contributor can navigate without a guide
2. Any AI agent can operate without bespoke instructions
3. Any organisation can adopt it without starting from scratch

The standard is deliberately minimal and fog-of-war. You activate one convention when a real use case demands it, not the whole framework upfront. Start with one folder. Let it grow.

→ [`GUIDE.md`](./GUIDE.md) for how to get started.
→ [`README.md`](./README.md) for the technical overview.
