---
name: ato-source-smb
description: "Sibling of ato-artifact-collector. Collects NIST 800-53 evidence from SMB / Windows file shares. Cross-platform: macOS (mount_smbfs), Linux (mount.cifs or gvfs), Windows (direct UNC paths). Strictly read-only, ambient-auth, depth-limited, scope-confirmed. Do not invoke directly unless running an ATO collection."
---

# ATO Source — SMB / Windows File Shares

Read `~/.claude/skills/ato-artifact-collector/references/sibling-contract.md`
first. This skill implements that contract for SMB shares across operating
systems.

## Hard Rule: this skill never writes

The only filesystem operation this skill performs on a mounted SMB share is
**reading** and **copying files out**. Never `cp` TO the share, never
`mkdir`, never `rm`, never `touch`, never change permissions. The share is
mounted read-only where the OS supports it (`mount_smbfs -o nobrowse,ro` on
macOS; `mount.cifs -o ro` on Linux).

If the user asks this skill to "drop the package back on the share" or
"update a file on the share" — refuse.

## Hard Rule: ambient auth only

Credentials come from the OS's native credential store:

| OS | Credential source |
|---|---|
| macOS | Keychain entry for the SMB share, or Kerberos ticket via `klist` |
| Linux | `~/.smbcredentials` with chmod 600 (managed by user, not skill), Kerberos, or `gvfs-mount` interactive prompt |
| Windows | Current logged-in user token (or `cmdkey` saved credential) |

This skill **never** writes to `~/.smbcredentials`, never prompts for a
password and stores it, never pipes a password into `mount` on the command
line. If credentials are missing, fail with the OS-specific instruction and
exit.

## Preauth via auth-config (optional)

Before attempting to mount or access a share, check for
`~/.agent-skills/auth/auth.yaml`:

- If the file exists with permissions `0600` **and** contains an entry at
  `sources.smb`, invoke the `auth-config` skill to run that entry's preauth
  command. The typical pattern is a user-owned script at
  `~/.agent-skills/auth/mount-smb.sh` that handles mounting (`mount_smbfs`
  on macOS, `mount.cifs` or `gvfs-mount` on Linux, or just a UNC path on
  Windows). `auth-config` runs the script; this skill never writes mount
  syntax itself.
- If the file is missing or has no `sources.smb` entry, fall through to the
  native-credential-store flow documented above.
- If the file has permissions looser than `0600`, emit `auth_missing` with
  detail `"~/.agent-skills/auth/auth.yaml must be chmod 600"` and exit.

The consumer contract is: after preauth, the expected share(s) are mounted
and readable. This skill re-runs the configured `validate` command (usually
`mount | grep -q '<share-host>'`) to confirm before proceeding.

## Hard Rule: depth-limited traversal

Default traversal depth is **3 levels** under each configured share path.
This prevents accidentally walking an entire fileserver. The default is
set in the config schema (`smb.depth: 3`) and can be raised per-share only
when the user explicitly configures it.

## Hard Rule: OS detection

At the start of the run, detect the OS:

```bash
uname -s      # Darwin | Linux
# On Windows, uname is not reliably present — check $OS env var or
# fall back to PowerShell $PSVersionTable.OS
```

Branch on the result and follow the matching section below. Each branch is
self-contained — do not mix commands across branches.

## Workflow

```
1. DETECT    → Identify OS (Darwin/Linux/Windows)
2. VALIDATE  → Parse scope, check each share entry
3. CONFIRM   → Show resolved scope + resolved mount commands, ask y/N
4. MOUNT     → Mount each share read-only (macOS/Linux) — no-op on Windows
5. DISCOVER  → Walk each share depth-limited, filter by patterns
6. COPY      → Copy matched files to evidence/ with smb_ prefix
7. EMIT      → Write .staging/smb-citations.json
8. UNMOUNT   → Always unmount on exit (macOS/Linux)
```

Steps 4 and 8 wrap everything else in a try/finally equivalent: even if
DISCOVER or COPY fails, UNMOUNT must still run. On Windows, steps 4 and 8
are no-ops.

## Step 1: OS detect

```bash
OS="$(uname -s 2>/dev/null || echo Unknown)"
case "$OS" in
  Darwin)  branch=macos ;;
  Linux)   branch=linux ;;
  *)       branch=windows ;;  # includes MINGW/CYGWIN/MSYS — fall through
esac
```

## Step 2: Validate scope

```json
{
  "enabled": true,
  "shares": [
    {
      "name": "ato-policies",
      "unc": "//fileserver.corp/ato",
      "mount_point": "~/mnt/ato-policies",
      "credentials_helper": "kerberos"
    }
  ],
  "depth": 3,
  "file_types": [".docx", ".pdf", ".md", ".txt"],
  "staging_dir": "...",
  "evidence_root": "..."
}
```

Validate:
- every `shares[].unc` starts with `//` or `\\` (double-slash or double-backslash)
- `mount_point` (if present) does not escape the user's home directory
- `credentials_helper` ∈ {keychain, kerberos, prompt, cmdkey}
  - `keychain` — macOS Keychain entry (user sets it up via Finder → Connect to Server)
  - `kerberos` — valid ticket; verified non-invasively with `klist`
  - `prompt` — let the OS mount tool prompt the user interactively at mount time
  - `cmdkey` — Windows saved credential (user ran `cmdkey /add:host /user:... /pass:...`)
- `account_hint` (optional) is echoed in the Step 3 confirm block so the
  operator can verify which identity the mount will attach as. Display-only —
  never used as an auth input.
- `depth` is an integer in [1, 10]
- `file_types` is non-empty

## Step 3: Confirm scope

Print the resolved scope plus the exact mount command that will run for the
current OS, and ask for y/N. This is the last chance to catch a typo in a
UNC path before the skill touches the network.

```
About to scan SMB shares with the following scope:

  OS: macOS
  Shares (1):
    - name: ato-policies
      UNC: //fileserver.corp/ato
      Mount point: /Users/alice/mnt/ato-policies
      Credentials: kerberos
      Mount command: mount_smbfs -o nobrowse,ro //fileserver.corp/ato /Users/alice/mnt/ato-policies
  Traversal depth: 3
  File types: .docx, .pdf, .md, .txt

Mounts are read-only. Nothing will be written back to the share.
Proceed? [y/N]
```

## Step 4 (macOS branch)

```bash
mkdir -p "$MOUNT_POINT"
mount_smbfs -o nobrowse,ro "//${CREDENTIAL_HINT}@${HOST}/${SHARE}" "$MOUNT_POINT"
```

If the mount fails with a credential error, write
`.staging/smb-error.json`:

```json
{
  "error": "auth_missing",
  "instruction": "Add the share to Keychain via Finder → Connect to Server, or obtain a Kerberos ticket with 'kinit user@REALM'",
  "share": "//fileserver.corp/ato"
}
```

and exit.

## Step 4 (Linux branch)

Prefer userland via `gvfs-mount` when root isn't available:

```bash
gvfs-mount "smb://${HOST}/${SHARE}"
# Files then appear under /run/user/$UID/gvfs/smb-share:...
```

Or, if root is available and CIFS utils are installed:

```bash
sudo mkdir -p "$MOUNT_POINT"
sudo mount -t cifs -o ro,sec=krb5,username="$USER" \
  "//${HOST}/${SHARE}" "$MOUNT_POINT"
```

On auth failure:

```json
{
  "error": "auth_missing",
  "instruction": "Obtain a Kerberos ticket with 'kinit user@REALM', or create ~/.smbcredentials (chmod 600) with username= and password= lines and retry",
  "share": "//fileserver.corp/ato"
}
```

## Step 4 (Windows branch)

Windows needs no mount step — UNC paths are first-class. Skip directly to
DISCOVER with the path `\\fileserver.corp\ato`.

If the current user token doesn't have access:

```json
{
  "error": "auth_missing",
  "instruction": "Run: cmdkey /add:fileserver.corp /user:DOMAIN\\user  (or log in as a domain user with share access)",
  "share": "\\\\fileserver.corp\\ato"
}
```

## Step 5: Discover (all OSes)

Walk the mounted share (or UNC path on Windows) depth-limited:

```bash
# macOS / Linux
find "$MOUNT_POINT" -maxdepth "$DEPTH" -type f \
  \( -iname '*.docx' -o -iname '*.pdf' -o -iname '*.md' -o -iname '*.txt' \)
```

```powershell
# Windows
Get-ChildItem -Path "\\fileserver.corp\ato" -Recurse -Depth $Depth -File `
  -Include *.docx, *.pdf, *.md, *.txt
```

Apply the filename patterns from `references/discovery-patterns.md` to map
each file to a control family. Skip any file larger than 50 MB with
`too_large`. Skip any file inside an `Archive*` or `Old*` directory unless
explicitly in scope.

## Step 6: Copy

For each matched file, copy into
`{evidence_root}/{family}/evidence/smb_{original-filename}`.

**Secret scan before write**: if the file is text (`.md`, `.txt`), check
for secret patterns (`password\s*[:=]`, `api_key\s*[:=]`, PEM private key
markers). If matched, skip with `partial_failures.reason = contains_secret`.
Binary files (`.docx`, `.pdf`) are copied as-is — we don't extract content
to scan.

## Step 7: Emit citation batch

`{staging_dir}/smb-citations.json`. Placeholder IDs `SMB-001`, `SMB-002`, …

Each row's `link` field is the UNC URI, not a browser URL:

```
smb://fileserver.corp/ato/Current/DR-runbook.pdf
```

See `references/evidence-schema.md` for the full schema.

## Step 8: Unmount

Always run at end — success, failure, or exception:

```bash
# macOS
umount "$MOUNT_POINT" 2>/dev/null || diskutil unmount force "$MOUNT_POINT"

# Linux
sudo umount "$MOUNT_POINT" 2>/dev/null || gvfs-mount -u "smb://${HOST}/${SHARE}"
```

Windows: no-op.

Log any unmount failure but do not treat it as a sibling-level error — the
citation batch has already been written.

## Phase 1 testing scope

This phase hand-verifies the **macOS** branch only. Linux and Windows
branches ship as reference implementations and are marked for follow-up
testing. This is called out in the orchestrator's verification plan.

## References

- `references/discovery-patterns.md` — filename patterns per control family
- `references/evidence-schema.md` — citation batch format, file naming
- `references/mount-cheatsheet.md` — per-OS mount commands, unmount commands,
  credential helper specifics
