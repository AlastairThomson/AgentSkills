---
name: ato-artifact-collector
description: "Collect, generate, and index NIST 800-53 security artifacts from a code repository for federal ATO (Authority to Operate) package preparation. Use whenever the user mentions ATO, NIST 800-53, security package, SSP artifacts, FedRAMP evidence collection, compliance artifacts, security documentation gathering, ATO readiness, compliance gaps, or security documentation completeness for a federal system. Even a casual 'collect security artifacts' or 'what do I need for my ATO' should trigger this skill. Accepts CLI-style flags (--repo / --aws / --azure / --sharepoint / --smb / --no-vuln-scan / --remediation / --poam) to bypass the interactive scope-confirmation interview; falls back to the interview when no source flags are present. Confirms scope, then delegates the multi-step collection to the ato-artifact-collector agent."
---

# ATO Artifact Collector

This skill is a thin launcher for the `ato-artifact-collector` agent. The agent runs an 8-step workflow that reads dozens of files, invokes sibling skills for external sources (AWS / Azure / SharePoint / SMB), runs a pre-collection vulnerability baseline, and writes 20+ evidence directories plus a `CHECKLIST.md`, `INDEX.md`, and `CODE_REFERENCES.md`. That volume of work belongs in an isolated agent context, not the main conversation.

## Step 0 — Parse flags from `$ARGUMENTS`

Before doing anything else, parse the user's invocation arguments for the following flags. The grammar is one or more space-separated `--<flag>` tokens; flags carry no values.

| Flag | Effect |
|---|---|
| `--repo` | Mark repo scope explicitly. (Repo is always implied; this flag is for documentation.) |
| `--aws` | Enable the AWS source. Skip the AWS y/N prompt. Requires ambient `aws` CLI auth and `ato-source-aws` installed. |
| `--azure` | Enable the Azure source. Skip the Azure y/N prompt. Requires ambient `az` CLI auth and `ato-source-azure` installed. |
| `--sharepoint` | Enable the SharePoint / M365 source. Skip the SharePoint y/N prompt. Requires ambient `m365` CLI auth and `ato-source-sharepoint` installed. |
| `--smb` | Enable the SMB / Windows-share source. Skip the SMB y/N prompt. Requires mount helpers and `ato-source-smb` installed. |
| `--no-vuln-scan` | Disable the pre-collection vulnerability scan. By default the scan runs every collection (between Step 1 and Step 2 of the agent workflow). |
| `--no-assessment` | Disable the per-Determine-If-ID assessment pass (Step 6.5) AND synthesis (Step 6.6). The orchestrator still emits the `<cf>-implementation.md` family narrative with H3 sub-sections + Determine If Statement, but skips Findings/Result and emits a 7-column CSV (no `Result`/`Findings` columns) instead of the 9-column GRC default. |
| `--no-synthesize` | Disable gap-driven artifact synthesis (Step 6.6) only. Findings + Result are still produced (assessment runs); gaps are named textually but no drafts are written and no `SYNTHESIZED_ARTIFACTS.md` inventory is produced. |
| `--accept-synthesized` | Auto-promote each synthesized draft from `synthesized/<artifact>.md` to `evidence/<CONTROL-ID>/<DETERMINE-IF-ID>/<artifact>.md` (one folder up); flip Result to Satisfied for that Determine If ID; emit loud signaling (end-of-run summary block, `INDEX.md` banner, `CHECKLIST.md` notes column). The original drafts stay under `synthesized/` for audit. **Risky** — synthesized drafts make assertions about the system from code inspection alone, and may disagree with org policy. The loud signaling is the safeguard; review every promoted artifact before authoritative submission. |
| `--remediation` | Auto-invoke `ato-remediation-guidance` after Step 8 completes. Without this flag, remediation guidance runs only when the user explicitly asks afterward. |
| `--poam` | Auto-invoke `ato-poam-generator` after the remediation step. **Implies `--remediation`** (POA&M generation consumes the remediation output). If the user passes `--poam` alone, log `[INFO] --poam implies --remediation; enabling.` and proceed with both. |

### Precedence rule

**Any source flag (`--aws`, `--azure`, `--sharepoint`, `--smb`) means: skip the interactive interview entirely and treat unflagged sources as disabled.** This matches CLI-tool conventions (explicit flags are authoritative; absence means off). If no source flags are present, fall through to the interview in Step 1.

`--repo` on its own counts as a source flag — it triggers the same skip-interview behavior, with all four external sources disabled.

`--no-vuln-scan`, `--no-assessment`, `--no-synthesize`, `--accept-synthesized`, `--remediation`, and `--poam` are output-control flags (they don't affect source selection). They can combine with the interview path or the flag path freely. `--no-assessment` implies `--no-synthesize` (synthesis depends on Findings).

### Examples

| Invocation | Behavior |
|---|---|
| (no args) | Run the interactive interview as today; default `vulnerability_scan.enabled` from config (true unless overridden) |
| `--repo` | Skip interview, repo only, vuln scan on, no remediation, no POAM |
| `--repo --aws` | Skip interview, repo + AWS, vuln scan on, no remediation, no POAM |
| `--repo --no-vuln-scan` | Skip interview, repo only, no vuln scan, no remediation, no POAM |
| `--repo --remediation` | Skip interview, repo only, vuln scan on, auto-remediation, no POAM |
| `--repo --poam` | Skip interview, repo only, vuln scan on, auto-remediation (implied), POA&M generated |
| `--repo --no-assessment` | Skip interview, repo only, no per-sub-control assessment scaffolding (smaller CSV without Result/Findings columns) |
| `--repo --no-synthesize` | Skip interview, repo only, assessment runs but no synthesized drafts written |
| `--repo --accept-synthesized` | Skip interview, repo only, synthesis on, drafts auto-promoted to evidence (loud signaling) |
| `--aws --azure --sharepoint --smb --remediation --poam` | Full external collection + auto-remediation + POAM (no interview) |

## Step 1 — Confirm scope with the user (only when no source flags were passed)

If Step 0 detected any source flag, **skip this step entirely**. The scope is fully determined by flags + config; do not re-ask.

Otherwise, establish which external sources the user wants to scan:

- **Repo only** (first-class default) — no external sources; the agent scans just the current repo.
- **AWS** — requires ambient `aws` CLI auth and `ato-source-aws` sibling installed.
- **Azure** — requires ambient `az` CLI auth and `ato-source-azure` sibling installed.
- **SharePoint / M365** — requires ambient `m365` CLI auth and `ato-source-sharepoint` sibling installed.
- **SMB file shares** — requires mount helpers and `ato-source-smb` sibling installed.

Ask the user which apply. If an `.ato-package.yaml` exists at the repo root, read it and confirm the settings with the user rather than re-asking from scratch.

## Step 2 — Launch the agent

Invoke the `Agent` tool with `subagent_type: "ato-artifact-collector"`. Pass:

- The confirmed scope (from Step 0 flags or Step 1 interview).
- The repo's working directory.
- The output-control flags resolved in Step 0:
  - `vuln_scan.enabled: true | false` (true unless `--no-vuln-scan` was passed or config disables it)
  - `assessment.enabled: true | false` (config default unless `--no-assessment` was passed; default config is `true`)
  - `synthesis.enabled: true | false` (config default unless `--no-synthesize` was passed; default config is `true`; auto-disabled when `assessment.enabled: false`)
  - `synthesis.auto_accept: true | false` (true if `--accept-synthesized` was passed; default config is `false`)
  - `auto_remediation: true | false` (true if `--remediation` or `--poam` was passed)
  - `auto_poam: true | false` (true if `--poam` was passed)
- Any user notes (target ATO version, deadline, gap tolerance).

The agent's system prompt has the full 8-step workflow (plus the new Step 1.5 vulnerability scan and the post-Step-8 auto-remediation / POA&M follow-ons), Mermaid rules, citation conventions, and sibling-invocation contract.

## Step 3 — Relay the agent's output

When the agent completes, relay:

- Final file tree of `docs/ato-package/` (directories and top-level files only — not contents).
- The `CHECKLIST.md` summary (which items are covered, which are gaps).
- Any scope failures the agent recorded (e.g. SharePoint auth missing — continued without).
- The vulnerability-scan summary table (severity counts + tools missing) if vuln scan ran.
- Confirmation that `REMEDIATION_GUIDANCE.md` and/or `poam-generated.md` exist if those follow-ons ran.

Do not re-process the narrative documents — they are for the assessor, not for summary re-reading in the main conversation.
