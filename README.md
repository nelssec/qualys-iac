# Qualys IaC Security GitHub Action (Enhanced)

Enhanced fork of [Qualys/github_action_qiac](https://github.com/Qualys/github_action_qiac) that adds `policy_name` support for scanning against custom TotalCloud policies.

## What's Different

The official Qualys IaC action always evaluates against the default policy. This fork exposes the `--policy_name` (`-pn`) flag from the `qiac` CLI, allowing you to specify a custom **Build time** TotalCloud policy by name.

## Prerequisites

1. Valid Qualys credentials with a TotalCloud subscription.
2. Use `actions/checkout@v4` with `fetch-depth: 0` before this action.
3. Store `URL`, `USERNAME`, and `PASSWORD` as GitHub Actions secrets.
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

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `URL` | Qualys platform URL (see table above) | Yes |
| `UNAME` | Qualys username | Yes |
| `PASS` | Qualys password | Yes |
| `failBuild` | Set to `false` to always pass the workflow regardless of findings | No (default: `true`) |

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
          policy_name: 'Azure Dev MVP'
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
          policy_name: 'Azure Dev MVP'
```

The composite variant supports all the same inputs (`directory`, `policy_name`, `timeout`, `polling_interval`) plus an optional `python_version` input (default `3.12`).

> **Note:** The composite variant requires the runner to be able to install Python via `actions/setup-python` and pip packages. If the runner has no internet access, you'll need to pre-install Python and the `Qualys-IaC-Security` pip package on the runner image.

## Troubleshooting

### Scan stuck in SUBMITTED

If a scan launches but stays in SUBMITTED until it times out:

```
The scan status is: SUBMITTED
Polling timeout of 600 seconds reached.
```

This means the Qualys backend accepted the scan but never started processing it. Common causes:

- **Empty policy** — the Build time policy has no controls assigned. Open the policy in TotalCloud and verify it contains controls.
- **No matching controls** — the policy has controls but none apply to the file types in your repo (e.g., Azure controls but only AWS Terraform files).
- **Qualys backend queue** — transient delay on the Qualys side. Try increasing `timeout` (e.g., `timeout: '1800'`) and retry.

The scan runs server-side on Qualys infrastructure, not on your runner. If the issue persists, contact Qualys support with the Scan ID from the log output.

## Build Time vs Runtime Policies

The `policy_name` input **only works with Build time policies**. If you pass a Runtime policy name, the scan will fail with:

```
The API request failed :
{"errorCode":"NOT_FOUND",
 "message":"There is no build time policy with title 'Your Policy Name'."}
```

To verify your policy type in the Qualys portal:

1. Navigate to **TotalCloud** > **Policies**
2. Check the **Execution Type** column
3. Only policies marked **Build time** can be used with this action

If you need to scan against controls from a Runtime policy, create a new **Build time** policy in TotalCloud with the same controls.

## Important Notes

- The `policy_name` must **exactly match** an existing policy in your Qualys subscription (case-sensitive).
- The policy must be a **Build time** execution type — Runtime policies will not work (see above).
- On `push` and `pull_request` events, only changed/added files are scanned.
- On `schedule` and `workflow_dispatch` events, the entire directory (or repo) is scanned.
- **Self-hosted runners** without Docker can use the [composite variant](#runners-without-docker).

## License

MIT - see [LICENSE](LICENSE). Original work copyright Qualys, Inc.
