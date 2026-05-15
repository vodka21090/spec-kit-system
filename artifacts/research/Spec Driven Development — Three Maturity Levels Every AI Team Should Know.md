---
title: "Spec Driven Development — Three Maturity Levels Every AI Team Should Know"
source: "https://medium.com/@wasowski.jarek/spec-driven-development-three-maturity-levels-every-ai-team-should-know-648c93cf1e1d"
author:
  - "[[Jarosław Wasowski]]"
published: 2026-04-11
created: 2026-05-12
description: "Spec Driven Development is a maturity ladder — from CLAUDE.md (spec-first) through a living specification (spec-anchored) to code as a generated artifact (spec-as-source). Which rung does your team stand on?"
tags:
  - "clippings"
---
## Spec Driven Development is a maturity ladder — from CLAUDE.md (spec-first) through a living specification (spec-anchored) to code as a generated artifact (spec-as-source). Which rung does your team stand on?

If you use CLAUDE.md,.cursorrules, or AGENTS.md, you’re already practicing Spec Driven Development. You just don’t know what level you’re at yet. **Every team working with Claude Code, Cursor, or Copilot** uses specifications — just at the lowest rung of the maturity ladder.

It’s like handing a new employee a set of loose verbal instructions on day one. It works at first. After three months, nobody — including the AI — knows why the code does what it does.

The data is unambiguous: on large codebases, experienced developers work with AI **19% slower** than without it, while subjectively believing they’re 20% faster. Uncontrolled AI coding generates technical debt faster than any human developer in history. A significant portion of AI agent trajectories involve specification drift — the agent gradually diverging from the developer’s original intent.

> *“Nothing is as dangerous as an idea when it is the only idea you have.” — Emile Chartier (Alain), Philosopher*

## Table of Contents

- **Why vibe coding fails at scale** — specification drift as the formal mechanism of architectural context loss in AI agents
- **Specification as a machine contract** — four properties that distinguish a living specification from dead documentation
- **Three SDD maturity levels** — spec-first, spec-anchored, spec-as-source with tools, empirical data, and a migration path for each
- **The strongest counterarguments** — why Kent Beck, Zaninotto, and The Bitter Lesson are partially right, and why SDD is heading the BDD path, not MDA
- **Your next step** — a maturity level audit and a concrete migration path starting Monday morning

Check out how to effectively manage context using SDD in my publication: [Managing Agent Context at Every Stage of the SDLC](https://medium.com/@wasowski.jarek/managing-agent-context-at-every-stage-of-the-sdlc-cdlc-sdd-cecd0d575064)

> *“Plans are useless, but planning is indispensable.” — Dwight D. Eisenhower, 34th President of the United States*

## Vibe Coding and the Bill for a Missing Contract

The term “vibe coding” originated as Andrej Karpathy’s tweet in February 2025 — a description of a mode where a developer “fully surrenders to the vibes” and accepts AI-generated code without review. A year later, Karpathy himself stepped back in favor of **“agentic engineering”** — acknowledging that uncontrolled delegation to AI isn’t sufficient.

The critique of vibe coding at scale is documented in independent measurements. A GitClear analysis covering **211 million lines of code** from 2020–2024 showed that **refactoring dropped by 60%**, code churn — lines changed within two weeks of being written — **rose from 3.1% to 5.7%**, and code duplication increased **eightfold**. AI generates code like “a temporary collaborator who doesn’t know the project.”

![Line chart showing three code quality metrics from 2020–2024: declining refactoring, rising code churn, and rising code duplication.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*vfScah2GKdziqmGR3q8E_A.png)

GitClear, 211 million lines of code: refactoring dropped 60%, code churn rose from 3.1% to 5.7%, code duplication 8x higher. The inflection point coincides with mass AI coding adoption.

### Specification Drift — The Formal Mechanism of Failure

This degradation has a formal name: **specification drift** — the phenomenon where an AI agent gradually diverges from the developer’s intent because that intent was never formalized in a file available at the moment of code generation. The agent optimizes for **local functional correctness**, not global architectural constraints. System architecture stays in the developer’s head; the agent starts from scratch every session.

Vibe coding isn’t laziness — it’s a rational response to immature 2024-era tooling. The problem is that most teams are stuck in this mode even though the tools have matured. If vibe coding fails, what should replace it — and why isn’t the answer the same document that was rotting on SharePoint in 2015?

> *“A contract is a form of trust that doesn’t require trust.” — Niklas Luhmann, Sociologist*

## Specification as a Machine Contract — Four Properties of a Living Specification

The idea of “write the specification before the code” isn’t new. Design by Contract appeared in 1986. TDD — in 1999. BDD — in 2006 (formal publication; the concept dates to 2003). **SDD’s innovation doesn’t lie in the idea itself, but in four structural properties** that make a specification a living machine contract rather than a dead wiki document.

### Definition — Four Roles of a Single Artifact

**Spec Driven Development** — a methodology in which the specification is the primary artifact: a machine-readable contract from which implementation, tests, and documentation are derived. An SDD specification simultaneously serves four roles: **contract** (what AI is meant to produce), **steering document** (loaded into the agent’s context at the start of each session), **test oracle** (from which tests are derived), and **living document** (updated based on implementation).

These four roles translate into the structural properties of a **living specification** — one that evolves alongside the code:

1. **Versioned next to code in the repo** — the specification lives in the repository, not on Confluence or in Google Docs. Changes are visible in git history.
2. **Bidirectional updates** — when implementation reveals something the spec didn’t anticipate, the specification is updated. This is the fundamental difference from waterfall, where the spec was frozen before coding began.
3. **Machine-readable format** — Markdown, YAML, structured plain text. Not PDF, not slides, not Word.
4. **Feedback loop from production** — incidents, performance metrics, and user behavior feed back into specification updates.

**Bidirectionality** is what distinguishes SDD from waterfall. “Writing before coding” doesn’t mean “freezing before coding.” In waterfall, the specification was frozen and started rotting from day one of implementation. In SDD, new edge cases and architectural decisions discovered during coding flow back into the specification. Without this bidirectionality, specifications are “just fancy prompts.”

![Comparison diagram: on the left, dead documentation (unidirectional flow, drift), on the right, a living SDD specification (bidirectional flow with four properties).](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*fSXIiVk8sgLxCCMqy-Ul3Q.png)

Dead documentation vs. living SDD specification. The bidirectional feedback loop (spec and code) is the fundamental difference from waterfall — “writing before coding” doesn’t mean “freezing before coding.”

### Why a PRD from Confluence Isn’t Enough

This definition explains **why a PRD from Confluence isn’t an SDD specification** — it’s not machine-readable, it doesn’t live in the repo, it has no feedback loop. An SDD specification is a statement of work for the AI — clear deliverables, quality standards, success criteria. Vibe coding is a “verbal agreement.” And an AI agent remembers nothing between sessions.

CLAUDE.md satisfies conditions 1 and 3, but not 2 and 4. CLAUDE.md is just the first rung of the ladder.

> *“A journey of a thousand miles begins with a single step.” — Lao Tzu, Philosopher*

## Level 1 — Spec-First — You’re Already Here

Every team using CLAUDE.md,.cursorrules, or AGENTS.md **is already practicing SDD at the spec-first level**. Cross-session consistency, repeatable conventions, architectural constraints at every code generation step — the barrier to entry is zero.

**The spec-first workflow** across all tools: Constitution (non-negotiable principles) → Specify (requirements) → Plan (architecture) → Tasks (atomic units of work) → Implement (generation within contract boundaries). The specification serves as a “super-prompt” — providing context, but not maintained after a feature ships.

### Spec-First Tools — Who’s Building the First Rung

Three tools define Level 1 SDD in 2026. **GitHub Spec Kit** — an open-source CLI with slash commands (/specify, /plan, /tasks) and a constitution.md file for non-negotiable architectural principles. **Amazon Kiro** — the first dedicated IDE for SDD (a VS Code fork) using EARS notation: “WHEN \[trigger\], THE SYSTEM SHALL \[response\].” **spec-workflow-mcp** — an MCP server enforcing the sequence Requirements → Design → Tasks with explicit human approval at each stage.

![Comparison map of three spec-first SDD tools: GitHub Spec Kit, Amazon Kiro, and spec-workflow-mcp with key features and use cases.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*wygN5vdQIwPL4eX31khIHw.png)

Three tools defining Level 1 SDD. Spec Kit is a CLI for any agent. Kiro is the first dedicated IDE. spec-workflow-mcp is an MCP server with an approval dashboard.

Spec-first has a **technical limitation** I discovered in my own CLAUDE.md — confirmed by the IFScale benchmark. Even the best models achieve close to 100% adherence at 10 instructions, but drop to 68% at 500 simultaneous instructions. Weaker models degrade far more sharply — IFScale records single-digit drops at maximum instruction load. A CLAUDE.md over 200 lines — which is surprisingly easy to exceed — means a real adherence drop.

The spec-first specification has a fundamental weakness: **it’s abandoned after the feature ships.** At the next modification, the agent has no context for the previous architectural decision — and specification drift returns.

Spec-first solves the “agent doesn’t know the context” problem. It doesn’t solve the “specification rots after a week” problem. That requires Level 2 — and this is where the fundamental paradigm shift begins.

> *“Theory without practice is sterile, practice without theory is blind.” — Immanuel Kant, Philosopher*

## Level 2 — Spec-Anchored — The Breakthrough Moment

The move from Level 1 to Level 2 is **simultaneously the hardest and the highest-ROI adoption point in SDD**. At the spec-anchored level, the specification isn’t abandoned after implementation — it lives alongside the code, evolves with it, and serves as the source of truth for every modification. Specification and code evolve in tandem.

The strongest empirical evidence comes from the **SLUMP** benchmark — Faithfulness Loss Under Emergent Specification — measuring implementation faithfulness loss when requirements are provided incrementally in conversation rather than as a complete specification. Researchers tested leading agents on 20 complex ML implementations with 371 atomic components. When the specification “emerged” from conversation (60 incremental requests), agents lost faithfulness — forgetting earlier decisions, breaking integration between modules, hallucinating logic contradicting previous instructions.

### SLUMP — Evidence That One Structural Change Recovers 90% of Context

The key element of SLUMP: a mitigation mechanism called **ProjectGuard** — a persistent specification layer maintained outside conversation history. A single structural change — moving the specification from chat to a persistent file — recovered **90% of lost faithfulness**. The number of faithful components rose from 118 to 181.

Initially, I was skeptical of SDD — it looked like waterfall dressed up in Markdown. I changed my mind when I saw the SLUMP data. **Bidirectionality changes everything.** The specification isn’t frozen — it’s updated based on implementation. This distinguishes SDD from waterfall just as fundamentally as continuous integration distinguishes agile from cascading processes.

![Comparison diagram of two flows: spec-first (unidirectional, drift) vs. spec-anchored (bidirectional, 90% faithfulness recovery per SLUMP benchmark).](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*4CJ5zDpvEwC91QFGCEwLWQ.png)

Moving from Level 1 to Level 2 SDD: one structural change — pulling the specification out of conversation into a persistent, bidirectionally updated file — recovers 90% of lost implementation faithfulness (SLUMP benchmark).

### Constitutional SDD — Production Data

Data from **Constitutional SDD** applied in banking confirms this shift in practice. A Constitution — a file defining non-negotiable security principles (CWE/MITRE Top 25) — as a persistent element of the specification yielded a **73% reduction in security defects**, **56% faster time to first secure build**, and a **4.3x improvement in compliance documentation coverage**.

In multi-agent architectures, a living spec becomes an **inter-agent coordination protocol** — parallel agents read the same contract as their source of truth. Without a shared specification, they inevitably diverge.

Level 2 solves specification drift. It still requires a human to write and maintain the specification. But what if the specification were the only artifact a human edits — and code were generated automatically?

> *“The future is already here — it’s just not evenly distributed.” — William Gibson, Science Fiction Writer*

## Level 3 — Spec-as-Source — Code as a Byproduct

At the highest SDD maturity level, the specification is **the only artifact edited by a human**. Code carries the header “GENERATED FROM SPEC — DO NOT EDIT.” The developer’s role shifts from writing code to designing contracts.

### Tessl — $125M for the Vision of Code as an Artifact

**Tessl** — Guy Podjarny’s startup (creator of Snyk) — raised **$125 million at a valuation above $500 million** to pursue this vision. Two products: Tessl Framework (MCP-compatible) and **Tessl Spec Registry** — a system of versioned specification packages with over 10,000 usage specs for popular libraries, solving the problem of agents hallucinating API calls. Podjarny predicts that developers working with agents will soon spend most of their time not looking at code at all.

![Pyramid/staircase of three SDD maturity levels: spec-first (base), spec-anchored (middle), spec-as-source (peak) with definitions, tools, and metrics for each level.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*GW7Kre4IuiaXSVtSzeOQKA.png)

Three maturity levels of Spec Driven Development. Most teams stand at Level 1 (CLAUDE.md). Moving to Level 2 (living spec) delivers the greatest ROI. Level 3 (code as artifact) is the horizon.

Honesty about the historical context is required here. **Model-Driven Architecture (MDA)** from 2001 promised the same thing — models as the primary artifact, automatic code generation. Its failure: abstraction impedance, tooling lock-in, and a steep competency barrier. Martin Fowler called MDA “Night of the Living Case Tools.”

Why it might be different this time: Markdown instead of UML, the MCP standard instead of vendor lock-in, iteration costs dropped from months to minutes. A high error rate on complex compositional specifications warns against rushing in, however. Spec-as-source is a horizon — not a starting point. Level 2 is the realistic goal for 2026.

> *“History doesn’t repeat itself, but it rhymes.” — Mark Twain, Writer*

## The Debate — The BDD Path or the MDA Path

Three levels of SDD provide a clear ladder. The strongest critics of this ladder have **serious arguments** — and an honest analysis requires engaging with them. SDD stands at a crossroads: it can follow the BDD path (lightweight, iterative, mainstream since 2006) or the MDA path (heavy, ceremonial, effectively dead after 2010).

### The Strongest Counterarguments — Beck, Zaninotto, Sutton

**Kent Beck**, creator of TDD and an Agile Manifesto signatory: “The descriptions of Spec-Driven Development I’ve seen emphasize writing a complete specification before implementation. That encodes a peculiar assumption that you won’t learn anything during implementation.” This critique lands on spec-first (Level 1) — but misses spec-anchored (Level 2), where implementation explicitly feeds back into the specification.

**François Zaninotto**, CEO of Marmelab, tested SDD tools and generated 8 files and 1,300 lines of text just to display a date in a time-tracking application. Seven practical problems: context blindness, markdown madness, systematic bureaucracy, faux agile, double code review, a false sense of security (agents mark tests as done without writing them), and diminishing returns on brownfield projects. These are real problems, not a straw man.

**The Bitter Lesson** — an observation by Rich Sutton, one of the fathers of reinforcement learning — states that general methods exploiting computational scale have historically beaten hand-crafted rules. Specifications are rules. Rules are a ceiling. If SDD tries to micromanage every variable, it becomes an inefficient, bloated programming language — and dies like MDA.

![Crossroads diagram: SDD at the center with two diverging paths — the BDD path (success, lightweight) and the MDA path (failure, heavyweight) with deciding factors.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*Uru-vYysPNBG3xvIZAyD5A.png)

SDD’s fate depends on which path it takes: lightweight and iterative like BDD (successful since 2006) or heavy and ceremonial like MDA (failed after 2008). Key factors: specification format, overhead, and feedback loop speed.

## The Alternative and the Necessary Condition

An alternative exists: Obie Fernandez built 13,000 lines of production code with Claude Code + TDD. “TDD kept me in the loop — tests are a forcing function that compels you to understand what’s being built.” A real option — but TDD without a persistent architectural specification doesn’t scale to multi-agent architectures.

I believe SDD will follow the BDD path — not MDA — for three reasons: Markdown instead of UML eliminates the entry barrier, the MCP standard eliminates vendor lock-in, and iteration costs have dropped from months to minutes. The condition is non-negotiable: **the specification must define WHAT and BOUNDARIES, not HOW.** When a specification dictates implementation line by line, SDD dies — and The Bitter Lesson wins.

> *“Change is the end result of all true learning.” — Leo Buscaglia, Educator*

## Key Takeaways

The SDD maturity ladder provides **a clear navigational framework** — and most teams stand on the first rung, unaware of the two above it.

1. **If you use CLAUDE.md,.cursorrules, or AGENTS.md** — you’re already practicing SDD at Level 1 (spec-first). It’s a good start, but the specification rots after the feature ships.
2. **Moving to Level 2 (spec-anchored) delivers the greatest ROI.** SLUMP proves that a persistent specification with a feedback loop recovers 90% of lost implementation faithfulness. That’s one structural change with an enormous effect.
3. **Level 3 (spec-as-source) is the horizon.** Tessl ($125M) is aiming there, but production data is absent. Watch it, don’t adopt it.
4. **SDD is not waterfall** — the key difference is bidirectionality (spec updated based on implementation) and short feedback loops (minutes, not months).
5. **The strongest counterarguments are partially valid** — and they define the boundary: specify WHAT and BOUNDARIES, not HOW. When a specification micromanages implementation, SDD becomes heavyweight MDA.

## Your Next Step Starting Monday Morning

- **Audit:** check whether your CLAUDE.md defines architectural constraints (not just formatting). If not — start with constraints.
- **Tool:** pick one spec-first tool — GitHub Spec Kit, Amazon Kiro, or spec-workflow-mcp — and integrate it into your existing workflow.
- **Goal for Q2 2026:** migrate one project from spec-first to spec-anchored — the specification lives in the repo alongside the code, updated bidirectionally after every implementation.
- **Watch:** Tessl Spec Registry, DORA 2026 results, and the evolution of SWE-bench Pro with human-augmented specs.

![Summary infographic: the SDD ladder from vibe coding through three maturity levels with key empirical data and the BDD vs. MDA debate.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*rV0v6AzelHjqzEgHk1JmSg.png)

Spec Driven Development — from the chaos of vibe coding to the machine contract. Three maturity levels, key data, the central choice: the BDD path (success) or MDA (failure).

*To those who’ve made it this far — thank you for your time. If your team stands on the first rung of the SDD ladder, I have a concrete proposal: this week, pull the specification out of the conversation and into a persistent file in the repo.*