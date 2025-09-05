# Repository Guidelines

## Project Structure & Module Organization
- `src/`: 5GC network functions (AMF, SMF, UPF, …) and daemons.
- `lib/`: protocol stacks and shared utilities.
- `configs/`: YAML templates (NF configs in `configs/open5gs`), examples, systemd/logrotate.
- `tests/`: Meson test suites (`unit`, `sctp`, `registration`, …).
- `webui`, `docs`, `docker`, `vagrant`: UI, docs, deployment assets.
- Build roots: `meson.build`, `meson_options.txt`.

## Build, Test, and Development Commands
- Configure: `meson setup build -Dbuildtype=debug --prefix=$PWD/install`
- Compile: `meson compile -C build` (or `ninja -C build`)
- Install: `ninja -C build install`
- Run tests: `meson test -C build --verbose`
- Static analysis: `meson compile -C build analyze-cppcheck` and `meson compile -C build analyze-clang-tidy`
- Example: `install/bin/open5gs-amfd -c install/etc/open5gs/amf.yaml`

## Coding Style & Naming Conventions
- Language: C (GNU89, `c_std=gnu89`).
- Indentation: 4 spaces; LF line endings; final newline (`.editorconfig`).
- Naming: snake_case; filenames reflect NF/module (e.g., `ngap-*`, `sbi-*`).
- Keep builds warning-clean; use `.clang-tidy` via the analyze targets before submitting.

## Testing Guidelines
- Place tests in the closest suite under `tests/` and register in that suite’s `meson.build`.
- Name C test sources `*-test.c`; keep tests deterministic.
- Run `meson test -C build` locally; add focused tests for protocol handlers, FSMs, timers, and encoders/decoders.

## Commit & Pull Request Guidelines
- Subject: `[SUBSYSTEM] Imperative summary` (e.g., `[AMF/SEC] Validate UE context`).
- Body: what/why, user-visible impact, relevant logs or traces.
- PRs: clear description, linked issues, minimal repro/config snippets, and test notes; include screenshots for `webui` changes.

## Security & Configuration Tips
- NF configs are generated from templates in `configs/open5gs/*.yaml.in` into `install/etc/open5gs`.
- Logging: templates default to `level: trace` and unified logging.
  - Toggle in YAML: `logger.unified_logging: true|false`, set `logger.unified_file` path.
  - Env override for quick tests: `OPEN5GS_UNIFIED_LOGGING=1`, `OPEN5GS_UNIFIED_FILE=/path/to/unified.log`.
- Do not commit secrets or real subscriber data; sanitize logs/pcaps in issues/PRs.
