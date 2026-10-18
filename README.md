# packager

Minimal GitHub Action to package World of Warcraft addons as ZIP files.

It zips the addon into `<name>.zip` with a top-level `<name>/` folder, so the archive can be extracted
directly into `Interface/AddOns`. On a tag push it also creates the GitHub release and uploads the zip.

## Usage

`.github/workflows/release.yml` in the addon repository:

```yaml
name: Release
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v7
        with:
          submodules: recursive

      - name: Package
        uses: lua-wow/packager@v1
```

Pushing `v1.2.0` creates the `v1.2.0` release (with generated notes) and attaches `<name>.zip`.

With options:

```yaml
      - name: Package
        id: package
        uses: lua-wow/packager@v1
        with:
          name: Tainted
          exclude: |
            docs/*
            mise.toml
            CLAUDE.md
          check-version: true
          release: false

      - run: echo "${{ steps.package.outputs.file }}"
```

### Inputs

| Input          | Default                 | Description                                                          |
|:---------------|:------------------------|:---------------------------------------------------------------------|
| `path`         | `.`                     | Addon root directory.                                                |
| `name`         | basename of the `*.toc` | Folder name inside the zip and zip name. Required if the root has more than one `.toc`. |
| `exclude-file` | `exclude.lst`           | File with exclude patterns, relative to `path`. Skipped if missing.  |
| `exclude`      |                         | Extra exclude patterns, one per line.                                |
| `release`      | `true`                  | Create the release for the pushed tag and upload the zip. Ignored when the run is not for a tag. |
| `check-version` | `false`                | On tag runs, fail before packaging unless the tag (without `v`) equals the TOC `## Version` and `CHANGELOG.md`, if present, has a `## [<version>]` entry. |
| `token`        | `${{ github.token }}`   | Token used by `gh` to create the release.                            |

### Outputs

| Output | Description                                              |
|:-------|:---------------------------------------------------------|
| `name` | Addon name.                                              |
| `file` | Absolute path of the zip, written to the workspace root. |

## Excludes

Patterns use `zip -x` wildcards, matched against paths relative to the addon root:

- `*` also matches `/`, so `docs/*` excludes the whole `docs` folder and `*/.git` matches at any depth.
- `**/.pkgmeta` behaves like `*/.pkgmeta`: it matches nested files, not one at the root.
- A folder name alone (`docs`) does **not** exclude its contents. Use `docs/*`.
- Blank lines and lines starting with `#` are ignored.

Always excluded: `.git*` and `*/.git*` (`.git`, `.github`, `.gitignore`, `.gitmodules`, … including inside
submodules), the exclude file itself, and a leftover `<name>.zip`.

Example `exclude.lst`:

```
# development files
docs/*
.claude/*
.luacheckrc
mise.toml
Makefile
CLAUDE.md
```

## Local use

`package.sh` holds the packaging logic and also runs outside GitHub Actions (it needs `bash`, `zip` and `unzip`).
It is configured through environment variables:

```sh
../packager/package.sh                                    # writes ./<name>.zip
ADDON_OUTPUT_DIR=/tmp ADDON_EXCLUDE='docs/*' ../packager/package.sh
```

| Variable             | Input                                      |
|:---------------------|:-------------------------------------------|
| `ADDON_PATH`         | `path`                                     |
| `ADDON_NAME`         | `name`                                     |
| `ADDON_EXCLUDE_FILE` | `exclude-file`                             |
| `ADDON_EXCLUDE`      | `exclude`                                  |
| `ADDON_OUTPUT_DIR`   | output folder (default: current directory) |
| `ADDON_VERSION`      | tag to check (`check-version`); unset skips the check |

## Versioning

Releases are tagged `vX.Y.Z`. The release workflow moves the major tag `vX` to the latest release, so
use `lua-wow/packager@v1` to receive fixes, or pin `@v1.0.0` (or a commit SHA) to stay fixed.

To release: update `CHANGELOG.md`, then `git tag v1.0.0 && git push origin v1.0.0`.

## License

[MIT](./LICENSE)
