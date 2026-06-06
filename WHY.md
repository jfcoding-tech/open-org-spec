# Why open-org-spec

*Not a technical doc. This is for anyone asking "why would we do this?" before they're ready to read the getting-started guide.*

---

## The problem is not documentation

Most organisations have more documentation than anyone can read. Confluence pages, slide decks, recorded meetings, email threads with thirty-six messages and no clear owner.

That is not the problem. The problem is **legibility** — the difference between information that exists somewhere and information that is findable, current, relevant, and actionable by the right person at the right time.

An unlegible organisation runs on knowledge that lives in people's heads. Decisions get made in meetings and evaporate. A new joiner can't understand how the org works without scheduling a week of calls. The same cross-functional disagreement happens three times because nobody can find the resolution from the first two. When something breaks, the person who gets called isn't the one who was involved — it's the one who happens to remember.

This is not a people problem. It is a design problem. The knowledge that governs the organisation is invisible. It cannot be queried. It cannot be challenged. It cannot survive the people who carry it.

---

## What legibility is

A legible organisation has written itself down. Not exhaustively — that's the documentation trap. Precisely: the things that actually govern how work gets done.

Who owns this decision. What scope it covers. What was ruled out and why. Where the boundary is between this team and the next. What the current priorities are and what they're connected to.

Plain text. Version-controlled. Findable by anyone. Current because someone owns it.

That is the surface. It doesn't have to be complete to be useful. It compounds as it grows — each unit of specification makes the existing ones more valuable. Start with one scope, one owner, one decision. The system teaches you what to specify next.

---

## What becomes observable

Once the organisation is specified, six things become visible that weren't before:

- Who is accountable for what — by name, not by title
- Which decisions are open and how long they have been
- What is stale, unowned, or contradicting something else
- Where boundaries are being crossed before damage is done
- What the organisation is producing against what it decided to produce
- Where a change needs to go and who needs to know about it

Without the specification, none of this is observable. The leader is back to walking the org manually — meetings, conversations, asking around. You can only observe thinking if the thinking is recorded.

---

## What it looks like in practice

Not a description. A walk through the surface.

**A project anyone can follow without a status meeting.**

```
projects/pricing-model-v2/
  spec.md           ← objective, owner, close criterion
  updates.md        ← append-only progress ledger
  decisions/
    2026-03-12-drop-annual-tier.md
```

Anyone who wants to know where things stand reads `updates.md`. No Slack ping, no assembled deck, no meeting scheduled to get context.

**A cross-functional disagreement resolved in writing.**

```
growth/feedback.md

## 2026-04-24 | Rag → Alex — Ownership gap: attribution logic

Attribution is failing for edge cases in the B2B path.
This needs a decision before the Q2 release.

→ Alex

---

## 2026-04-26 | Alex → Rag — Re: attribution logic [resolved]

Decision: B2B attribution follows the rule in
decisions/2026-04-26-b2b-attribution.md.
```

Four days. Two people. No meeting. The resolution is findable forever — not in someone's inbox.

**A decision that answers a question nobody asked yet.**

```
decisions/
  2025-11-14-no-custom-auth-providers.md
```

A new engineer joins eight months later. Before writing a line of code she checks the system. The architectural decision is there — what was considered, what was ruled out, why. She doesn't reinvent the reasoning. She builds on it or proposes to change it with a counter-argument.

**A role spec so the next person mirrors the pattern.**

```
clusters/growth/cross-cluster-coordinator.md

**Owner:** Jamie Park
**Function:** Driver

Responsible for coordinating demand signals across clusters
before the monthly planning cycle.
```

When Jamie moves on, the next person doesn't start from scratch.

---

## Why AI makes this urgent

Everything above was possible before AI. What has changed is the economics — and the stakes.

AI operates on context. When the context is in the system — decisions recorded, owners declared, scopes defined — AI can run an analysis in twenty minutes that used to take a day. The cross-project risk analysis becomes a query, not a synthesis.

But the inverse is also true. Without a legible organisation, AI generates volume without intelligence. More output. Faster delivery. In whatever direction you were already pointing. The feedback loop that would have slowed you down — the friction, the rework, the visible failure — gets suppressed. By the time the impact surfaces, you are much further in the wrong direction.

The legible organisation is the synthesis layer. The spec is what gives AI enough to work with. Without it, AI doesn't make the organisation smarter. It makes it louder.

---

## The primitives argument

An organisation's governance is not a monolith. It is built from foundational elements — how decisions are made, how roles are declared, how feedback flows, how projects are tracked.

When those elements are written down and inherited by the scopes that depend on them, something changes. Change a foundational element and the update propagates through every scope built on top of it. Governance becomes explicit — lower scopes can add but not contradict; contradictions surface before they compound.

The open-org-spec capabilities are those foundational elements. Not a framework to adopt in full — primitives to activate one at a time, as the use case demands.

---

## Where to start

Find the decision that is governing your organisation but has never been written down. Write it down. Give it an owner. Make it findable.

That is the first unit of legibility. Everything compounds from there.

→ [`GUIDE.md`](./GUIDE.md) for how to get started.
→ [`README.md`](./README.md) for the technical overview.
