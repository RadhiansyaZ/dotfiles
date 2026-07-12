# Wiki page schema

Every substantive page in `docs/wiki/` starts with YAML front matter containing `title`, a non-empty `source_files` list of tracked repository-relative paths, and an ISO `last_reviewed` date. Each page body has a Markdown H1 title.

Source-backed facts link to repository files. Operational guidance is labelled as guidance. Constraints and safety boundaries are explicit. Verification commands must already be supported by the repository. Uncertain conclusions link to a pending-review record.

Do not include credentials, tokens, raw diffs, hostnames, usernames, absolute personal paths, session data, or local command output.
