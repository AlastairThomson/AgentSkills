---
name: bdd-audit
description: "Audit BDD spec coverage: classify each feature area as wired/unwired/truly-missing/deferred and produce a prioritised build-vs-test action list. Use when the user asks about BDD coverage, Gherkin specs, step wiring, or whether unimplemented scenarios represent missing tests or missing features. Delegates the multi-file investigation to the bdd-audit agent."
---

# BDD Audit

This skill is a thin stub that triggers on "audit BDD specs" / "check Gherkin coverage" requests and delegates to the `bdd-audit` agent.

## What to do

1. Invoke the `Agent` tool with `subagent_type: "bdd-audit"`. State the working directory in the prompt — the agent's system prompt contains the full workflow.
2. Relay the agent's prioritised action list to the user.
3. Suggest the right next skill based on the result:
   - "Build first" items dominate → user likely needs a feature-development plan before any test wiring; flag this.
   - "Wire now" items dominate → suggest a focused test-wiring pass.
   - Fully wired → suggest `/coverage-audit` to find unit-test gaps next.

## Why this is an agent, not inline skill work

The audit reads every feature file, every step-definition file, and greps the source tree for domain concepts. That evidence is verbose and one-time; sequestering it in an agent's context keeps the main conversation lean.
