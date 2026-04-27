# SMB Discovery Patterns

Same shape as the SharePoint pattern table — filename patterns mapped to
the 20 control families. Matching is case-insensitive.

| Family | Filename patterns |
|---|---|
| `01-system-design` | `*SDD*`, `*System Design*`, `*Architecture*` |
| `02-system-inventory` | `*Inventory*`, `*CMDB*`, `*Asset*` |
| `03-configuration-management` | `*CMP*`, `*Baseline*`, `*Hardening*`, `*Change Request*` |
| `04-access-control` | `*Access Control*`, `*RBAC*`, `*Access Request*` |
| `05-authentication-session` | `*Authentication*`, `*MFA*`, `*Password Policy*` |
| `06-audit-logging` | `*Audit*`, `*Log Retention*`, `*SIEM*` |
| `07-vulnerability-management` | `*Vulnerability*`, `*Patch*`, `*POA&M*` |
| `08-incident-response` | `*IR*`, `*Incident*`, `*Playbook*` |
| `09-contingency-plan` | `*CP*`, `*Contingency*`, `*DR*`, `*Runbook*`, `*BCP*` |
| `10-security-policies` | `*Policy*`, `*Policies*`, `*SSP*` |
| `11-personnel-security` | `*Personnel*`, `*Background*`, `*Clearance*` |
| `12-security-training` | `*Training*`, `*Awareness*` |
| `13-system-maintenance` | `*Maintenance*`, `*Change Log*` |
| `14-physical-environmental` | `*Physical*`, `*Facility*`, `*Datacenter*` |
| `15-media-protection` | `*Media*`, `*Sanitization*`, `*Disposal*` |
| `16-network-communications` | `*Network*`, `*Firewall*`, `*VPN*` |
| `17-sdlc-secure-development` | `*SDLC*`, `*Code Review*` |
| `18-supply-chain` | `*Supply Chain*`, `*SBOM*`, `*Vendor*` |
| `19-interconnections` | `*ISA*`, `*MOU*`, `*Interconnection*` |
| `20-risk-assessment` | `*Risk Assessment*`, `*Assessment Report*`, `*POA&M*` |

## File type allow list

Only `.docx`, `.doc`, `.pdf`, `.xlsx`, `.xls`, `.pptx`, `.ppt`, `.md`,
`.txt`. Anything else is skipped.

## Directory exclusions

Hard-skip these directories regardless of depth:

- `Archive`, `Archives`, `Old`, `Obsolete`, `Deprecated`
- `Personal`, `My Documents` (user-scoped content is out of scope)
- `Recycle Bin`, `$RECYCLE.BIN`, `.Trash`, `.Trashes`
- Anything matching `Backup*` older than 2 years (use mtime)

## Size and traversal limits

- Max file size: 50 MB — larger files are logged as `too_large`
- Max depth: from config (`smb.depth`, default 3)
- Max files per share: 500 — if exceeded, stop and log `truncated_results`
