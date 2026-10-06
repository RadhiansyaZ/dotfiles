# Decision log

Resolve these choices before starting dependent work. Record the selected option, rationale, and date in this file.

## DEC-001 – Existing machine-local Zed data in Git history

Status: `approved`

Options:

1. **Remove from the current tree only** – lowest disruption, but prior commits retain the metadata.
2. **Rewrite repository history** – removes historical copies, but requires coordinated force-push and fresh clones or rebases.

Recommendation: remove from the current tree immediately. Use history rewriting only if the exposed metadata is considered sensitive enough to justify repository-wide disruption.

Decision: Current-tree removal only. Preserve history; historical metadata remains. No rewrite or force push is authorized. Approved on 2026-10-06.

## DEC-002 – WezTerm support model

Status: `approved`

Options:

1. **Windows-only managed configuration** – keep the PowerShell link, remove Unix Stow claims, and retain the WSL-specific default domain.
2. **Cross-platform managed configuration** – make domain selection platform-aware, add WezTerm to Unix Stow deployment, and test Windows, macOS, and Linux behavior.

Recommendation: choose Windows-only unless active macOS or native Linux WezTerm use requires shared provisioning. This is the smaller and safer correction.

Decision: Cross-platform managed configuration. Make platform defaults conditional and add Unix GNU Stow delivery. Remove unused plugin provisioning; plugin restoration is not requested. Approved on 2026-10-06.

## DEC-003 – Krew scope

Status: `approved`

Options:

1. **PATH support only** – document that Krew is manually installed and the shell only exposes its standard binary directory.
2. **Provision Krew** – add an idempotent supported-platform installer and document Krew in the machine tooling inventory.

Recommendation: PATH support only unless reproducible Kubernetes workstation setup is a current repository goal.

Decision: Full idempotent Krew provisioning on supported Unix platforms. Document installation and tooling inventory, with focused tests. Follow-up approval limits provisioning to macOS, Debian/Ubuntu, and WSL; native Windows is excluded and kubectl remains an externally installed prerequisite. Approved on 2026-10-06.

## DEC-004 – Legacy helper scripts

Status: `approved`

Options:

1. **Remove `fonts.sh` and `tpm.sh`** – use Ansible as the single provisioning path.
2. **Retain as recovery tools** – document their invocation, scope, and verification separately from normal setup.

Recommendation: remove them because their behavior is already represented in Ansible.

Decision: Remove fonts.sh and tpm.sh. Keep Ansible as the provisioning path and update ownership/documentation. Approved on 2026-10-06.

## DEC-005 – Existing Pi settings change

Status: `approved`

Options:

1. Commit the changelog-version update separately before remediation.
2. Revert it before remediation.
3. Leave it unstaged and exclude it from every remediation commit.

Recommendation: commit or revert it separately so phase diffs and verification remain unambiguous.

Decision: Leave the existing Pi edit unstaged and excluded through a new worktree/branch, as authorized by the maintainer. Apply the same exclusion to the existing zsh edit. Original-checkout files must not be copied, reverted, modified, or staged. Approved on 2026-10-06.
