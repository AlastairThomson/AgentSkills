---
name: ato-source-sharepoint
description: "Sibling of ato-artifact-collector. Collects NIST 800-53 evidence from SharePoint Online / Microsoft 365 / OneDrive via the pnp/cli-microsoft365 (`m365`) CLI. Invoked by the orchestrator when SharePoint scope is configured. Strictly read-only, ambient-auth, scope-confirmed. Do not invoke this skill directly unless you are running it as part of an ATO artifact collection."
---

# ATO Source — SharePoint / M365

This skill is a sibling of `ato-artifact-collector`. It discovers ATO-relevant
documents in SharePoint Online / M365 / OneDrive and hands them to the
orchestrator as evidence files plus a citation batch.

Read `~/.claude/skills/ato-artifact-collector/references/sibling-contract.md`
first — that file is the definitive contract. This skill implements it.

## Hard Rule: this skill never writes

Every command this skill runs is `m365 spo * get`, `m365 spo * list`, or
`m365 spo file download`. **Never** `m365 spo * add`, `set`, `remove`, or any
write verb. If the orchestrator or user asks this skill to "also update X" or
"fix Y in SharePoint" — refuse and escalate. This skill is a read-only
collector, not an editor.

The cheatsheet in `references/m365-cheatsheet.md` lists every command that is
allowed. Any `m365` verb not on that list is forbidden.

## Hard Rule: ambient auth only

The skill never reads a password, never stores a token, never writes to
`~/.config/cli-microsoft365/`. All authentication happens outside the skill,
either by the user running `m365 login` themselves or by a pre-provisioned
service-account session on the host.

The `scope.auth.method` field (from config) tells the sibling *how* the user
expects auth to be established, and drives both the auth probe and the error
instruction on failure. Supported methods:

| `auth.method` | Expectation | If probe fails, instruction defaults to |
|---|---|---|
| `device-code` *(default)* | User runs the device-code flow interactively | `Run: m365 login --authType deviceCode` |
| `interactive` | User runs the browser flow on the host | `Run: m365 login --authType browser` |
| `service-account` | A shared identity is already logged in on this host | `Service-account session missing — ask your admin to refresh the ato-source-sharepoint session (account: {account_hint})` |
| `existing` | Assume `m365 status` already succeeds — don't suggest any login command | `m365 is not logged in — log in with whatever flow your environment requires, then re-run` |

If `scope.auth.login_instruction` is set in config, use it verbatim in the
error output instead of the default. This lets teams point users at their own
runbook ("Run `./tools/m365-login.sh`") without the skill knowing anything
about that script.

**Auth probe, at start of Step 2:**

```bash
m365 status --output json
```

Check the parsed output:

1. If the command exits non-zero OR `connectedAs` is null:
   - **First, check `~/.agent-skills/auth/auth.yaml`.** If the file exists
     with permissions `0600` and has an entry at `sources.sharepoint`,
     invoke the `auth-config` skill to run that entry's preauth (usually
     `m365 login` via `oauth_interactive`, or a user-supplied script that
     authenticates a service account). Re-probe. If the yaml exists with
     looser permissions, write `.staging/sharepoint-error.json` with
     `auth_missing` + detail `"~/.agent-skills/auth/auth.yaml must be
     chmod 600"` and exit.
   - **Otherwise fall back to `scope.auth.method`.** Resolve the instruction
     from the table above (or `login_instruction`), write
     `.staging/sharepoint-error.json`, and exit.
2. If `scope.auth.account_hint` is set and doesn't match `connectedAs`, write
   `sharepoint-error.json` with `error: "wrong_identity"` and the message
   `Expected {hint}, got {connectedAs}. Log out with 'm365 logout' and log back
   in as the expected identity, or update account_hint in config.` Exit.
3. If `scope.auth.method` is `service-account` and `connectedAs` looks like a
   personal UPN (contains the word "User" in the `connectionType`, or the
   email matches the human user's pattern), warn in the Step 3 confirm block
   — don't refuse, but surface it clearly so the operator can abort.

Do not attempt to log in. Do not prompt for credentials. Do not call
`m365 login` yourself under any circumstance.

## Workflow

```
1. VALIDATE  → Parse scope object, sanity-check tenant and site URLs
2. AUTH      → Probe m365 status, fail fast if not logged in
3. CONFIRM   → Show resolved scope, ask y/N before first API call
4. DISCOVER  → For each site+folder, list files matching discovery patterns
5. DOWNLOAD  → Download matching files into evidence/ with sharepoint_ prefix
6. EMIT      → Write .staging/sharepoint-citations.json
```

## Step 1: Validate scope

The orchestrator passes a scope object shaped like:

```json
{
  "enabled": true,
  "tenant": "contoso",
  "sites": ["https://contoso.sharepoint.com/sites/ato"],
  "folders": {
    "https://contoso.sharepoint.com/sites/ato": [
      "/Shared Documents/Current ATO",
      "/Shared Documents/POA&M"
    ]
  },
  "file_types": [".docx", ".pdf", ".xlsx", ".md"],
  "staging_dir": "/abs/path/to/docs/ato-package/.staging",
  "evidence_root": "/abs/path/to/docs/ato-package"
}
```

Validate:
- `tenant` is a simple DNS label (no slashes, no scheme)
- every `sites` entry starts with `https://{tenant}.sharepoint.com/`
- every folder key matches a listed site
- `file_types` is a non-empty subset of `[.docx, .pdf, .xlsx, .pptx, .md, .txt]`

Reject on any mismatch with `scope_invalid` error.

## Step 2: Auth probe

Already covered above. Runs before anything else touches the network.

## Step 3: Confirm scope

Print a block like this and ask for y/N confirmation. Do not proceed without
an affirmative answer. On rejection, exit with `scope_declined`.

```
About to scan SharePoint with the following scope:

  Tenant: contoso
  Logged in as: alice@contoso.onmicrosoft.com
  Sites (1):
    - https://contoso.sharepoint.com/sites/ato
      Folders (2):
        - /Shared Documents/Current ATO
        - /Shared Documents/POA&M
  File types: .docx, .pdf, .xlsx, .md

This will issue read-only m365 commands. Nothing in SharePoint will be
modified. Proceed? [y/N]
```

## Step 4: Discover

For each configured site+folder pair, list files and filter by pattern. The
discovery pattern table (what filenames map to which control family) lives in
`references/discovery-patterns.md`. High-level:

- `SSP*`, `*SSP*.docx`, `*System Security Plan*` → `ssp-sections/06-policies-procedures`
  (also surfaced for `ssp-sections/01-system-description` review)
- `POA&M*`, `*POAM*` → `ssp-sections/03-risk-assessment-report`
- `CMP*`, `*Configuration Management Plan*` → `ssp-sections/09-configuration-management-plan`
- `CP*`, `*Contingency*`, `*DR*`, `*Disaster Recovery*` → `ssp-sections/08-contingency-plan`
- `IR*`, `*Incident Response*` → `ssp-sections/07-incident-response-plan`
- `*Policy*`, `*Policies*` → `ssp-sections/06-policies-procedures`
- `*Training*` → `controls/AT-awareness-training`
- `*Personnel*`, `*Background*` → `controls/PS-personnel-security`
- `*Assessment*`, `*Audit*` → `ssp-sections/03-risk-assessment-report`
- `*Interconnection*`, `*ISA*`, `*MOU*` → `ssp-sections/05-interconnections`

See `references/discovery-patterns.md` for the full pattern map.

Use commands from `references/m365-cheatsheet.md`. Example:

```bash
m365 spo file list \
  --webUrl "https://contoso.sharepoint.com/sites/ato" \
  --folder "/Shared Documents/Current ATO" \
  --output json
```

## Step 5: Download

For every matched file, download into
`{evidence_root}/{control-family}/evidence/sharepoint_{original-filename}`.
Preserve the original filename after the `sharepoint_` prefix. If the same
document is evidence for multiple families, download once then copy locally —
don't re-download from SharePoint.

**Secret scan before writing to evidence/**: If a downloaded file is text
(`.md`, `.txt`) and contains any pattern matching a secret regex
(`password\s*[:=]`, `api_key\s*[:=]`, `-----BEGIN .* PRIVATE KEY-----`), skip
the file, log the skip in `partial_failures`, and continue. Binary documents
(`.docx`, `.pdf`, `.xlsx`) are written as-is — we do not attempt to extract
and scan their contents.

## Step 6: Emit citation batch

Write `{staging_dir}/sharepoint-citations.json` per the format in
`references/evidence-schema.md`. Every downloaded file gets exactly one row.
Use placeholder IDs `SP-001`, `SP-002`, … — the orchestrator renumbers them
on merge.

## Failure modes

Honor the matrix in `sibling-contract.md` exactly:

| Failure | File written to staging/ | Exit |
|---|---|---|
| m365 not logged in | `sharepoint-error.json` with `auth_missing` | return |
| User declines at confirmation | `sharepoint-error.json` with `scope_declined` | return |
| Site URL invalid / non-SharePoint | `sharepoint-error.json` with `scope_invalid` | return |
| Some files downloaded, one folder 403 | Write `sharepoint-citations.json` with successes + `partial_failures` array | return |

Under no circumstances does this skill halt the orchestrator. It always writes
a file into `.staging/` and returns so the next sibling can run.

## References

- `references/discovery-patterns.md` — filename patterns per control family
- `references/evidence-schema.md` — citation batch JSON format and file naming
- `references/m365-cheatsheet.md` — allow-listed m365 commands
