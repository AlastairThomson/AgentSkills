---
description: "Collect, generate, and index NIST 800-53 security artifacts from a code repository for federal ATO (Authority to Operate) package preparation. Use whenever the user mentions ATO, NIST 800-53, security package, SSP artifacts, FedRAMP evidence collection, compliance artifacts, security documentation gathering, ATO readiness, compliance gaps, or security documentation completeness for a federal system. Even a casual 'collect security artifacts' or 'what do I need for my ATO' should trigger this skill. Confirms scope with the user, then delegates the multi-step collection to the ato-artifact-collector agent."
---

# ATO Artifact Collector

This skill is a thin launcher for the `ato-artifact-collector` agent. The agent runs an 8-step workflow that reads dozens of files, invokes sibling skills for external sources (AWS / Azure / SharePoint / SMB), and writes 20+ evidence directories plus a `CHECKLIST.md`, `INDEX.md`, and `CODE_REFERENCES.md`. That volume of work belongs in an isolated agent context, not the main conversation.

## Step 1 — Confirm scope with the user

Before launching the agent, establish which external sources the user wants to scan:

- **Repo only** (first-class default) — no external sources; the agent scans just the current repo.
- **AWS** — requires ambient `aws` CLI auth and `ato-source-aws` sibling installed.
- **Azure** — requires ambient `az` CLI auth and `ato-source-azure` sibling installed.
- **SharePoint / M365** — requires ambient `m365` CLI auth and `ato-source-sharepoint` sibling installed.
- **SMB file shares** — requires mount helpers and `ato-source-smb` sibling installed.

Ask the user which apply. If an `.ato-package.yaml` exists at the repo root, read it and confirm the settings with the user rather than re-asking from scratch.

## Step 2 — Launch the agent

Invoke the `Agent` tool with `subagent_type: "ato-artifact-collector"`. Pass:

- The confirmed scope (from Step 1).
- The repo's working directory.
- Any user notes (target ATO version, deadline, gap tolerance).

The agent's system prompt has the full 8-step workflow, Mermaid rules, citation conventions, and sibling-invocation contract.

## Step 3 — Relay the agent's output

When the agent completes, relay:

- Final file tree of `docs/ato-package/` (directories and top-level files only — not contents).
- The `CHECKLIST.md` summary (which items are covered, which are gaps).
- Any scope failures the agent recorded (e.g. SharePoint auth missing — continued without).

Do not re-process the narrative documents — they are for the assessor, not for summary re-reading in the main conversation.
