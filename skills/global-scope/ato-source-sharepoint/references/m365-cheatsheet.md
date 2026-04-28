# m365 CLI Cheatsheet (read-only allow list)

This sibling may only invoke commands listed below. Any `m365` command not on
this list is forbidden.

Install: `npm install -g @pnp/cli-microsoft365` (docs:
https://github.com/pnp/cli-microsoft365).

## Auth (probe only — never login from inside the skill)

```bash
m365 status --output json
```

Expected shape when logged in:

```json
{
  "connectedAs": "alice@contoso.onmicrosoft.com",
  "authType": "deviceCode",
  "cloudType": "Public"
}
```

If `connectedAs` is null, write `auth_missing` error and exit.

## Site and list discovery

```bash
# List all sites the user can see (only used when scope says "all sites")
m365 spo site list --output json

# Get site details
m365 spo site get --url "https://contoso.sharepoint.com/sites/ato" --output json

# List document libraries on a site
m365 spo list list --webUrl "https://contoso.sharepoint.com/sites/ato" --output json
```

## File discovery

```bash
# List files in a folder (recursive via --recursive)
m365 spo file list \
  --webUrl "https://contoso.sharepoint.com/sites/ato" \
  --folder "/Shared Documents/Current ATO" \
  --recursive \
  --output json

# Get file metadata
m365 spo file get \
  --webUrl "https://contoso.sharepoint.com/sites/ato" \
  --url "/sites/ato/Shared Documents/Current ATO/SSP-v2.docx" \
  --output json
```

## Download

```bash
m365 spo file get \
  --webUrl "https://contoso.sharepoint.com/sites/ato" \
  --url "/sites/ato/Shared Documents/Current ATO/SSP-v2.docx" \
  --asFile \
  --path "docs/ato-package/ssp-sections/06-policies-procedures/evidence/sharepoint_SSP-v2.docx"
```

`--asFile` writes the binary content to the given path. This is the only
command the skill uses that touches the local filesystem outside `.staging/`.

## Forbidden verbs

Never use any of these, even if they appear to be read-only variants:

- `m365 spo file add`, `set`, `remove`, `copy`, `move`, `rename`, `checkin`,
  `checkout`, `approve`, `publish`
- `m365 spo folder add`, `remove`, `rename`
- `m365 spo list add`, `set`, `remove`, any list item mutation
- `m365 spo site add`, `set`, `remove`, `classic`
- `m365 login`, `m365 logout`, `m365 setup` — auth must already be established
- Any `m365 aad *`, `m365 entra *`, or `m365 teams *` mutation verb
- Any command with `--force`, `--confirm`, or similar

If the orchestrator asks you to invoke anything on this list, refuse.

## URL encoding

SharePoint URLs with spaces or `&` need to be URL-encoded when written into
citation `link` fields (spaces → `%20`, `&` → `%26`). The `m365` CLI accepts
both encoded and unencoded forms on input.
