# Sibling Skill Contract

Every `ato-source-*` sibling skill implements this contract. The
`ato-artifact-collector` orchestrator invokes siblings via the Skill tool and
relies on their outputs landing in well-known locations. Siblings that deviate
from this contract will not integrate cleanly.

## Identity

Sibling skills live at `~/.claude/skills/ato-source-{name}/` where `{name}` is
one of: `sharepoint`, `aws`, `azure`, `smb`. Each sibling has:

```
ato-source-{name}/
├── SKILL.md                          ← Hard rules, scope query, discovery, handoff
└── references/
    ├── discovery-patterns.md         ← What to look for, per control family
    ├── evidence-schema.md            ← File naming, citation batch format
    └── {tool}-cheatsheet.md          ← CLI/MCP commands the skill uses
```

## Hard rules — every sibling must state these up front

Every sibling's SKILL.md opens with these rules. They are not optional.

1. **Read-only.** The skill uses only `get`, `list`, `describe`, and `download`
   verbs. Any mutating API (`put`, `create`, `delete`, `update`, `attach`, etc.)
   is forbidden in the skill's instructions. If the user asks the sibling to
   "also fix X" — refuse, escalate to the orchestrator, and let the user run a
   different skill.

2. **Ambient auth only, never stored credentials.** The sibling requires the
   user to have already logged in via whatever native flow the operator's
   environment uses. The sibling never reads credentials from the config
   file, never prompts for a password and caches it, never stores a token.
   On auth failure, fail loud with a specific login instruction.

   **The config's `auth:` block (per source) is environment-configurable.**
   Each sibling supports multiple `auth.method` values — for example Azure
   supports `device-code`, `interactive`, `helper`, and `existing`; AWS
   supports `sso`, `profile`, `env`, and `instance`; SharePoint supports
   `device-code`, `interactive`, `service-account`, and `existing`. The
   sibling picks its probe and its on-failure instruction based on the
   configured method. A user-supplied `login_instruction` override (string
   from config) replaces the default failure message verbatim, so teams can
   point operators at their own runbooks without the sibling needing to know
   anything about those flows.

   The Azure sibling additionally supports a `helper_command` — a path to a
   **user-owned executable** that wraps whatever credential-acquisition flow
   the environment uses (1Password → `az login`, an internal identity broker,
   a federal SSO shim, etc.). The sibling invokes the helper as a subprocess
   and checks its exit code; it **never reads the helper's contents** and
   never sees any secrets the helper touches. This is the extension point
   for environment-specific auth without weakening the "sibling never holds
   credentials" rule.

   What stays constant across all methods: no secrets in the config file; no
   login attempts beyond the one optional helper invocation; no interactive
   password prompts from inside the sibling itself.

3. **Scope confirmation in-session.** Even when the scope object is fully
   pre-configured, the sibling displays a human-readable summary of what it's
   about to touch (tenant, sites, accounts, regions, UNC paths) and asks for
   explicit y/N confirmation before the first external call. This is the last
   line of defense against misconfiguration.

4. **US-only for cloud sources.** AWS and Azure siblings validate every region
   in scope against the hard-coded US allow list in
   `ato-artifact-collector/references/config-schema.md`. A single non-US region
   in scope causes the sibling to refuse the whole run with a specific error
   naming the offending region. No "skip and continue" — fail closed.

5. **Never exfiltrate secrets.** If a sibling stumbles onto something that
   looks like a secret (`password=`, API key, private key PEM, etc.) inside
   an evidence file it would otherwise download, the sibling skips the file,
   logs the skip, and continues. Evidence is for assessors, not an attacker
   dump.

## Inputs

The orchestrator invokes the sibling with a scope object resolved from the
merged config. The sibling's SKILL.md defines its own scope shape; see each
sibling for specifics. Common fields:

- `enabled: true` — always true when the orchestrator invokes the sibling
  (disabled sources are never called)
- Source-specific scope fields (sites, accounts, subscriptions, shares, etc.)
- `staging_dir` — absolute path to `docs/ato-package/.staging/` in the repo
- `evidence_root` — absolute path to `docs/ato-package/` (so the sibling knows
  where to drop files under `{NN-family-slug}/evidence/`)

## Outputs

The sibling writes to two locations:

### 1. Evidence files

Copied or exported files land in
`docs/ato-package/{NN-family-slug}/evidence/` with a source prefix so they
can never collide with repo-sourced evidence:

- `sharepoint_*` — SharePoint downloads
- `aws_*` — AWS JSON exports, IAM reports, Config compliance JSON, etc.
- `azure_*` — Azure JSON exports, policy state, NSG rules, etc.
- `smb_*` — copies from SMB shares (with original filename preserved after
  the prefix)

The family slug is one of the 20 slugs defined in the orchestrator's Step 4.
The sibling picks the family by matching the artifact to the discovery
patterns in its own `references/discovery-patterns.md`, which cross-references
the orchestrator's `references/artifact-mappings.md`.

#### 1a. Per-resource digest companions

Cloud siblings (`aws`, `azure`) additionally write a Markdown digest
companion next to each significant JSON evidence file. The digest:

- Sits in the same `evidence/` folder as the JSON, with the same source
  prefix and a per-resource name (e.g. `aws_iam-role-app-runtime.md`,
  `azure_role-assignment-22222222.md`).
- Contains a 1–3 sentence plain-English summary, a Key Settings table
  (5–12 rows), every "critical" linked resource embedded inline as full
  JSON (e.g. an IAM user's attached policy documents, a role
  assignment's role definition body), and a noted-only references table
  for non-critical dependencies.
- Is the **human-facing** evidence; the JSON remains the verbatim ground
  truth. Step 7 prefers the digest as the link target in
  `CODE_REFERENCES.md` when both are present.

The full digest spec lives in each cloud sibling's
`references/evidence-schema.md` "Per-resource digest companion" section
and `references/digest-templates.md` ready-to-fill templates.

SharePoint and SMB siblings do not produce digests — their evidence is
already a human-readable document.

### 2. Citation batch

One JSON file per sibling at
`docs/ato-package/.staging/{source}-citations.json`:

```json
{
  "source": "sharepoint",
  "generated_at": "2026-04-14T10:32:00Z",
  "scope_summary": "tenant=contoso, 1 site, 3 folders",
  "citations": [
    {
      "id_placeholder": "SP-001",
      "cited_by": "10-security-policies/security-policies-evidence.md",
      "location": "SSP-v2.docx",
      "link": "https://contoso.sharepoint.com/sites/app-ato/Shared%20Documents/SSP-v2.docx",
      "purpose": "Prior approved SSP — baseline for this revision",
      "control_family": "10-security-policies",
      "evidence_file": "10-security-policies/evidence/sharepoint_SSP-v2.docx"
    }
  ]
}
```

Field reference:

- `id_placeholder` — the sibling uses its own prefix (`SP-`, `AWS-`, `AZ-`,
  `SMB-`) and monotonic numbering within its batch. Step 7 renumbers these
  to contiguous `CR-NNN` IDs on merge.
- `cited_by` — path (relative to `docs/ato-package/`) of the narrative doc
  that should cite this. The sibling can leave this as the family's evidence
  file path if no specific narrative section is implied — the human author
  incorporates it during review.
- `location` — human-readable locator: file name, ARN, resource ID, UNC path.
- `link` — the external URL or URI (see the link format table in Step 7 of
  the orchestrator).
- `purpose` — one-line description of why this matters to the control family.
- `control_family` — one of the 20 slugs; determines the evidence subfolder.
- `evidence_file` — path (relative to `docs/ato-package/`) of the local copy
  the sibling wrote. Must actually exist at merge time. For cloud
  siblings this is the raw JSON.
- `digest_file` *(optional, cloud siblings only)* — path (relative to
  `docs/ato-package/`) of the Markdown digest companion. Required when a
  per-resource digest was synthesized; omitted for aggregate-only
  exports where the digest *is* the evidence file. Step 7 prefers
  `digest_file` as the human-facing link in `CODE_REFERENCES.md`.

### Staging cleanup

The staging directory is transient. The orchestrator deletes
`docs/ato-package/.staging/` at the end of Step 7 after successful merge.
Siblings must not assume files in `.staging/` persist beyond a single run.

## Failure modes

Siblings must handle these specific failure modes with specific exit behavior.
The orchestrator relies on these to distinguish "keep going with other
sources" from "halt the run".

| Failure | Sibling behavior | Orchestrator response |
|---|---|---|
| Ambient auth missing | Write `.staging/{source}-error.json` with `{"error": "auth_missing", "instruction": "Run: m365 login --authType deviceCode"}` and exit | Record failure, print instruction, continue with next source |
| Scope rejected at confirmation prompt | Write `.staging/{source}-error.json` with `{"error": "scope_declined"}` and exit | Record, continue with next source |
| Scope validation failed (non-US region, bad config) | Write `.staging/{source}-error.json` with `{"error": "scope_invalid", "detail": "region eu-west-1 not on US allow list"}` and exit | Record, continue with next source |
| Partial success (some files downloaded, one API call failed) | Write the citation batch with what succeeded; append `partial_failures: [...]` array to the batch JSON with per-failure detail | Merge the successful rows; note partials in INDEX.md under the family |
| Mutating API detected in instructions | Sibling refuses to run at all, writes error, exits | Halt the whole package — this is a bug in the sibling skill itself |

## Invocation pattern from the orchestrator

After Step 1 (Orient), for each source with `enabled: true` in the resolved
scope, the orchestrator invokes:

```
Skill: "ato-source-{name}"
Args: JSON-encoded scope object for this source + staging_dir + evidence_root
```

The orchestrator waits for the sibling to return before invoking the next
sibling. Siblings do not call each other. The orchestrator does not pass
credentials — the sibling relies entirely on ambient auth set up by the user.

After all enabled siblings have returned (success or failure), the
orchestrator proceeds to Step 4 (Generate) with evidence and staging
already populated.

## What siblings do NOT do

- **Do not generate narrative documents.** That's the orchestrator's job in
  Step 4. Siblings only collect evidence and register citations.
- **Do not write to `CODE_REFERENCES.md`.** Siblings write citation batches
  to `.staging/`. The orchestrator merges them in Step 7.
- **Do not modify files outside `docs/ato-package/`.** Especially: do not
  write to `~/.claude/skills/`, `~/.aws/`, `~/.azure/`, or any config
  location. Siblings are strictly output-to-package-only.
- **Do not run their own gap analysis.** The orchestrator owns the control
  family completeness model. Siblings just deliver what they find.
- **Do not prompt for credentials.** If ambient auth is missing, fail loud
  with a login instruction and exit.
