# Package management ideas

Status: proposal only. No installer, package selection, or update policy is changed by this document.

## Direction agreed before research

- Prioritize package lifecycle management: installation, versions, upgrades, verification, removal, and recovery.
- Compare broad alternatives, including changes to the current toolchain.
- Prefer reproducible versions over automatically following current releases.

## Recommendation

Use **a small validated YAML catalogue for package identity, ownership, platform intent, and verification**, alongside **the chosen installer's native version and lock files**. Keep the [machine tooling wiki](../wiki/machine-tooling.md) as the human-readable platform guide; eventually generate its inventory tables from those sources.

Pilot **mise for runtimes and selected CLI tools**, with locked installation and explicit backends. Retain Ansible for Unix provisioning, GNU Stow for repository-backed home configuration, and PowerShell for native Windows provisioning. Evaluate **Nix as the stronger Unix alternative** if the required guarantee includes dependency closures and build inputs. Aqua is a credible narrower option for release-binary tools, especially if native YAML configuration is a priority.

This recommendation is conditional on a clean-machine pilot. Exact-version declarations alone do not establish reproducibility. Homebrew, ordinary APT repositories, and Winget need explicit limitations or additional infrastructure; the proposal does not assume approval for rolling-version exceptions.

A simpler first step is to pin existing Ansible inputs and fix version checks. That reduces risk immediately and avoids introducing a new manager before its value is demonstrated.

## 1. What the repository currently does

The wiki is useful as a comparison, but cannot enforce installation policy. The executable sources show several distinct lifecycle behaviors:

| Evidence | Current behavior | Consequence |
| --- | --- | --- |
| [Shared variables](../../ansible/group_vars/all.yml) | Package lists and release patterns already use YAML; shared npm and Go tools lack exact versions | Converting more lists to YAML alone leaves the lifecycle unchanged |
| [Shared tasks](../../ansible/tasks/common.yml) | `go install ...@latest` is guarded by binary existence | Fresh machines resolve new versions; existing machines retain old ones |
| [macOS tasks](../../ansible/tasks/macos.yml) | Runs `brew bundle`, selects Node LTS, installs unversioned npm globals | Setup can change installed versions |
| [Linux tasks](../../ansible/tasks/linux.yml) | APT packages use `state: present`; several upstream installers run only when commands are missing | Presence is checked more consistently than the requested version |
| [GitHub release installer](../../ansible/tasks/linux_github_binary.yml) | Queries the latest release when missing; downloads without a declared checksum; missing assets/binaries produce debug messages | No recorded artifact identity; some installation gaps do not fail setup |
| [Neovim installer](../../ansible/tasks/linux_nvim.yml) | Preserves the full runtime tree, but resolves latest only when `nvim` is missing | A replacement must preserve runtime files and improve version reconciliation |
| [Windows manifest](../../windows/packages/packages.winget.json) and [setup](../../setup-windows.ps1) | Manifest packages have no `Version`; import uses `--ignore-versions`; import exit status is not checked before the completion message | Adding versions to JSON alone would have no effect; completion does not prove success |
| [Windows setup](../../setup-windows.ps1) | Also installs `glowm` through `go install ...@latest` when absent | Winget is not the only Windows package source |
| [Unix bootstrap](../../setup.sh) | macOS bootstraps/upgrades Ansible tooling through unpinned pip installs | Reproducing packages also requires controlling the provisioner |

There is also potential competing ownership: Linux declares a downloaded `tree-sitter` binary while shared npm packages include `tree-sitter-cli`. The effective command depends on installation and PATH ordering. An ownership check should detect this before changing either installer.

The current wiki's explanation that Homebrew Bundle cannot consume Go/npm entries is also out of step with current upstream documentation, which lists both types [1]. The repository still filters those entries and uses its own tasks. Preserve that distinction between current repository behavior and upstream capability; expanding Bundle support would not solve its version-locking limits.

## 2. Define the reproducibility guarantee

Use explicit levels so reports do not overstate what a backend provides:

| Level | Required evidence |
| --- | --- |
| Package selection | Same intended tools for a named platform/profile |
| Exact version | Same resolved versions, with no fallback to latest |
| Artifact identity | Same platform-specific downloaded bytes, verified against reviewed hashes |
| Dependency environment | Locked transitive dependencies, runtime/build inputs, and relevant OS assumptions |

Target artifact identity for managed development tools, and dependency-environment locking where the backend supports it. Record the achieved level per tool. Identical bytes across different operating systems are not a meaningful goal; each supported OS/architecture needs its own resolved artifacts.

A clean restore must either install the reviewed selection or fail with an actionable reason. A deleted release, missing architecture, unsupported downgrade, or checksum mismatch must never cause an automatic switch to another version.

Long-term restore also needs artifact availability. Lockfiles do not preserve downloads. If restoring old revisions years later is required, evaluate a retained artifact cache or mirror, licensing permissions, and backup policy separately.

## 3. Options and trade-offs

| Approach | Reproducibility potential | Repository fit | Main cost or limitation |
| --- | --- | --- | --- |
| Strengthen existing Ansible + Homebrew + Winget | Exact versions/hashes for custom tasks; native-manager limitations remain | Smallest migration; existing platform boundaries stay intact | Repository owns version comparison, download selection, checksums, upgrade and rollback logic |
| mise + native OS managers | Locked versions and artifacts for supported backends; some backends support dependency graphs [2] | Candidate to consolidate NVM, direct Go installs, and selected CLI installers | TOML rather than YAML; guarantees vary by backend and tool; shell/PATH migration required |
| aqua + separate runtime management | Exact CLI versions, pinned registry, reviewed checksums [3][4] | Strong candidate for GitHub-release binaries; native YAML | Adds another manager if runtimes remain elsewhere; platform coverage varies by tool |
| Nix for Unix packages + native Windows provisioning | Locked package definitions and dependency graphs; stronger control of Unix environments [5] | Relevant to the stated reproducibility priority | Largest learning/migration cost; native Windows remains separate; package availability and host integration need testing |
| Homebrew Bundle across macOS/Linux/WSL | Declarative selection; arbitrary historical version restoration is not guaranteed [1] | Could reduce platform-specific declarations | Does not meet the reproducibility goal by itself; changes the current macOS-only Brewfile contract |
| Pinned containers or VM images | Captures more of the OS/dependency environment | Useful for verification and project environments | Does not manage the host's native terminals, editors, and desktop applications |

### mise: preferred pilot

Current documentation provides `mise lock` and `mise install --locked`, with platform entries and backend-specific artifact metadata [2]. Pin the mise release used by the pilot and verify those capabilities in that release before depending on them.

Important limits:

- Strict URL locking applies only to supporting backends. A successful locked install is not proof that all build inputs or transitive dependencies are frozen.
- Current documentation describes dependency sidecars for certain npm/Python installers. Commit required sidecars and test their integrity checks. Other language backends may lock only the top-level version.
- Source builds and package lifecycle scripts can still produce different outputs.
- Select explicit backends and inspect the resulting lock entries. Review backend changes as installation-source changes.
- Populate entries for every supported target. Native Windows support of the manager does not imply support for every tool/backend.
- Do not install aqua separately merely because mise uses an aqua backend. One installation owner per command is the goal.

### aqua: narrower YAML-native alternative

Aqua separates package declarations from `aqua-checksums.json`. Pin the registry revision and each package version, enable checksum verification, and require pre-recorded checksums [3][4]. In aqua v2, `require_checksum: true` rejects missing checksum entries; generate and review them during an explicit update step.

An initially computed checksum records downloaded bytes. Without a trusted upstream signature/checksum, it does not establish their provenance. Native Windows support has tool-specific gaps, including shell-script tools [6]. Keep unsupported targets explicit rather than treating skipped installation as success.

### Nix: strongest Unix candidate in this comparison

A pinned Nixpkgs input can control a larger dependency environment than a catalogue of downloaded executables. A flake lockfile pins inputs; flakes are still described as experimental in upstream documentation [5]. Nix documents Linux and macOS host support, with Windows use through WSL rather than native Windows [7].

If selected, use Nix for package installation initially. Keep repository configuration under Stow. Do not introduce Home Manager file ownership alongside Stow without a separate migration decision. Locking Nix inputs still does not guarantee every build is bit-for-bit reproducible or every historical source remains downloadable.

## 4. Where YAML helps

YAML is a suitable format for a small catalogue because Ansible already consumes it, it supports comments, and it can be validated against a schema. Its value comes from validation and consumers. An unused second inventory would add maintenance.

Separate ownership of facts:

| Fact | Authoritative source in the proposal |
| --- | --- |
| Logical tool ID, command names, install/config intent, platform support, verification | `packages/catalogue.yml` |
| Requested version and backend-specific options | One native manifest per selected installer |
| Resolved version, artifact hashes, dependency graph | Native lockfile/checksum sidecars where available |
| Custom installer without native locking | Small versioned artifact record consumed by the existing Ansible task |
| Observed installed path/version and installation ownership receipt | Machine-local state, outside tracked files |
| Platform rationale and exception explanations | Human-written documentation |

These are proposed paths, not files added by this task. Do not copy native lockfile contents into a second universal lockfile. A catalogue should reference native entries and resolve them when generating reports.

### Illustrative catalogue shape

This is a design sketch, not an executable configuration. It illustrates one possible mise pilot without selecting real versions or expanding current native Windows scope.

```yaml
schema_version: 1

tools:
  node:
    commands: [node, npm]
    targets:
      macos:
        install:
          owner: mise
          manifest: packages/unix/mise.toml
          entry: node
      linux:
        install:
          owner: mise
          manifest: packages/unix/mise.toml
          entry: node
      windows:
        install: null
        reason: Native setup currently installs NVM for Windows only.
    verify:
      argv: [node, --version]
      parser: node-semver
      expectation: resolved-version

  wezterm:
    commands: [wezterm]
    targets:
      macos:
        install: null
        configuration: stow
      linux:
        install: null
        configuration: stow
      windows:
        install: null
        configuration: windows-setup
    reason: Configuration is managed; executable installation is external.

profiles:
  wsl:
    inherits: linux
```

Installation and configuration are separate fields because they can coexist. Add explicit platform/architecture restrictions where required; the existing x86_64-only release selections are an immediate test case. WSL can inherit Linux package intent while retaining its existing SSH and Windows integration rules.

Schema and semantic checks should reject:

- Duplicate YAML keys, unknown fields, and invalid references to native manifest entries.
- Multiple active owners for a command on the same target.
- Managed tools with neither a verification rule nor an explicit verification exception.
- Required targets without supported artifacts or required lock entries.
- Floating versions in exact-version policy, and checksum gaps in artifact-identity policy.
- Generated inventory that disagrees with manifests or silently omits platform exclusions.

Quote version strings. Prefer plain data and argv arrays. Keep arbitrary shell execution and installer recipes out of the catalogue. Use a safe YAML loader; semantic validation still needs code beyond structural schema validation.

## 5. Lifecycle contract

The following are proposed operations, not commands currently implemented:

| Operation | Contract |
| --- | --- |
| Validate | Check catalogue, native manifests, locks, owner uniqueness, and target coverage without changing the host |
| Plan | Show missing tools, version drift, command shadowing, unsupported targets, and proposed actions |
| Apply | Install approved locked selections; never resolve newer versions or rewrite locks during normal setup |
| Update | Explicitly resolve candidate updates, review versions/sources/hashes/dependencies, then test before accepting |
| Verify | Check the selected executable path, actual version, and a minimal functional probe |
| Remove | Preview removal of repository-owned installations; require approval; leave unrelated packages and user data alone |
| Recover | Reapply a previous manifest/lock revision where supported; report unavailable artifacts or unsafe downgrade paths |

An existing command with the wrong version is drift, not success. If it belongs to another manager, stop and show the conflict. Avoid adopting or deleting an existing installation based only on its name.

Normal setup should fail if a required package fails, and report optional exclusions separately. Check native process exit codes in PowerShell before reporting success. Verification must check versions and paths, not only `command -v` or `Get-Command`.

Rollback should be tested for side-by-side CLI/runtime versions. It cannot promise reversal of desktop application data migrations or all system-package downgrades. Removing a declaration should create an orphan/removal proposal, not trigger automatic uninstall or broad package-manager cleanup.

Schedule reviewed security updates even with pinned versions. An urgent update should produce a new approved selection and tests; permanently frozen vulnerable packages are not an acceptable maintenance policy.

## 6. Native-manager limits requiring explicit decisions

### Homebrew

Homebrew explicitly describes itself as rolling-release and does not provide a Brewfile lockfile for arbitrary versions. `--no-upgrade` prevents the upgrade step but does not pin clean installs [1].

Move strict-version development tools to a suitable versioned backend, or investigate maintained historical formulae/artifacts with their operational cost. If Homebrew stays responsible for desktop/system packages, label that as a reproducibility exception requiring approval.

### APT

Exact `name=version` selections depend on repository availability and dependency resolution. Stronger historical restore needs a consistent repository snapshot and a known distro release/architecture [8]. Debian and Ubuntu need separate repository strategies; a Debian snapshot is not an Ubuntu solution. Freezing repository state also requires a deliberate security-update process.

### Winget

Winget import accepts per-package `Version`, but the current `--ignore-versions` overrides those values [9]. Removing that flag is necessary for a versioned import, but insufficient to prove successful downgrade, artifact retention, or application-state recovery.

Winget pins affect Winget upgrades, not an application's own updater [10]. Do not globally disable application security updates to claim reproducibility. Evaluate vendor-supported policy per application and record the limitation. Native Windows keeps its own manifest and execution path even if some CLI management is later shared.

## 7. Phased adoption and verification gates

### Phase 1: define ownership and policy

Catalogue a representative set: Node, Go, a Go-installed CLI, an npm CLI, `tree-sitter`, Neovim, an APT package, a Winget application, and a configured-only application. Identify exact targets and reproducibility levels. Record who owns each command today.

**Gate:** every selected tool maps to an executable source; no duplicate owners or unexplained platform gaps; no provisioning behavior changes yet.

### Phase 2: compare clean-machine pilots

Run mise and the strengthened-existing-task approach against the same small set. Include aqua for release binaries and a Nix Unix proof of concept if dependency-environment locking is required. Pin the managers and bootstrap dependencies themselves.

Test in disposable Linux environments, a macOS runner/VM, and a native Windows environment. Test WSL integration separately where host behavior differs. Include each architecture that will be claimed as supported.

**Gate:** installation produces the expected paths/versions; repeat apply makes no package changes; missing locks and tampered checksums fail; a reviewed update and recovery both work. Record implementation complexity and manual steps. No winner is approved solely from documentation.

### Phase 3: integrate one owner at a time

Move selected declarations to the chosen manager and remove their old installer entries in the same migration. Review PATH and shell activation, including NVM/Go paths and Windows shims. Preserve Neovim runtime files and Debian command-name compatibility.

Keep Ansible/Stow and PowerShell/one-way Windows sync boundaries. Any new Unix repository-backed home symlink must use a Stow package after conflict resolution [11]. Keep downloads, caches, credentials, and observed host state outside the repository.

**Gate:** clean install, repeat apply, version drift detection, command-shadow detection, and existing platform smoke tests pass. No accidental native Windows feature expansion.

### Phase 4: generate inventory and enforce it

Generate a dedicated package table, then link or embed it in the existing wiki. Preserve handwritten explanations of WSL behavior, configuration delivery, and machine-local state. Add a check mode that fails when checked-in generated documentation differs.

**Gate:** changing a package declaration updates the inventory deterministically; invalid references and unsupported required targets fail CI; generated data never includes host-specific state.

### Phase 5: establish update and retention policy

Add reviewed update automation only after manifests and ownership are stable. Retain previous artifacts where long-term restore matters and licensing permits. Keep destructive removal separate from routine setup.

**Gate:** restore a prior approved revision on a clean target. Document any package that cannot meet its declared guarantee and request a policy decision rather than silently weakening it.

## 8. Decisions before implementation

1. Does the required guarantee stop at exact artifacts, or include the full Unix dependency environment? The latter makes a Nix pilot more important.
2. Which OS releases and architectures must clean restoration support?
3. Are explicitly labelled system/desktop exceptions acceptable where exact restore cannot be supported?
4. How long must old revisions remain restorable, and is maintaining an artifact cache worthwhile?

No whole-repository migration is recommended before those decisions and the pilot results. YAML can make the policy inspectable; backend capabilities and verification determine whether it is enforced.

## Sources

Repository evidence is linked in section 1. Upstream documentation describes current capabilities, which must be checked against the exact manager versions selected for a pilot.

1. [Homebrew Bundle and Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile) – supported package types, default upgrades, and explicit lockfile limitations.
2. [mise lockfiles](https://mise.jdx.dev/dev-tools/mise-lock.html) – strict installation, platform entries, backend limits, and dependency sidecars.
3. [aqua checksum verification](https://aquaproj.github.io/docs/reference/security/checksum/) – checksum sources and registry verification.
4. [aqua checksum configuration](https://aquaproj.github.io/docs/reference/config/checksum/) – required checksum behavior and committed checksum files.
5. [Nix flakes](https://nix.dev/concepts/flakes.html) – locked inputs, system-specific outputs, and experimental status.
6. [aqua Windows support](https://aquaproj.github.io/docs/reference/windows-support/) – platform and shell-script limitations.
7. [Nix supported platforms](https://nix.dev/manual/nix/2.30/installation/supported-platforms) – Linux/macOS support and WSL guidance.
8. [APT sources.list](https://manpages.debian.org/testing/apt/sources.list.5.en.html) – repository configuration and snapshot selection; verify support in the target APT version.
9. [Winget import](https://learn.microsoft.com/en-us/windows/package-manager/winget/import) – version fields and ignore-version behavior.
10. [Winget pinning](https://learn.microsoft.com/en-us/windows/package-manager/winget/pinning) – pin behavior and external updater limits.
11. [Repository Stow rules](../stow-packages.md) – configuration ownership and conflict resolution.
