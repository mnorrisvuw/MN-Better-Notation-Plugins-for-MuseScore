# Roadmap

## Version 2.0

### One-click plugin updates

Add an opt-in updater that builds on the existing GitHub release check:

- Ask the user before downloading and installing an available update.
- Download the release into a temporary staging directory.
- Verify the release checksum before installation.
- Back up the currently installed plugin files so the update can be rolled back.
- Replace only files managed by the MN Better Notation Plugins release.
- Prompt the user to restart MuseScore after a successful installation.
- Keep the update logic in one shared updater component rather than duplicating it in every plugin.
- Support MuseScore 4 and 5 on macOS initially, with platform-specific Windows and Linux installation routines considered separately.

### Findings navigator palette

Create a compact navigator palette for reviewing plugin findings:

- List findings in order of urgency by default.
- Include a search function.
- Provide filter buttons for `All`, `Layout`, `Notation`, `Text`, and `Instrumentation`.
- Navigate to and select the relevant location in the score when a finding is clicked.
- Allow the list to be sorted by bar, instrument, or priority.
- Provide finding-level action buttons:
  - `Locate in score`
  - `Ignore`
  - `Ignore all similar`
  - `Mark resolved`
  - `Fix now`, when the finding has a supported automatic correction
