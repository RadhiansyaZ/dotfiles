# Pending-review queue

A pending record is a tracked, public-safe question for a source change whose documentation impact needs human resolution. No pending record is the normal success state.

Name a record `<short-head-sha>.md`. Its front matter must include `status`, full `base` and `head` SHAs, changed `paths`, `question`, `owner`, and `created`. The body links affected sources and likely pages without including a raw diff or sensitive values.

Open records expire after 30 days. Resolve a record by updating the affected page, setting `status: resolved`, and recording the resolving commit and date.
