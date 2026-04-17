# Qualys IaC Security GitHub Action (Enhanced)

Enhanced fork of [Qualys/github_action_qiac](https://github.com/Qualys/github_action_qiac) that adds `policy_name` support for scanning against custom TotalCloud policies.

## What's Different

The official Qualys IaC action always evaluates against the default policy. This fork exposes the `--policy_name` (`-pn`) flag from the `qiac` CLI, allowing you to specify a custom **Build time** TotalCloud policy by name.

## Prerequisites

1. Valid Qualys credentials (username/password or OIDC Client ID/Secret) with a TotalCloud subscription.
2. Use `actions/checkout@v4` with `fetch-depth: 0` before this action.
3. Store credentials as GitHub Actions secrets: `URL` plus either `USERNAME`/`PASSWORD` (basic auth) or `QUALYS_CLIENT_ID`/`QUALYS_CLIENT_SECRET` (OIDC auth).
4. Self-hosted runners must use Linux with Docker installed (or use the [composite variant](#runners-without-docker) if Docker is unavailable).

## Platform URLs

The `URL` secret must use the **qualysguard** format for your platform:

| Platform | URL |
|----------|-----|
| US Platform 1 | `https://qualysguard.qualys.com` |
| US Platform 2 | `https://qualysguard.qg2.apps.qualys.com` |
| US Platform 3 | `https://qualysguard.qg3.apps.qualys.com` |
| US Platform 4 | `https://qualysguard.qg4.apps.qualys.com` |
| EU Platform 1 | `https://qualysguard.qualys.eu` |
| EU Platform 2 | `https://qualysguard.qg2.apps.qualys.eu` |
| EU Platform 3 (Italy) | `https://qualysguard.qg3.apps.qualys.it` |
| India Platform | `https://qualysguard.qg1.apps.qualys.in` |
| Canada Platform | `https://qualysguard.qg1.apps.qualys.ca` |
| UAE Platform | `https://qualysguard.qg1.apps.qualys.ae` |
| Australia Platform | `https://qualysguard.qg1.apps.qualys.com.au` |
| UK Platform | `https://qualysguard.qg1.apps.qualys.co.uk` |
| KSA Platform | `https://qualysguard.qg1.apps.qualysksa.com` |

> **Note:** Do not use `gateway` or `qualysapi` URLs. The `qiac` CLI requires the `qualysguard` URL format.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `directory` | IaC root directory to scan | No | `.` |
| `policy_name` | Qualys TotalCloud policy name (Build time execution type) | No | _(default policy)_ |
| `timeout` | Maximum seconds to wait for scan results | No | `600` (10 min) |
| `polling_interval` | Seconds between scan status checks (minimum 30) | No | `30` |
| `source_id` | TotalCloud source connector UUID — links scans to a source in the Qualys portal | No | _(none)_ |
| `max_critical` | Max CRITICAL findings allowed before failing the build | No | _(unlimited)_ |
| `max_high` | Max HIGH findings allowed before failing the build | No | _(unlimited)_ |
| `max_medium` | Max MEDIUM findings allowed before failing the build | No | _(unlimited)_ |
| `max_low` | Max LOW findings allowed before failing the build | No | _(unlimited)_ |
| `auth_type` | Authentication type: `basic` or `oidc` | No | `basic` |

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `URL` | Qualys platform URL (see table above) | Yes |
| `UNAME` | Qualys username | Yes (basic auth) |
| `PASS` | Qualys password | Yes (basic auth) |
| `CLIENTID` | Qualys Client ID | Yes (OIDC auth) |
| `CLIENTSECRET` | Qualys Client Secret | Yes (OIDC auth) |
| `failBuild` | Set to `false` to always pass the workflow regardless of findings | No (default: `true`) |

## Authentication

### Basic Auth (default)

The default authentication uses a Qualys username and password. Store them as GitHub Actions secrets and pass them as environment variables:

```yaml
      env:
        URL: ${{ secrets.URL }}
        UNAME: ${{ secrets.USERNAME }}
        PASS: ${{ secrets.PASSWORD }}
```

### OIDC Auth

OIDC authentication uses a Client ID and Client Secret instead of a username and password. The `qiac` CLI exchanges these for a short-lived JWT token automatically. Set `auth_type` to `oidc` and provide `CLIENTID` and `CLIENTSECRET` as environment variables:

```yaml
      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          CLIENTID: ${{ secrets.QUALYS_CLIENT_ID }}
          CLIENTSECRET: ${{ secrets.QUALYS_CLIENT_SECRET }}
        with:
          auth_type: 'oidc'
          policy_name: 'AWS DISA STIG Build Controls'
```

#### Qualys Managed Tokens (recommended for CI/CD)

The simplest way to get a Client ID and Client Secret is through Qualys Managed Tokens. No external Identity Provider is needed.

1. Log in to the Qualys portal (requires UI 4.0)
2. Click the User icon > **View Profile**
3. Open the **Auth ID Client Management** section
4. Select the **Subscription Level** tab (recommended for CI/CD — not tied to a specific user)
5. Click **New Client**
6. Enter a name (e.g., "GitHub Actions IaC Scanning")
7. Assign permissions for the TotalCloud module
8. Click **Create** and copy the **Client Secret** (shown only once)
9. Copy the **Client ID** from the client list
10. Store both as GitHub Actions secrets (`QUALYS_CLIENT_ID` and `QUALYS_CLIENT_SECRET`)

Subscription-level clients support granular per-module permissions and are not invalidated when individual user accounts are deactivated, making them ideal for CI/CD pipelines.

#### External Identity Provider (Okta, Azure AD)

If your organization uses an external IdP, you can configure OIDC through Qualys Support:

1. Contact Qualys Support to request OIDC activation
2. Provide your IdP details: Entity ID, SSO URL, and signing certificates (or JWKS URL)
3. Once enabled (~1 week), you receive a Client ID and Client Secret
4. Use them the same way as Qualys Managed Tokens above

Supported IdPs include **Okta** and **Microsoft Entra (Azure AD)**. See the [Qualys OIDC documentation](https://docs.qualys.com/en/edr/latest/mergedProjects/edr_api/mergedProjects/subscription_info_api_guide/oauth/oauth_oidc.htm) for details.

## Usage Examples

### Basic scan (default policy)

```yaml
name: Qualys IaC Scan
on:
  push:
    branches: [main]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
```

### Scan with a custom policy (AWS)

```yaml
      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
        with:
          policy_name: 'AWS DISA STIG Build Controls'
```

### Scan with a custom policy (Azure)

```yaml
      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
        with:
          policy_name: 'Azure Dev Best Practices'
```

> **Note:** The policy name must match a **Build time** policy exactly. Runtime policies will not work. See [Build Time vs Runtime Policies](#build-time-vs-runtime-policies).

### Scan a specific directory with custom policy

```yaml
      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
        with:
          directory: 'terraform/'
          policy_name: 'My Custom Policy'
```

### Upload SARIF results to GitHub Security tab

```yaml
name: Qualys IaC Scan
on:
  push:
    branches: [main]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
        with:
          policy_name: 'Azure CIS Build Controls'

      - name: Upload SARIF file
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: response.sarif
```

### Custom timeout and polling interval

```yaml
name: Qualys IaC Scan
on:
  push:
    branches: [main]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
        with:
          timeout: '1800'
          polling_interval: '60'
```

### Severity thresholds (quality gate)

Fail the build only when findings exceed specific limits. For example, block on any critical findings but allow up to 5 high:

```yaml
      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
        with:
          policy_name: 'Azure Dev Best Practices'
          max_critical: '0'
          max_high: '5'
```

When a threshold is exceeded, the output includes a severity summary and the specific threshold that was breached. Thresholds left empty are unlimited — only the levels you set are enforced.

## Supported File Types

- **Terraform:** `.tf`, `.json`
- **CloudFormation:** `.template`, `.yml`, `.yaml`

## Performance

The scan runs inside a Docker container on the GitHub Actions runner. To reduce scan time:

- **Use a custom policy** with only the controls you need, rather than scanning against the full default policy.
- **Increase `timeout`** if scans are timing out on large repos (default is 600s / 10 min).
- **Use larger runners** — GitHub offers [larger hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/using-larger-runners) for Teams/Enterprise plans. Self-hosted runners can be sized to your needs.

Container resource limits are controlled by the runner, not the action.

## Runners Without Docker

If your self-hosted runners don't have Docker (e.g., Azure private runners), use the **composite variant** which installs Python and the `qiac` CLI directly on the runner — no Docker required:

```yaml
      - name: Qualys IaC Scan
        uses: nelssec/qualys-iac/composite@v1
        env:
          URL: ${{ secrets.URL }}
          UNAME: ${{ secrets.USERNAME }}
          PASS: ${{ secrets.PASSWORD }}
        with:
          policy_name: 'Azure Dev Best Practices'
```

The composite variant supports all the same inputs (`directory`, `policy_name`, `timeout`, `polling_interval`, `auth_type`) plus an optional `python_version` input (default `3.12`).

> **Note:** The composite variant requires the runner to be able to install Python via `actions/setup-python` and pip packages. If the runner has no internet access, you'll need to pre-install Python and the `Qualys-IaC-Security` pip package on the runner image.

## Troubleshooting

### Scan does not progress past SUBMITTED

If the scan is accepted but the status never advances beyond SUBMITTED before the polling timeout expires, the issue is on the Qualys platform side — scan processing happens server-side, not on your runner. Check the following:

- **Policy has no controls** — verify the Build time policy contains at least one control in TotalCloud.
- **Control/file type mismatch** — ensure the policy includes controls relevant to your IaC templates (e.g., an Azure-only policy won't evaluate AWS Terraform files).
- **Platform processing delay** — occasionally the backend queue is slow. Increase `timeout` and retry.

If the problem continues, provide the Scan ID from the workflow logs when contacting Qualys support.

### Policy not found error

If the scan fails immediately with a `NOT_FOUND` error, the policy name either doesn't exist or is not a **Build time** policy. Only Build time policies can be used with IaC scanning — Runtime policies are not supported.

To check your policy type:

1. Open **TotalCloud** > **Policies** in the Qualys portal
2. Look at the **Execution Type** column
3. Confirm the policy is marked **Build time**

If the policy you need is Runtime-only, create a new Build time policy with the same controls.

### Authentication or connection failures

If the scan fails before launching with an authentication or connection error:

- **Wrong URL format** — the `URL` secret must use the `qualysguard` format (e.g., `https://qualysguard.qg2.apps.qualys.com`). Using `gateway` or `qualysapi` URLs will fail. See the [Platform URLs](#platform-urls) table.
- **Invalid credentials** — for basic auth, verify `UNAME` and `PASS` secrets are correct and the account is not locked or expired. For OIDC auth, verify `CLIENTID` and `CLIENTSECRET` are correct.
- **OIDC token errors** — if using `auth_type: 'oidc'`:
  - **400 Invalid Signature** — the Client Secret may be incorrect, or JWKS certificates are out of sync. Regenerate the client credentials in the Qualys portal.
  - **401 Invalid Token** — the JWT token has expired or is malformed. This usually means the Client ID or Client Secret is wrong.
  - **403 Permission Denied** — the OIDC client does not have sufficient permissions. Verify the client has TotalCloud module access in Auth ID Client Management.
- **Proxy or firewall** — if the runner cannot reach the Qualys platform, check network rules. The `qiac` CLI does not retry on connection failures.

### No files scanned on push or pull request

On `push` and `pull_request` events, only changed or newly added files are scanned. If no supported file types (`.tf`, `.json`, `.template`, `.yml`, `.yaml`) were modified in the commit, the action exits with "There are no files/folders to scan" and produces an empty SARIF result. This is expected behavior.

### Scan completes but no findings reported

If the scan finishes successfully but reports zero findings:

- **Policy scope** — the policy may not include controls relevant to the resources in your templates. Review the policy's control list in TotalCloud.
- **File types** — only Terraform and CloudFormation files are scanned. Other IaC formats (Ansible, Pulumi, etc.) are not supported.
- **Directory path** — if using the `directory` input, confirm the path is correct relative to the repo root.

### Docker not available on self-hosted runner

If the workflow fails with a Docker-related error on a self-hosted runner, use the [composite variant](#runners-without-docker) (`nelssec/qualys-iac/composite@v1`) which runs directly on the runner without Docker.

### SARIF upload fails

If the `github/codeql-action/upload-sarif` step fails after the scan, ensure the `response.sarif` file exists in the workspace. The action always generates this file — even when no findings are detected — but if the scan itself crashes, the file may be missing. Use `if: always()` on the upload step to ensure it runs regardless of the scan outcome.

## Important Notes

- The `policy_name` must **exactly match** an existing policy in your Qualys subscription (case-sensitive).
- The policy must be a **Build time** execution type — Runtime policies will not work (see above).
- On `push` and `pull_request` events, only changed/added files are scanned.
- On `schedule` and `workflow_dispatch` events, the entire directory (or repo) is scanned.
- **Self-hosted runners** without Docker can use the [composite variant](#runners-without-docker).

## License

MIT - see [LICENSE](LICENSE). Original work copyright Qualys, Inc.
