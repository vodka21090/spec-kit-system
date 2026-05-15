---
title: "Managing Agent Context at Every Stage of the SDLC — CDLC + SDD"
source: "https://medium.com/@wasowski.jarek/managing-agent-context-at-every-stage-of-the-sdlc-cdlc-sdd-cecd0d575064"
author:
  - "[[Jarosław Wasowski]]"
published: 2026-05-01
created: 2026-05-12
description: "How to manage LLM context in software development with AI across the SDLC using Specification Driven Development (SDD)."
tags:
  - "clippings"
---
## How to manage LLM context in software development with AI across the SDLC using Specification Driven Development (SDD).

Consider a typical failure sequence. Friday, 5:23 PM. An agent has been working for thirty-five minutes on a refactor of the invoicing module. It runs a grep that returns eight files. It edits file number four on the list — `payments_processor.py`. The diff looks fine. Code review takes seven minutes. The deploy goes clean. **At 2:14 AM, a production alert fires**: invoices aren't generating for new customers.

File number four wasn’t the file that needed changing. That was file number two, `invoices_generator.py`. File number four landed in the attention dead zone — the middle of a list of eight grep results — and the agent read it with degraded attention. After thirty-five minutes, the context window was 60% full, most of those tokens raw tool output from previous steps. This wasn't a bug in the model. It was **context debt** that materialized as broken code. Ward Cunningham named technical debt over thirty years ago; we now have a new class of debt — one that accumulates automatically while the team sleeps.

My thesis in this episode is simple. **Context for a coding agent is a finite, priceable engineering resource** — the same as CPU time, RAM, or a release budget. And it’s an **architecture**, not a file. It consists of a library of versioned Skills, a curated tool set, isolated subagents, preconfigured commands, and MCP servers — all the elements from which an agent in a ReAct loop decides for itself what to load at each SDLC step. Teams that understand this architecture get production-quality code from their agents.

## What You’ll Learn

- **Two independent degradation mechanisms** — Lost in the Middle (position) and context rot (time)
- **Four CDLC operations** — Generate, Evaluate, Distribute, Observe as a lifecycle
- **Three SDD levels and spec-as-code** — where the spec becomes an in-context learning artifact
- **Context architecture** — Skills, tools, subagents, commands, and MCP servers as a versioned per-phase SDLC library
- **ReAct patterns** — atomic tasks, parallel code+tests with verification, MCP+LSP instead of pasting files
- **Reality check** — where SDD helps, and where it just plays at helping

## Your Agent Edited the Wrong File Yesterday

The failure from the opening scene has two culprits — and they’re two *different* mechanisms, though engineers often confuse them.

The first is **Lost in the Middle** — the structural U-shaped attention bias in LLMs, where tokens at the start and end of the context window are systematically better retained than those in the middle. The attention curve looks like a smile: high at the beginning and end, sunken in the middle. In Liu et al.’s experiment on a question-answering task with twenty documents, model accuracy dropped from roughly 75% at position one to roughly 55% in the middle, then recovered to about 72% at the last position. In one scenario, the result was *below* the no-context baseline — the model performed better guessing than searching through a noisy list. This is a consequence of the transformer architecture: causal masking (each token sees only previous ones) and RoPE — positional encoding via rotational phases, with a tendency toward lower positional similarity at greater distances.

The second mechanism is **context rot** — and it works entirely differently. Lost in the Middle is a spatial problem (where a token sits in the window). Context rot is a temporal problem (how long the agent has been working). With each tool call, the conversation history grows: raw `grep` output, full stack traces, database JSON, compilation attempts and errors. After thirty minutes, the **signal-to-noise ratio** in the window drops exponentially. The model still reads everything — but attention gets diluted across the original instruction and hundreds of lines of operational chaff. The result: the agent loses the thread, drops architectural decisions from minute fifteen, and starts confidently producing plausible-but-wrong code.

A bigger model doesn’t save you. Chroma tested eighteen frontier models in 2025 — *all* of them degraded before the declared window limit. Degradation doesn’t wait for the window to fill — it starts with each increment of context length, well before the hard limit. **An engineer who understands both mechanisms audits an agent session by window fill percentage *and* by the age of the oldest critical artifact** — not by the vendor’s declared limit.

![Context window diagram with three attention zones: a high-attention beginning and end and a middle marked as a blind spot, where file number four out of eight grep results gets ignored by the agent.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*nguT9zGetA2HjGjd2i0XtQ.png)

Three attention zones in the context window: files in the middle of a grep list fall into the model’s blind spot — regardless of the declared window size.

## Context Debt — The Debt You Repay in Tokens and Broken Code

Technical debt accumulates when a developer cuts corners. **Context debt accumulates while the developer sleeps** — because the agent keeps working. It’s the compounding cost of outdated or contradictory context, parallel to technical debt, but accumulating automatically, without any conscious decision from the developer. **This is the first class of debt that breaks the assumption of deliberate human choice.**

The danger grows from three directions. The debt is invisible in DevOps metrics. It materializes as code that *passes review* — because it looks plausible. It grows while the team sleeps. In practice, I see four failure modes:

- **Retrieval Noise** (the agent found the right file but drowned in the middle),
- **Context Poisoning** (the agent treats untrusted PR comments as authoritative),
- **Context Dilution** (the correct signal is obscured by 50 semi-relevant documents),
- and **Context Leakage** (a security failure).

Three of the most chronically underestimated sources of debt are worth naming directly.

**Tool overload.** Every additional tool exposed to the agent isn't a free option — it's a description, parameter schema, and examples that consume tokens and simultaneously *expand the decision space*. Research from ETH Zurich found that with more than fifty MCP tools in a single session, agent tool-selection accuracy drops dramatically — the agent confidently uses the wrong tool when descriptions are similar. The practitioner loads a tool set per SDLC phase:

- **in the design phase,** `**read_file**` **+** `**glob**` **is enough;**
- **in implementation,** `**edit_file**`**,** `**run_tests**`**, and** `**format**` **get added;**
- **in deployment,** `**terraform_plan**` **and** `**kubectl_diff**` **get attached**.

Loading the full set of dozens of tools in every session is a recipe for confusion.

**Atomic tasks instead of monoliths.** A large, complex task — "build the authorization feature from scratch" — fills the context history in the first twenty minutes. The agent starts mixing up requirements and losing earlier decisions. A small atomic task — "generate the SQL migration for the `sessions` table" — completes at 5% window fill and can be repeated in a clean session. **Atomic decomposition isn't agile theater; it's a defense against context rot.** The BMAD method (a simplified Analyst → PM → Architect → SM → Dev → QA sequence — the full framework has dozens of specialized roles) explicitly enforces a chain of atomic roles, each in a clean context, with an explicit hand-off via an artifact file.

**Parallel code and tests with a verification gate.** A single agent writing both implementation *and* tests has a built-in confirmation bias — the tests will fit the code, even if both are wrong. Sub-agent A writes code from the specification, sub-agent B writes tests from *the same* specification, sub-agent C (the verifier) checks that the tests pass and that both artifacts match the spec. Each in a clean context. **This is a statistical safety net** — because every LLM call is a sample, not a deterministic output. Two independent implementations against a shared specification substantially reduce the probability that both pass verification if either is wrong.

Patrick Debois, Product DevRel Lead at Tessl and the father of the DevOps movement, named the lifecycle that pays down this debt the Context Development Lifecycle.

![Two comparison charts: technical debt accumulating with discrete developer decisions and context debt accumulating automatically while the agent works, with concrete numbers — 8× growth in code duplication and $18,000–90,000 monthly costs.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*21FvWy9bYH0uThCH8rQ2YA.png)

Technical debt grows with developer decisions. Context debt grows while the agent works at night — 8× more duplicated code blocks in 2024 vs 2020 is no accident.

## Four CDLC Operations: Generate, Evaluate, Distribute, Observe

DevOps took code that everyone treated like a loose file and wrapped it in tests, CI/CD, and monitoring. **CDLC does exactly the same thing with agent context.** Patrick Debois states the analogy directly: before DevOps, developers and operators had opposing incentives. CDLC is that same inflection point for teams working with AI agents — context isn't a file; it's an artifact with a release lifecycle.

Four operations map onto four DevOps disciplines:

- **Generate** is writing code. Translating tribal knowledge into explicit context — specs, Skills, gold paths, ADRs. Don't duplicate what the model already knows from training; fill the gaps between the model and *your* system.
- **Evaluate** is unit tests. **TDD-for-context.** Eval datasets running from fifty to two hundred task instances. Each failed evaluation is a specification you didn't write. The rule is simple: unmanaged context is unmanaged debt — until you measure it, you're flying blind.
- **Distribute** is versioned packages. Versioned Skills and command packages from a registry, distributed across teams as a dependency. Without a registry, context rots silently.
- **Observe** is telemetry. Where the agent asks questions — those are gaps in the context. Where it does the unexpected — those are ambiguities. Where the code works but doesn't reflect the intent — those are underspecified assumptions.

The loop closes into a **context flywheel** — an assumed system property where each operation informs the next. The practical takeaway: teams should start with **Evaluate**. Without a golden dataset of fifty representative tasks, the other three operations happen in the dark.

CDLC says *how* to manage context. SDD answers the second question: *what* should be in the artifact so the agent understands what it's building — and how that contract becomes an in-context learning resource at every subsequent SDLC phase.

![Cyclic diagram of the four CDLC stages: Generate, Evaluate, Distribute, Observe — with the parallel DevOps cycle alongside, showing that context engineering is the same lifecycle pattern applied to a new artifact.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*-08JpaIYJM6_aQ5C-w1LgQ.png)

The four CDLC operations form a flywheel: each informs the next, just like in DevOps. Without Evaluate, the other three happen in the dark.

### SDD and Spec-as-Code: Specification as In-Context Learning

Sean Grove of OpenAI put it bluntly in his presentation "The New Code" at AI Engineer World's Fair 2025: **code is ten to twenty percent of the value; the rest is structured communication**. Operationally, that means one thing — we're hiring the agent as a contract executor, not a syntax generator. Spec-Driven Development inverts the workflow: the specification is the source of truth, and code is its executable output.

SDD isn't a philosophy. It's a practical answer to the fundamental LLM constraint: non-determinism. The three SDD rigor levels are a decision map, not a quality hierarchy:

- **Spec-First** — spec written before code, allowed to drift after implementation. Use case: prototypes, AI-assisted initial development. Delivers 90% of the value at 10% of the cost.
- **Spec-Anchored** — spec maintained alongside code as an executable validation gate. A code change that diverges from the spec blocks the merge. Use case: production systems, long-lived projects.
- **Spec-as-Source** — humans only edit the spec, code is regenerated 1:1 with the marker `// GENERATED FROM SPEC — DO NOT EDIT`. Use case: embedded systems, OpenAPI server stubs, safety-critical code.

Here's the thing worth emphasizing: **spec-as-code only works if the spec lives inside the CDLC loop**. In Spec-Anchored, the spec becomes an executable validation gate — Generate produces the spec, Evaluate tests whether the code fulfills it, Distribute publishes the versioned spec to CI, Observe catches drift between the spec and actual production behavior. Without Evaluate, the spec becomes an aspirational document. Without Distribute, different teams stare at different versions.

In practice, an agent session receives the spec injected as **in-context learning**. This is exactly what Anthropic had in mind when they described LLMs as "in-context learners." Every well-crafted spec is a demonstration shot — concrete enough for the model to extract the pattern, general enough for the pattern to generalize.

Underneath all three levels sits the same artifact cascade: **Constitution → Spec → Plan → Tasks**.

- Constitution — non-negotiable architectural rules;
- Spec — testable requirements in EARS or Given/When/Then;
- Plan — ADRs and C4 diagrams in Mermaid;
- Tasks — atomic, sequenced units of work. EARS (`THE SYSTEM SHALL...` from Rolls-Royce, 2009) is becoming the standard because every WHEN/SHALL maps 1:1 to a test case.

### What You're Actually Injecting into the Agent: Skills, Tools, Subagents, Commands, MCP

Here we reach the operational core. **Context isn't a config file** — it's a versioned library of five artifact types from which an agent in a ReAct loop decides what to load at each step. Each type has its place in the architecture and its role per SDLC phase.

**Skills** are atomic procedural instructions — files describing *when* to do something, *how* to do it, and *what* artifacts to produce. A Skill is versioned like a library (`auth-patterns.md@v1.2`), carries metadata indicating which SDLC phase it targets, and is **lazy-loaded** — the agent in the reasoning phase of its ReAct loop decides whether to pull it into context. The practitioner writes the Skill `migration-jest-to-vitest.md` once, complete with preconditions, steps, verification, and out-of-scope notes; from then on, every session that encounters a Jest migration receives that Skill without any copy-pasting. **Without SDLC phase metadata, Skills become noise** — the agent loads a code review checklist into a draft-writing session.

**Tools and their definitions** are the second context type, and often the most underestimated. A tool isn't an "API call" — it's a **description** + parameter schema + usage examples, all communicated to the model in the prompt. Each additional tool description consumes tokens from the primacy zone and simultaneously creates another opportunity for selection confusion. Selective tool definition loading per SDLC phase — `read_file` + `glob` in design, `edit_file` + `run_tests` + `format` in implementation, `terraform_plan` + `kubectl_diff` in deployment — protects against tool overload. Tool definitions should also be versioned: updating an API schema requires a `bump`, because the agent learns parameter details from the description.

**Subagents** are the context isolation mechanism. Each subagent has its own system prompt, its own tool set, its own permissions, and — critically — a **fresh context window**. A research subagent explores the codebase with thousands of tokens, and returns a 1-2K summary to the main agent. A code-review subagent receives a diff + spec + checklist; it knows nothing about how the code was written, so it has no confirmation bias. **Subagents have a fixed context cost (definitions) and a variable gain (fresh context per task)** — and they're the primary defense against context rot.

**MCP servers** complete the architecture. The most interesting pattern is an **MCP server exposing an LSP (Language Server Protocol)**. Instead of pasting fifty files into context, the agent queries the LSP server: "give me the definition of the symbol `processInvoice` ", "find all usages of this class", "show me the type signature". The agent gets a **structural code graph** instead of source text. Token-efficient: instead of 50 files × 200 lines = 10,000 lines of context, the agent makes a dozen LSP calls returning exactly what it needs. This is "pointers > copies" in its purest form — and it's the foundation on which the agentic IDEs of 2026 (Cursor, Windsurf) are beginning to build.

**The ReAct loop with a conscious library.** In the reasoning phase of its loop, the agent decides which Skill to load, which subagent to spin up, which command to invoke, and which MCP server to query. The Constitution + active Spec occupy the primacy zone — always loaded. Everything else is a **library** — pulled on demand, according to SDLC phase metadata. **The architect-engineer designs that library and its metadata; the agent selects from it at runtime.**

This is exactly the matrix that most teams improvise every day — and one that can finally be designed once, audited, distributed, and measured. **The rest of this article assumes you have that architecture** — and in the reality check, I'll show where, even with it, SDD can do harm.

![Six SDLC phases mapped to artifacts, formats, optimal context-window zones, and common anti-patterns — a visual reference for auditing your current agent setup.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*ALP8exUYKvEwMddK3JIQDA.png)

Six SDLC phases, six context recipes. The same artifacts in different positions = dramatically different results — Faros AI measures a 35–40% reduction in style violations after moving AGENTS.md from the middle to the top.

## Reality Check — Where SDD Helps, Where It Just Plays at Helping

The recipe from the previous section isn't universal. The most common trap of 2026 is treating SDD as a religion. **It's an architectural choice per repository, even per feature** — and there's hard data to back that up.

Boris Cherny, lead of the Claude Code team at Anthropic, says it openly: PRDs are dead on his team — prototypes replaced them. The same team ships dozens of releases per day, with Claude Code writing 90% of the code, *without* PRDs. The signal isn't "SDD is bad," it's "SDD has its domain."

Academia delivers a harder blow. A team from ETH Zurich published a study in February 2026: *Evaluating AGENTS.md*. The conclusion is worth quoting directly: **"context files tend to reduce task success rates compared to providing no repository context."** LLM-generated context files reduced task success in five out of eight settings, at a cost 20-23% higher. Human-written: a marginal +4%. For many setups, *no* static config file beats an *agent-generated* config file.

METR published an RCT on sixteen experienced developers. With AI, they were **nineteen percent slower** on *their own* codebases — yet they *felt* 20% faster. A thirty-nine percentage-point perception gap. The message: **AI probably helps novices and unfamiliar codebases, not experts on their own turf.** The METR February 2026 update for a new developer cohort shows opposite results — suggesting the effect is highly dependent on project context and author profile. Evidence evolves.

Criticism of SDD itself is loudest in the blogosphere. The most thorough analysis from November 2025 lists seven flaws — from Context Blindness to Diminishing Returns. A concrete example: the GitHub Spec Kit produces **eight files and 1,300 lines for a trivial date-display feature**. Zaninotto's article had a title that spoke for itself: *"Spec-Driven Development: The Waterfall Strikes Back."*

The practitioner's synthesis — a decision tree with three variables: number of teams touching the codebase, consequences of architectural drift, cost of regenerating code. **SDD wins when all three are high.** It helps in cross-service refactors with shared contracts, regulated domains, and multi-agent coordination. It hurts in exploratory prototypes, simple feature work, and iterations where spec-spec rewrites cost more than code-spec convergence. A manager doesn't enforce SDD top-down — they let teams choose per repo and audit the choice after six months with a PR throughput vs. rework rate metric.

![A three-question decision tree for choosing the SDD level per repository: cross-service consequences, multi-team coordination, compliance gates — with concrete outcome nodes and their counterparts in real teams.](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*sYG8HXSr2FC_CRoNiPNG9g.png)

*.*

## Maturity Ladder — Where Your Team Stands and Where It Should Go

CDLC adoption in 2026 looks like DevOps adoption in 2010-2015. Back then, teams would say "we have DevOps" because they'd installed Jenkins. Today they say "we have CDLC" because they have a config file in the repo. **Most AI-native teams are at L1-L2** — that's the current industry baseline. The competitive advantage lies in moving to L3 and L4.

The ladder has six rungs:

- **L0 — No context.** Every session starts from zero; the agent asks about the stack every session.
- **L1 — Ad-hoc context.** A file copied from a blog post, never updated. Most teams are here today.
- **L2 — Versioned context.** Config in the repo, kept updated, no evals. Industry baseline 2026.
- **L3 — Tested context.** Evals for key conventions, a golden dataset of 50-200 task instances. Vercel, in their agent evaluations, reported moving from a 79% pass rate on skill-based search to 100% with a well-constructed AGENTS.md file.
- **L4 — Distributed context.** Skills and commands distributed across teams via a central registry. Subagents as a shared library.
- **L5 — Context flywheel.** Full CDLC — a self-healing system with an Observe → Generate loop. Frontier 2026.

Practical rule: **one rung up per quarter. No more.** Jumping from L1 to L4 is a recipe for maturity theater — papering over practice. Debois put it elegantly: the winning teams in the age of agents won't be the ones with the best models — they'll be the ones with the best context.

## Summary

We return to the agent from Friday's failure. It edited file number four of eight because it fell into an attention dead zone — and now you understand *systemically* why that happened and exactly what to do this week. Start with one Skill versioned per SDLC phase for your active repo, spin up a parallel sub-agent code-writer and sub-agent test-writer against a shared spec with a verifier at the end, and within a quarter build a golden dataset of fifty representative tasks as a regression test after every context configuration change. A bigger model doesn't save you — context discipline saves you, measured, distributed, and improved in a loop while the rest of the teams are still improvising in Cursor Chat.

*Thank you for reading to the end.* ***If this article changed the way you think about context — share it with someone who should know this too****, leave 50 claps, and follow the profile.*