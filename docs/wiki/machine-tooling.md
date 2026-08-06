---
title: Machine tooling comparison
source_files:
  - Brewfile
  - ansible/group_vars/all.yml
  - ansible/tasks/linux.yml
  - ansible/tasks/macos.yml
  - windows/packages/packages.winget.json
  - setup-windows.ps1
  - sync-win.ps1
last_reviewed: 2026-08-05
---
# Machine tooling comparison

Use this as a **difference-first** inventory. It separates tools that the repository
installs from tools it merely configures, so a missing command can be traced to the
right machine-specific source.

**Status legend**

- **Installed** — the stated bootstrap path installs it.
- **Configured only** — configuration is deployed, but this repository does not install
  the application.
- **Not provisioned** — no installation or configuration is supplied for that machine.
- **Manual prerequisite** — needed by the bootstrap but intentionally supplied outside
  the normal package list.

## 1. Machine contract at a glance

| Machine | Bootstrap command | Installer(s) | Configuration delivery | Important boundary |
| --- | --- | --- | --- | --- |
| **macOS** | `./setup.sh` | Ansible, Homebrew Bundle, NVM, direct Go installer | GNU Stow | The Brewfile is macOS-only. |
| **Debian/Ubuntu** | `./setup.sh` | Ansible, APT, upstream installers/releases, NVM | GNU Stow | Targets Debian-family Linux only. |
| **WSL (Debian)** | `./setup.ps1`, then `./setup.sh` inside WSL | Windows bootstrap plus the Debian/Ubuntu path | Stow, except native copied SSH config | WSL is the full Unix development environment. |
| **Native Windows** | Elevated `./setup.ps1` or `./setup-windows.ps1` | Winget | Symlinks plus selected one-way copies | Does not replace the Unix/WSL toolchain. |

### Fastest way to locate a discrepancy

| If you are comparing… | Start here |
| --- | --- |
| A command available on macOS but not Linux | [macOS-only tools](#3-macos-only-tools) and [Linux-only tools](#4-linuxwsl-only-tools) |
| A command expected in native Windows | [Native Windows differences](#5-native-windows-differences) |
| A tool that has a config but no executable | [Configured-only applications](#6-configured-only-applications) |
| Node, Go, agent, or editor behavior | [Runtime and agent differences](#7-runtime-editor-and-agent-differences) |
| The exact package declaration to change | [Sources of truth](#9-sources-of-truth-and-maintenance) |
| Upstream package, repository, release, or manifest link | [Installation source catalogue](#10-installation-source-catalogue) |

## 2. Cross-machine parity matrix

This table shows the intended command availability after the relevant bootstrap.
“Installed” does not mean that a tool has the same package manager or version on every
machine.

| Tool or capability | macOS | Debian/Ubuntu + WSL | Native Windows | Difference to know |
| --- | --- | --- | --- | --- |
| `git` | Manual prerequisite (Xcode tooling normally supplies it) | Manual prerequisite | Installed | Unix playbooks do not install Git explicitly. |
| `zsh` | Configured only; assumed available | Installed | Not provisioned | Native Windows uses PowerShell. |
| `stow` | Installed | Installed | Not provisioned | Windows uses symlinks/copies instead. |
| `tmux` / TPM | Installed | Installed | Not provisioned | Use WSL for tmux. |
| `starship`, `fzf`, `zoxide` | Installed | Installed | Installed | Shared prompt behavior; PowerShell caches its initialization. |
| `bat`, `fd`, `ripgrep`, `eza`, `jq`, `tree`, `htop` | Installed | Installed | `bat`, `fd`, `ripgrep`, `eza`, `jq` installed; `tree` and `htop` not provisioned | Linux exposes Debian names as `bat` and `fd` links. |
| `gh`, `lazygit` | Installed | Installed | Installed | Linux obtains both from upstream releases/repositories. |
| `lazysql`, `htmlq`, `saml2aws`, `act`, `actionlint`, `dbmate` | Installed | Installed | Not provisioned | Linux uses GitHub releases/direct binary; two release assets are x86_64-only. |
| `aws` | Installed | Installed | Installed | AWS CLI v2 is a direct Linux installer. |
| `go` and Go tools | Installed | Installed | Go installed; shared Go tools not provisioned | Windows does not run the Unix shared Go-tools task. |
| Node runtime | Node LTS via NVM | Node LTS via NVM | NVM for Windows only | Windows setup does **not** install a Node version. |
| `pnpm`, `uv`, Python | Installed | Installed | Installed | macOS/Linux/WSL also install `pyenv`; native Windows uses winget Python. |
| Neovim | Installed | Installed | Installed | Linux downloads the full latest release rather than APT Neovim. |
| Zed | Configured only | Configured only | Installed and configured | Windows copies settings; Unix Stow deploys them. |
| Pi, Codex, Context Mode | npm global packages installed | npm global packages installed | Configured only | Windows manifest has no Node runtime or global agent packages. |
| OpenCode | Installed | Configured only | Not provisioned | Only macOS Brewfile installs OpenCode. |
| WezTerm | Configured only | Configured only | Configured only | `glowm-wezterm` is an experimental inline-Mermaid wrapper. |
| `glowm` + Chrome/Chromium | Installed | Installed | Installed | Mermaid rendering needs the browser; use `glowm-wezterm` in WezTerm. |
| Ghostty | Configured only | Configured only | Not provisioned | No installer is declared. |

## 3. macOS-only tools

### Installed only on macOS

`Brewfile` supplies tools that have no matching Debian/WSL or Windows provisioner:

- Infrastructure and utility: `terragrunt`, `vegeta`, and `rtk`.
- Database/client support: `libpq`.
- Desktop or media tooling: `mpv` plus the Bruno, DBeaver Community, and TFLint casks.
- Editor integrations: the VS Code extensions declared in `Brewfile`.
- AI CLI: `opencode` from `anomalyco/tap`.

macOS also installs `curl`, `pass`, `pre-commit`, `python@3.12`, and the common shell,
Git, database, editor, and language tools through Homebrew. They are not necessarily
macOS-exclusive; the parity matrix identifies their other implementations.

### macOS package source and exceptions

- `ansible/tasks/macos.yml` checks Xcode Command Line Tools, installs Homebrew, applies
  `Brewfile`, installs Node LTS through Homebrew NVM, and installs global npm tools.
- If Go is absent, the task downloads the current Go package from `go.dev` rather than
  using Homebrew.
- `brew bundle` deliberately excludes `go` and `npm` lines. The executable declarations
  for shared Go and npm tools are in `ansible/group_vars/all.yml`.

## 4. Linux/WSL-only tools

### Installed only on Debian/Ubuntu and WSL

- Base build and font dependencies: `wget`, `unzip`, `xz-utils`, `gpg`,
  `ca-certificates`, `build-essential`, and `fontconfig`.
- Database support: `postgresql-client`, `sqitch`, and `libdbd-pg-perl`.
- Linux release install behavior: latest Neovim is installed under `/opt` and linked to
  `/usr/local/bin/nvim`; the older APT Neovim package is removed.
- Linux installs Zoxide, PNPM, UV, Starship, NVM, and AWS CLI through their upstream
  installers rather than APT.

### Linux-specific compatibility rules

- `batcat` and `fdfind` are linked into `~/.local/bin` as `bat` and `fd`.
- `htmlq` and `saml2aws` are only installed for `x86_64`, because their selected release
  assets are x86_64-only. Other listed GitHub-release tools support the playbook’s
  supported architectures when their upstream asset exists.
- WSL does not Stow SSH configuration: it creates a native `~/.ssh/config` with mode
  `0600`. All other Unix Stow packages remain shared.
- The Unix playbook installs Nerd Fonts FiraCode and JetBrainsMono release `v3.2.1`.
  Native Windows does not provision these fonts.

## 5. Native Windows differences

### What Winget installs

`windows/packages/packages.winget.json` installs these groups:

| Group | Winget packages |
| --- | --- |
| Shell and terminal | PowerShell, Windows Terminal, psmux, Starship, Zoxide, FZF |
| File and JSON tools | Eza, Bat, FD, Ripgrep, JQ |
| Development | Git, GitHub CLI, Neovim, Go, Python 3.12, UV, NVM for Windows, PNPM, AWS CLI, Terraform, glowm |
| Developer applications | Zed, DBeaver Community, Bruno, Google Chrome, Lazygit |

### Deliberate Windows gaps

Native Windows does **not** provision Zsh, Stow, tmux, TPM, Docker completion, Unix
shell plugins, the shared Go helper-tool set other than `glowm`, Node LTS, or npm global agent tools. It installs psmux as a
native PowerShell terminal multiplexer. It also lacks the
Linux/macOS release-based tools `act`, `actionlint`, `dbmate`, `htmlq`, `lazysql`,
`saml2aws`, and `tree-sitter`.

Use WSL when a task needs the Unix shell, tmux, shared agent CLI installation, or the
Linux-only release tools. Native Windows is intended for its PowerShell, terminal,
Windows-native editor, and desktop application workflow.

### Windows configuration model

`setup-windows.ps1` creates repository-backed symlinks for Git, the PowerShell profile,
psmux, agent skills, Starship, and WezTerm. It bootstraps PPM, the psmux plugin manager, so
`C-a` followed by `I` installs the plugins declared in the linked psmux configuration. It also pre-clones the WezTerm plugin tree
(`resurrect.wezterm` and its `dev.wezterm` dependency) into `%APPDATA%/wezterm/plugins`
with the system `git`, because WezTerm's bundled libgit2 cannot clone plugins on Windows.
It copies Pi and Zed settings as real local files:

| Application | Canonical source | Windows destination | Why copied instead of linked |
| --- | --- | --- | --- |
| Pi | `pi/.pi/agent/settings.json` and `mcp.json` | `%USERPROFILE%/.pi/agent` | Pi writes its own settings. |
| Zed | `zed/.config/zed/settings.json` | `%APPDATA%/Zed/settings.json` | Zed cannot reliably open a UNC-backed settings link. |

`sync-win.ps1` is strictly one-way, repository to Windows. It backs up a pre-existing
real settings file once and leaves machine-local authentication, sessions, extensions,
and other state untouched.

## 6. Configured-only applications

These tracked configurations do not imply an installed executable. Install the
application separately on any machine where it is needed.

| Application/configuration | macOS | Linux/WSL | Native Windows | Notes |
| --- | --- | --- | --- | --- |
| Ghostty | Configured only | Configured only | Not provisioned | The tracked Ghostty file currently contains only template comments. |
| WezTerm | Configured only | Configured only | Configured only | Windows link defaults tabs/splits to the Debian WSL domain. |
| Zed | Configured only | Configured only | Installed + copied config | Zed is the preferred configured editor where available. |
| Claude Code | Configured only | Configured only | Not provisioned | Credentials and local state are intentionally excluded. |
| Pi | Configured; executable installed via npm | Configured; executable installed via npm | Configured only | Windows needs a separate Pi/Node installation. |
| OpenCode | Installed + configured | Configured only | Not provisioned | Only the macOS Brewfile installs it. |
| PostgreSQL client settings | Configured only | Configured + client installed | Not provisioned | Credentials are not part of the tracked contract. |

## 7. Runtime, editor, and agent differences

### Language runtimes and package managers

| Runtime/tool | macOS | Debian/Ubuntu + WSL | Native Windows |
| --- | --- | --- | --- |
| Go | Current release downloaded only when absent | Current release downloaded only when absent | Winget Go |
| Node | NVM plus current LTS | NVM plus current LTS | NVM for Windows, no Node version selected |
| PNPM | Homebrew | Official installer | Winget |
| Python | Homebrew Python 3.12, pyenv, and UV | APT `python3`/`pip`, pyenv, and UV | Winget Python 3.12 and UV |
| pre-commit | Homebrew | User-level `pip3` install | Not provisioned |

Shared Unix Go commands are `dlv`, `gcov2lcov`, `gofumpt`, `goimports`,
`golangci-lint`, `goplay`, `gopls`, `gotests`, `impl`, `mockery`, `revive`, and
`staticcheck`. Shared Unix npm globals are `@earendil-works/pi-coding-agent`,
`@openai/codex`, `context-mode`, `corepack`, and `tree-sitter-cli`.
Neither set is installed by the native Windows bootstrap.

### Shell, terminal, and editor behavior

- **Zsh (macOS/Linux/WSL):** history, completions, FZF, Zoxide, Starship, NVM, PNPM,
  aliases for `bat`/`eza`, plus manually cloned `zsh-autosuggestions` and
  `zsh-syntax-highlighting`.
- **PowerShell (Windows):** comparable aliases and helpers, PSReadLine, lazy PSFzf
  loading, and cached Starship/Zoxide initialization. It is not a Zsh replacement.
- **tmux (macOS/Linux/WSL):** TPM with `tmux-sensible`, `tmux-resurrect`, and
  `tmux-continuum`; `Ctrl-A` is the prefix.
- **WezTerm:** mirrors the tmux `Ctrl-A` leader. On Windows it opens new panes/tabs in
  WSL Debian by default. `glowm-wezterm` temporarily selects glowm’s iTerm2 image path,
  which WezTerm supports; this is experimental, so use `glowm --pdf` if rendering fails.
- **Neovim:** LazyVim bootstrapped by `lazy.nvim` on all three package-provisioned
  platforms. On Linux the latest upstream release is required for its runtime tree.
- **Starship:** one shared configuration shows OS/host, directory, Git, Python, Go,
  Node, the active Kubernetes context and namespace, and command duration. The OS/host
  display makes native Windows, WSL, and Unix sessions visually distinguishable.

### Agent tooling

- **Pi:** global npm agent on Unix; its shared configuration enables `pi-ask-user`,
  `pi-web-access`, and `context-mode`, and starts Context Mode as an MCP server.
- **OpenCode:** configuration enables the DCP plugin; the OpenCode executable is provisioned
  only on macOS.
- **Claude Code:** its statusline shows the current workspace, Git branch, active Kubernetes
  context and namespace, model, context remaining, cost, and applicable rate limits.
- **Skills:** the `agents` Stow package contains a lockfile for restoring third-party skills.
  Installed third-party skill directories remain ignored.

## 8. Shared configuration versus machine-local state

| Shared from this repository | Must stay local |
| --- | --- |
| Shell, Git, Neovim, tmux, Starship, terminal, Zed, Pi, OpenCode, and agent-skill configuration | Credentials, SSH private keys, Pi authentication/sessions/npm/git/bin data, Claude credentials/cache/sessions, and application-generated state |

Do not add a Windows-to-WSL copy path without an explicit conflict-resolution policy.
The repository remains canonical, and Windows copies flow from it only.

## 9. Sources of truth and maintenance

| What changed | Update this source | Also review |
| --- | --- | --- |
| macOS package, cask, tap, or VS Code extension | `Brewfile` | This document |
| Shared npm, Go, Stow, font, or Linux package definition | `ansible/group_vars/all.yml` | `Brewfile` inventory lines, if applicable; this document |
| Linux installer/release behavior | `ansible/tasks/linux.yml` and its included task files | This document |
| macOS installer behavior | `ansible/tasks/macos.yml` | This document |
| Native Windows package | `windows/packages/packages.winget.json` | This document |
| Windows links/copy policy | `setup-windows.ps1`, `sync-win.ps1`, and `windows/sync-*.ps1` | `README.md`, `AGENTS.md`, and this document |

After a change, run the relevant setup path. Unix setup dry-runs Stow and probes `zsh`,
`stow`, `tmux`, and `nvim`; native Windows verifies `starship`, `fzf`, `zoxide`, `git`,
`nvim`, `eza`, and `bat` after refreshing `PATH`. Before committing, run
`git diff --check`.

## 10. Installation source catalogue

The links below point to the package page, upstream repository, release/download page,
or package-manager manifest that the relevant installer uses. They are grouped by
**installation mechanism**, not by operating system, so a package can be found without
having to infer which platform installed it. A tool described as “configured only” in
this document appears in [configuration sources](#configuration-and-plugin-sources),
not in an installer table.

### Homebrew: macOS `Brewfile`

Homebrew Bundle consumes the tracked [`Brewfile`](../../Brewfile); each formula or cask
below links to its Homebrew package page. Tap links identify the third-party formula
source used by the Brewfile.

| Type | Installation source |
| --- | --- |
| Taps | [anomalyco/tap](https://github.com/anomalyco/homebrew-tap), [sqitchers/sqitch](https://github.com/sqitchers/homebrew-sqitch), [terraform-linters/tap](https://github.com/terraform-linters/homebrew-tap) |
| Formulae: CI, cloud, infrastructure | [act](https://formulae.brew.sh/formula/act), [actionlint](https://formulae.brew.sh/formula/actionlint), [awscli](https://formulae.brew.sh/formula/awscli), [terragrunt](https://formulae.brew.sh/formula/terragrunt), [vegeta](https://formulae.brew.sh/formula/vegeta) |
| Formulae: shell and file tools | [bat](https://formulae.brew.sh/formula/bat), [curl](https://formulae.brew.sh/formula/curl), [eza](https://formulae.brew.sh/formula/eza), [fd](https://formulae.brew.sh/formula/fd), [fzf](https://formulae.brew.sh/formula/fzf), [htop](https://formulae.brew.sh/formula/htop), [jq](https://formulae.brew.sh/formula/jq), [ripgrep](https://formulae.brew.sh/formula/ripgrep), [rtk](https://formulae.brew.sh/formula/rtk), [starship](https://formulae.brew.sh/formula/starship), [tree](https://formulae.brew.sh/formula/tree), [zoxide](https://formulae.brew.sh/formula/zoxide) |
| Formulae: Git and databases | [gh](https://formulae.brew.sh/formula/gh), [git-crypt](https://formulae.brew.sh/formula/git-crypt), [lazygit](https://formulae.brew.sh/formula/lazygit), [dbmate](https://formulae.brew.sh/formula/dbmate), [lazysql](https://formulae.brew.sh/formula/lazysql), [libpq](https://formulae.brew.sh/formula/libpq), [pass](https://formulae.brew.sh/formula/pass), [pgformatter](https://formulae.brew.sh/formula/pgformatter), [saml2aws](https://formulae.brew.sh/formula/saml2aws), [Sqitch tap](https://github.com/sqitchers/homebrew-sqitch) |
| Formulae: languages and editors | [neovim](https://formulae.brew.sh/formula/neovim), [nvm](https://formulae.brew.sh/formula/nvm), [pnpm](https://formulae.brew.sh/formula/pnpm), [pre-commit](https://formulae.brew.sh/formula/pre-commit), [python@3.12](https://formulae.brew.sh/formula/python@3.12), [stow](https://formulae.brew.sh/formula/stow), [tmux](https://formulae.brew.sh/formula/tmux), [uv](https://formulae.brew.sh/formula/uv) |
| Formulae: other | [htmlq](https://formulae.brew.sh/formula/htmlq), [mpv](https://formulae.brew.sh/formula/mpv), [OpenCode](https://formulae.brew.sh/formula/opencode) |
| Casks | [Bruno](https://formulae.brew.sh/cask/bruno), [DBeaver Community](https://formulae.brew.sh/cask/dbeaver-community), [Google Chrome](https://formulae.brew.sh/cask/google-chrome), [TFLint tap/formula source](https://github.com/terraform-linters/homebrew-tap) |
| VS Code extensions | [Swagger Viewer](https://marketplace.visualstudio.com/items?itemName=arjun.swagger-viewer), [ForgeCode](https://marketplace.visualstudio.com/items?itemName=forgecode.forge-vscode), [Go](https://marketplace.visualstudio.com/items?itemName=golang.go), [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python), [Python Debugger](https://marketplace.visualstudio.com/items?itemName=ms-python.debugpy), [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance), [Python Environments](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-python-envs), [Ansible](https://marketplace.visualstudio.com/items?itemName=redhat.ansible), [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml), [OpenAPI](https://marketplace.visualstudio.com/items?itemName=redocly.openapi-vs-code) |

### Debian/Ubuntu: APT packages

The Linux playbook’s package names are declared in
[`ansible/group_vars/all.yml`](../../ansible/group_vars/all.yml) and its
[Linux tasks](../../ansible/tasks/linux.yml). Each link is a Debian package search page,
which is deliberately version-independent across supported Debian/Ubuntu releases.

| Group | APT package sources |
| --- | --- |
| Bootstrap/build | [curl](https://packages.debian.org/search?keywords=curl), [wget](https://packages.debian.org/search?keywords=wget), [unzip](https://packages.debian.org/search?keywords=unzip), [xz-utils](https://packages.debian.org/search?keywords=xz-utils), [gpg](https://packages.debian.org/search?keywords=gpg), [ca-certificates](https://packages.debian.org/search?keywords=ca-certificates), [build-essential](https://packages.debian.org/search?keywords=build-essential), [fontconfig](https://packages.debian.org/search?keywords=fontconfig) |
| Shell and navigation | [stow](https://packages.debian.org/search?keywords=stow), [tmux](https://packages.debian.org/search?keywords=tmux), [bat](https://packages.debian.org/search?keywords=bat), [ripgrep](https://packages.debian.org/search?keywords=ripgrep), [fd-find](https://packages.debian.org/search?keywords=fd-find), [fzf](https://packages.debian.org/search?keywords=fzf), [jq](https://packages.debian.org/search?keywords=jq), [tree](https://packages.debian.org/search?keywords=tree), [htop](https://packages.debian.org/search?keywords=htop), [zsh](https://packages.debian.org/search?keywords=zsh) |
| Database, development, and Mermaid rendering | [postgresql-client](https://packages.debian.org/search?keywords=postgresql-client), [pgformatter](https://packages.debian.org/search?keywords=pgformatter), [sqitch](https://packages.debian.org/search?keywords=sqitch), [libdbd-pg-perl](https://packages.debian.org/search?keywords=libdbd-pg-perl), [pass](https://packages.debian.org/search?keywords=pass), [git-crypt](https://packages.debian.org/search?keywords=git-crypt), [python3](https://packages.debian.org/search?keywords=python3), [python3-pip](https://packages.debian.org/search?keywords=python3-pip), [mpv](https://packages.debian.org/search?keywords=mpv), [chromium](https://packages.debian.org/search?keywords=chromium) on Debian, or [chromium-browser](https://packages.ubuntu.com/search?keywords=chromium-browser) on Ubuntu |

### Linux/WSL: upstream installers and release assets

These are not distribution packages. The linked page is the direct project repository,
release page, or installer documentation used by the Ansible task.

| Installer path | Tools and source links |
| --- | --- |
| Download/install script or official archive | [Go downloads](https://go.dev/dl/), [Starship installer](https://starship.rs/install.sh), [Zoxide installer](https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh), [NVM installer](https://github.com/nvm-sh/nvm), [PNPM installer](https://pnpm.io/installation), [UV installer](https://docs.astral.sh/uv/getting-started/installation/), [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [pre-commit](https://pre-commit.com/#install), [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases) |
| APT repository added by the playbook | [GitHub CLI Linux install source](https://github.com/cli/cli/blob/trunk/docs/install_linux.md), [eza Debian package source](https://github.com/eza-community/eza/blob/main/deb.asc) |
| Latest GitHub release asset | [Neovim](https://github.com/neovim/neovim/releases/latest), [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/releases/latest), [Lazygit](https://github.com/jesseduffield/lazygit/releases/latest), [Lazysql](https://github.com/jorgerojas26/lazysql/releases/latest), [act](https://github.com/nektos/act/releases/latest), [actionlint](https://github.com/rhysd/actionlint/releases/latest), [htmlq](https://github.com/mgdm/htmlq/releases/latest), [saml2aws](https://github.com/Versent/saml2aws/releases/latest) |
| Direct release binary | [dbmate](https://github.com/amacneil/dbmate/releases/latest) |

### Shared Unix language tools

These tools are installed by the shared Ansible task after Go and Node are available.
Go links resolve to the Go package/module page used by `go install`; npm links resolve
to the registry package used by `npm install -g`.

| Installer | Package sources |
| --- | --- |
| `go install` | [dlv](https://pkg.go.dev/github.com/go-delve/delve/cmd/dlv), [gcov2lcov](https://pkg.go.dev/github.com/jandelgado/gcov2lcov), [gofumpt](https://pkg.go.dev/mvdan.cc/gofumpt), [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports), [golangci-lint](https://pkg.go.dev/github.com/golangci/golangci-lint/v2/cmd/golangci-lint), [goplay](https://pkg.go.dev/github.com/haya14busa/goplay/cmd/goplay), [glowm](https://pkg.go.dev/github.com/atani/glowm/cmd/glowm), [gopls](https://pkg.go.dev/golang.org/x/tools/gopls), [gotests](https://pkg.go.dev/github.com/cweill/gotests/gotests), [impl](https://pkg.go.dev/github.com/josharian/impl), [mockery](https://pkg.go.dev/github.com/vektra/mockery/v2), [revive](https://pkg.go.dev/github.com/mgechev/revive), [staticcheck](https://pkg.go.dev/honnef.co/go/tools/cmd/staticcheck) |
| `npm install -g` | [Pi coding agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent), [Codex](https://www.npmjs.com/package/@openai/codex), [Context Mode](https://www.npmjs.com/package/context-mode), [Corepack](https://www.npmjs.com/package/corepack), [tree-sitter CLI](https://www.npmjs.com/package/tree-sitter-cli) |

### Native Windows: Winget manifest packages

The Windows installer imports the tracked
[`packages.winget.json`](../../windows/packages/packages.winget.json). Microsoft’s Winget
CLI identifies packages by ID; every link below searches that exact ID in the
[official `microsoft/winget-pkgs` manifest repository](https://github.com/microsoft/winget-pkgs).
Use `winget show --id <ID>` to inspect the currently available source/version before
installing.

| Group | Winget manifest source links |
| --- | --- |
| Shell and terminal | [Microsoft.PowerShell](https://github.com/microsoft/winget-pkgs/search?q=Microsoft.PowerShell&type=code), [Microsoft.WindowsTerminal](https://github.com/microsoft/winget-pkgs/search?q=Microsoft.WindowsTerminal&type=code), [Starship.Starship](https://github.com/microsoft/winget-pkgs/search?q=Starship.Starship&type=code), [ajeetdsouza.zoxide](https://github.com/microsoft/winget-pkgs/search?q=ajeetdsouza.zoxide&type=code), [junegunn.fzf](https://github.com/microsoft/winget-pkgs/search?q=junegunn.fzf&type=code) |
| File and JSON tools | [eza-community.eza](https://github.com/microsoft/winget-pkgs/search?q=eza-community.eza&type=code), [sharkdp.bat](https://github.com/microsoft/winget-pkgs/search?q=sharkdp.bat&type=code), [sharkdp.fd](https://github.com/microsoft/winget-pkgs/search?q=sharkdp.fd&type=code), [BurntSushi.ripgrep.MSVC](https://github.com/microsoft/winget-pkgs/search?q=BurntSushi.ripgrep.MSVC&type=code), [jqlang.jq](https://github.com/microsoft/winget-pkgs/search?q=jqlang.jq&type=code) |
| Development | [Git.Git](https://github.com/microsoft/winget-pkgs/search?q=Git.Git&type=code), [GitHub.cli](https://github.com/microsoft/winget-pkgs/search?q=GitHub.cli&type=code), [Neovim.Neovim](https://github.com/microsoft/winget-pkgs/search?q=Neovim.Neovim&type=code), [GoLang.Go](https://github.com/microsoft/winget-pkgs/search?q=GoLang.Go&type=code), [Python.Python.3.12](https://github.com/microsoft/winget-pkgs/search?q=Python.Python.3.12&type=code), [astral-sh.uv](https://github.com/microsoft/winget-pkgs/search?q=astral-sh.uv&type=code), [CoreyButler.NVMforWindows](https://github.com/microsoft/winget-pkgs/search?q=CoreyButler.NVMforWindows&type=code), [pnpm.pnpm](https://github.com/microsoft/winget-pkgs/search?q=pnpm.pnpm&type=code), [Amazon.AWSCLI](https://github.com/microsoft/winget-pkgs/search?q=Amazon.AWSCLI&type=code), [Hashicorp.Terraform](https://github.com/microsoft/winget-pkgs/search?q=Hashicorp.Terraform&type=code) |
| Developer applications | [Zed.Zed](https://github.com/microsoft/winget-pkgs/search?q=Zed.Zed&type=code), [DBeaver.DBeaver.Community](https://github.com/microsoft/winget-pkgs/search?q=DBeaver.DBeaver.Community&type=code), [Bruno.Bruno](https://github.com/microsoft/winget-pkgs/search?q=Bruno.Bruno&type=code), [Google.Chrome](https://github.com/microsoft/winget-pkgs/search?q=Google.Chrome&type=code), [JesseDuffield.lazygit](https://github.com/microsoft/winget-pkgs/search?q=JesseDuffield.lazygit&type=code) |

### Configuration and plugin sources

These source links cover tools whose configuration is tracked even when the executable
is not installed by the matching platform bootstrap.

| Tool or plugin | Upstream source |
| --- | --- |
| Zsh plugins | [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) |
| tmux plugins | [TPM](https://github.com/tmux-plugins/tpm), [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible), [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect), [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) |
| Terminals and prompt | [Ghostty](https://ghostty.org), [WezTerm](https://wezfurlong.org/wezterm/), [Starship](https://starship.rs), [Zoxide](https://github.com/ajeetdsouza/zoxide) |
| Editors | [Neovim](https://github.com/neovim/neovim), [lazy.nvim](https://github.com/folke/lazy.nvim), [LazyVim](https://github.com/LazyVim/LazyVim), [Zed](https://zed.dev) |
| Agents and extensions | [Pi coding agent](https://www.npmjs.com/package/@earendil-works/pi-coding-agent), [pi-ask-user](https://www.npmjs.com/package/pi-ask-user), [pi-web-access](https://www.npmjs.com/package/pi-web-access), [Context Mode](https://www.npmjs.com/package/context-mode), [OpenCode](https://opencode.ai), [OpenCode DCP plugin](https://www.npmjs.com/package/@tarquinen/opencode-dcp), [Claude Code](https://docs.anthropic.com/en/docs/claude-code) |
| Other configured applications | [PostgreSQL](https://www.postgresql.org), [Git](https://git-scm.com) |
