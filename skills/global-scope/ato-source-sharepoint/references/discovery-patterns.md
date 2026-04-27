# SharePoint Discovery Patterns

Maps filename patterns and SharePoint locations to the 20 control families in
`ato-artifact-collector/references/artifact-mappings.md`. When a file matches
multiple patterns, map it to every family that claims it and download-once /
copy-many across `{family}/evidence/`.

Pattern matching is case-insensitive.

## Full pattern table

| Family | Filename patterns | Notes |
|---|---|---|
| `01-system-design` | `*SDD*`, `*System Design*`, `*Architecture*`, `*HLA*`, `*LLA*` | Also pull SSP for design sections |
| `02-system-inventory` | `*Inventory*`, `*CMDB*`, `*Asset List*`, `*Component List*` | |
| `03-configuration-management` | `*CMP*`, `*Configuration Management Plan*`, `*Baseline*`, `*Hardening*` | |
| `04-access-control` | `*Access Control*`, `*RBAC*`, `*Role Matrix*`, `*Access Request*` | |
| `05-authentication-session` | `*Authentication*`, `*MFA*`, `*Session*`, `*Password Policy*` | |
| `06-audit-logging` | `*Audit*`, `*Logging*`, `*Log Retention*`, `*SIEM*` | Exclude "audit findings" → those go to risk-assessment |
| `07-vulnerability-management` | `*Vulnerability*`, `*Patch*`, `*Scan Report*`, `*POA&M*` | POA&M also goes to risk-assessment |
| `08-incident-response` | `*IR*`, `*Incident Response*`, `*IRP*`, `*Playbook*` | |
| `09-contingency-plan` | `*CP*`, `*Contingency*`, `*DR*`, `*Disaster Recovery*`, `*BCP*` | |
| `10-security-policies` | `*Policy*`, `*Policies*`, `*SSP*`, `*System Security Plan*` | |
| `11-personnel-security` | `*Personnel*`, `*Background Check*`, `*Clearance*`, `*Onboarding*` | |
| `12-security-training` | `*Training*`, `*Awareness*`, `*Education*` | |
| `13-system-maintenance` | `*Maintenance*`, `*Patch Schedule*`, `*Change Log*` | |
| `14-physical-environmental` | `*Physical*`, `*Facility*`, `*Datacenter*`, `*Environmental*` | |
| `15-media-protection` | `*Media*`, `*Sanitization*`, `*Disposal*` | |
| `16-network-communications` | `*Network*`, `*Topology*`, `*Firewall*`, `*TLS*`, `*VPN*` | |
| `17-sdlc-secure-development` | `*SDLC*`, `*Secure Development*`, `*Code Review*`, `*SAST*` | |
| `18-supply-chain` | `*Supply Chain*`, `*SBOM*`, `*Vendor*`, `*Third Party*` | |
| `19-interconnections` | `*Interconnection*`, `*ISA*`, `*MOU*`, `*Data Sharing Agreement*` | |
| `20-risk-assessment` | `*Risk Assessment*`, `*RA*`, `*POA&M*`, `*Audit Findings*`, `*Assessment Report*` | |

## Multi-family files

These filename shapes typically belong in multiple families:

| Filename shape | Families |
|---|---|
| `SSP*.docx` | `10-security-policies` (primary), `01-system-design`, `04-access-control`, `05-authentication-session` |
| `POA&M*.xlsx` | `07-vulnerability-management`, `20-risk-assessment` |
| `ATO Package*` | all 20 — treat as an archive, inventory rather than download |
| `Risk Assessment*.docx` | `20-risk-assessment`, `07-vulnerability-management` |

## File types

Only download these extensions (from `file_types` in scope):

- `.docx`, `.doc`
- `.pdf`
- `.xlsx`, `.xls`
- `.pptx`, `.ppt`
- `.md`, `.txt`

Skip: any extension not in the scope's `file_types`, any file larger than
50 MB (log as `partial_failure: too_large`), any file inside a folder named
`Archive*` or `Old*` unless the scope explicitly includes it.

## Exclusions

Hard-skip these regardless of pattern match:
- Files whose name contains `DRAFT` if a same-named non-DRAFT version exists
  in the same folder (prefer the finalized version)
- Files inside `Recycle Bin` or `Preservation Hold Library`
- Files with `.tmp`, `.~lock`, `~$` prefixes (Office lock files)
