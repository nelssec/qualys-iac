# Qualys IaC Security GitHub Action (Enhanced)

Enhanced fork of [Qualys/github_action_qiac](https://github.com/Qualys/github_action_qiac) that adds `policy_name` support for scanning against custom CSA policies.

## What's Different

The official Qualys IaC action always evaluates against the default policy. This fork exposes the `--policy_name` (`-pn`) flag from the `qiac` CLI, allowing you to specify a custom **Build time** CSA policy by name.

## Prerequisites

1. Valid Qualys credentials with a CloudView (CSA) subscription.
2. Use `actions/checkout@v2` (or later) with `fetch-depth: 0` before this action.
3. Store `URL`, `USERNAME`, and `PASSWORD` as GitHub Actions secrets.
4. Self-hosted runners must use Linux with Docker installed.

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
| India Platform | `https://qualysguard.qg1.apps.qualys.in` |
| Canada Platform | `https://qualysguard.qg1.apps.qualys.ca` |
| UAE Platform | `https://qualysguard.qg1.apps.qualys.ae` |
| Australia Platform | `https://qualysguard.qg1.apps.qualys.com.au` |
| UK Platform | `https://qualysguard.qg1.apps.qualys.co.uk` |
| KSA Platform | `https://qualysguard.qg1.apps.qualys.sa` |

> **Note:** Do not use `gateway` or `qualysapi` URLs. The `qiac` CLI requires the `qualysguard` URL format.

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `directory` | IaC root directory to scan | No | `.` |
| `policy_name` | Qualys CSA policy name (Build time execution type) | No | _(default policy)_ |

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

### Scan with a custom policy

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
          policy_name: 'AWS DISA STIG Build Controls'
```

### Scan a specific directory with custom policy

```yaml
name: Qualys IaC Scan
on:
  pull_request:
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
          policy_name: 'AWS DISA STIG Build Controls'

      - name: Upload SARIF file
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: response.sarif
```

## Supported File Types

- **Terraform:** `.tf`, `.json`
- **CloudFormation:** `.template`, `.yml`, `.yaml`

## Important Notes

- The `policy_name` must **exactly match** an existing policy in your Qualys subscription.
- The policy must be a **Build time** execution type.
- On `push` and `pull_request` events, only changed/added files are scanned.
- On `schedule` and `workflow_dispatch` events, the entire directory (or repo) is scanned.

## License

MIT - see [LICENSE](LICENSE). Original work copyright Qualys, Inc.
