# Changelog

## [Unreleased]

## [1.1.0] - 2026-10-18

- `check-version` input: fail a tag release whose tag doesn't match the TOC `## Version` or has no `CHANGELOG.md` entry.
- Log the zip's file list.

## [1.0.0] - 2026-10-18

- Package an addon as `<name>.zip` with a `<name>/` folder, honoring `exclude.lst` and extra patterns.
- Create the GitHub release for the pushed tag and upload the zip.
