# Decision log

Resolve these choices before starting dependent work. Record the selected option, rationale, and date in this file.

## DEC-001 – Existing machine-local Zed data in Git history

Status: `needs-decision`

Options:

1. **Remove from the current tree only** – lowest disruption, but prior commits retain the metadata.
2. **Rewrite repository history** – removes historical copies, but requires coordinated force-push and fresh clones or rebases.

Recommendation: remove from the current tree immediately. Use history rewriting only if the exposed metadata is considered sensitive enough to justify repository-wide disruption.

Decision: _unresolved_

## DEC-002 – WezTerm support model

Status: `needs-decision`

Options:

1. **Windows-only managed configuration** – keep the PowerShell link, remove Unix Stow claims, and retain the WSL-specific default domain.
2. **Cross-platform managed configuration** – make domain selection platform-aware, add WezTerm to Unix Stow deployment, and test Windows, macOS, and Linux behavior.

Recommendation: choose Windows-only unless active macOS or native Linux WezTerm use requires shared provisioning. This is the smaller and safer correction.

Decision: _unresolved_

## DEC-003 – Krew scope

Status: `needs-decision`

Options:

1. **PATH support only** – document that Krew is manually installed and the shell only exposes its standard binary directory.
2. **Provision Krew** – add an idempotent supported-platform installer and document Krew in the machine tooling inventory.

Recommendation: PATH support only unless reproducible Kubernetes workstation setup is a current repository goal.

Decision: _unresolved_

## DEC-004 – Legacy helper scripts

Status: `needs-decision`

Options:

1. **Remove `fonts.sh` and `tpm.sh`** – use Ansible as the single provisioning path.
2. **Retain as recovery tools** – document their invocation, scope, and verification separately from normal setup.

Recommendation: remove them because their behavior is already represented in Ansible.

Decision: _unresolved_

## DEC-005 – Existing Pi settings change

Status: `needs-decision`

Options:

1. Commit the changelog-version update separately before remediation.
2. Revert it before remediation.
3. Leave it unstaged and exclude it from every remediation commit.

Recommendation: commit or revert it separately so phase diffs and verification remain unambiguous.

Decision: _unresolved_
