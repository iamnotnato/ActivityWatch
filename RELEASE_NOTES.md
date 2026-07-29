# Release Notes

## v1.1.0

Security release. Patches 23 Dependabot advisories across all Python components and raises the minimum Python version to 3.10.

### Breaking changes

- **Minimum Python is now 3.10** (was 3.9). Python 3.9 reached end-of-life in October 2025.

  This is the reason for the minor version bump rather than a patch. Every remaining
  security fix below is published only for Python 3.10+, so the floor had to move to
  pick them up. If you install `aw-core` or `aw-client` from PyPI, you must be on
  Python 3.10 or newer. Users of the packaged Windows installer are unaffected — the
  interpreter is bundled.

### Security

| Package | From | To | Advisory |
|---|---|---|---|
| urllib3 | 2.6.3 | 2.7.0 | [GHSA-mf9v-mfxr-j63j](https://github.com/advisories/GHSA-mf9v-mfxr-j63j) decompression-bomb safeguards bypassed in the streaming API<br>[GHSA-qccp-gfcp-xxvc](https://github.com/advisories/GHSA-qccp-gfcp-xxvc) sensitive headers forwarded across origins on proxied redirects |
| requests | 2.32.5 | 2.34.2 | [GHSA-gc5v-m9x4-r6x2](https://github.com/advisories/GHSA-gc5v-m9x4-r6x2) insecure temp file reuse in `extract_zipped_paths()` |
| setuptools | 82.0.1 | 83.0.0 | [GHSA-h35f-9h28-mq5c](https://github.com/advisories/GHSA-h35f-9h28-mq5c) `MANIFEST.in` exclusion bypass via Unicode normalization |
| pytest | 8.4.2 | 9.1.1 | [GHSA-6w46-j5rx-g56g](https://github.com/advisories/GHSA-6w46-j5rx-g56g) vulnerable tmpdir handling (dev only) |
| black | 25.11.0 | 26.5.1 | [GHSA-3936-cmfr-pm3m](https://github.com/advisories/GHSA-3936-cmfr-pm3m) arbitrary file write via cache filename (dev only) |

Applied across `aw-core`, `aw-client`, `aw-server`, `aw-qt`, `aw-watcher-afk`,
`aw-watcher-input`, `aw-watcher-window` and the bundle root.

### Other changes

- **Dropped the `setuptools >=78.1.1,<81` pin.** It existed because PyInstaller imported
  `pkg_resources`, which setuptools removed in 81+. No longer needed: setuptools 83 ships
  no `pkg_resources` at all, and PyInstaller 6.15+ provides its own shim. Verified with a
  full packaging run and smoke tests on the frozen `aw-qt`, `aw-server`,
  `aw-watcher-afk` and `aw-watcher-window` executables.
- Removed dead `importlib-metadata` conditional dependencies (`python < 3.10`) from
  `aw-server` and `aw-qt`.
- Fixed `aw-qt` mypy config: `python_version = 3.8` → `"3.10"` (must be a string).
- CI now builds against Python 3.10.

### Known issues

Not fixed here because no upstream patch exists:

- **Vue 2 ReDoS** ([GHSA-5j4c-8p2g-v4jx](https://github.com/advisories/GHSA-5j4c-8p2g-v4jx), low)
  and **vue-template-compiler XSS** ([GHSA-g3ch-rx76-35fx](https://github.com/advisories/GHSA-g3ch-rx76-35fx), moderate).
  Vue 2 is end-of-life; the only remediation is a Vue 3 migration. The compiler is a
  build-time dev dependency and is not shipped to browsers.
- **glib 0.18.5 unsoundness** ([RUSTSEC-2024-0429](https://rustsec.org/advisories/RUSTSEC-2024-0429), moderate)
  in `aw-tauri`, pinned transitively through `gtk 0.18` ← `libappindicator`/`tray-icon` ←
  `tauri 2.11.5`. No released `tao`/`gtk-rs` version permits `glib ^0.20`. Affects the
  Linux target only.
- **brace-expansion** ([GHSA-mh99-v99m-4gvg](https://github.com/advisories/GHSA-mh99-v99m-4gvg)).
  The bundled copies were updated to 1.1.17 / 2.1.3, but the advisory covers everything
  `<= 5.0.7` and is patched only in 5.0.8, so the 1.x and 2.x lines remain flagged.
  Dev-only, reachable via the eslint and jest toolchains.

Pre-existing and unrelated to this release: the `aw-core` test suite has 34 failures
caused by `peewee` 4.x breaking iso8601 parsing (the constraint `>=3.0.0,<5.0.0` admits
4.x). Also, running `pytest` from the `aw-server` directory root collects `__main__.py`
and starts a real server; use `pytest tests/` as the Makefile does.

**Full changelog:** [`v1.0.5...v1.1.0`](../../compare/v1.0.5...v1.1.0)

---

The following versions were tagged but never published as releases. Notes are included
here for completeness.

## v1.0.5

Security release.

- `aw-client`: raised the Python floor to `^3.9.2`, which unblocked `cryptography`
  43.0.3 → 49.0.0.
- `aw-server`: `pytest` constraint `^7.3` → `^8.0`.
- `awatcher`: `ksni` 0.2.2 → 0.3.6, which removed the legacy `dbus`/`clap 2`/`atty`
  dependency chain entirely and resolved the `atty` unaligned-read advisory.

**Full changelog:** [`v1.0.4...v1.0.5`](../../compare/v1.0.4...v1.0.5)

## v1.0.4

Bug fix and npm security updates.

- **Fixed server startup failure on Flask 2.4+**: `escape` was removed from `flask`, so
  it is now imported from `markupsafe`.
- Bumped the `postcss` override to `^8.5.18`
  ([GHSA-r28c-9q8g-f849](https://github.com/advisories/GHSA-r28c-9q8g-f849), path traversal).
- Overrode `yorkie` → `cross-spawn` to `^6.0.6` (ReDoS).
- Removed unused dependencies: `html-loader` (pulled a vulnerable `html-minifier`),
  `shelljs`, `tslint`.
- Production npm audit reduced to 0 high/critical.

**Full changelog:** [`v1.0.3...v1.0.4`](../../compare/v1.0.3...v1.0.4)

## v1.0.3

- **Fixed missing logo in npm builds.** Added a `prebuild` script that copies
  `media/logo/logo.{png,svg}` into `static/`, so a plain `npm run build` produces a
  complete bundle. Previously only the Makefile target did this, leaving `dist` without
  `logo.png`.

**Full changelog:** [`v1.0.2...v1.0.3`](../../compare/v1.0.2...v1.0.3)

## v1.0.2

- **Fixed the category "Append" rule for categories with malformed or empty rules.**
  `appendClassRule` silently dropped appends when the target category's rule had an
  undefined type (for example a legacy `rule: {}`). Any non-regex or empty rule is now
  replaced with a fresh regex rule, and `cleanCategory` normalizes rules with a missing
  type to `{type: 'none'}`.

**Full changelog:** [`v1.0.1...v1.0.2`](../../compare/v1.0.1...v1.0.2)

## v1.0.1

- Switched to local path dependencies, bumped `phf` to 0.13, and added audit ignores for
  advisories with no available fix.

**Full changelog:** [`v1.0.0...v1.0.1`](../../compare/v1.0.0...v1.0.1)
