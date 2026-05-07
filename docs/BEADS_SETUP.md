# Beads (`bd`) Setup

This repo uses [beads](https://github.com/steveyegge/beads) as the issue
tracker for sectors. **`bd init` has already been run** at host root —
this doc records what was done so future contributors can replicate the
setup on a fresh clone or extend it for new sectors.

## 1. Install `bd`

Sources:

- npm: `npm install -g @steveyegge/beads` (installs as `bd` and `bd.cmd`)
- Or follow platform instructions at <https://github.com/steveyegge/beads>

Verify:

```powershell
bd --version
# bd version 1.0.3 (or newer)
```

## 2. Repo state (already done)

The host-root graph was initialized with:

```powershell
bd init
```

This created `.beads/` (Dolt-backed embedded DB), installed git hooks
under `.beads/hooks/`, registered Claude Code SessionStart + PreCompact
hooks, and added a `BEGIN BEADS INTEGRATION` block to root `CLAUDE.md`.

Issue prefix auto-detected from the directory name:
**`Unreal_Nice_Plugins`** — issues look like
`Unreal_Nice_Plugins-<3-char-hash>`.

> **Principle-violation note (Q2):** bd issues for plugin-internal work
> currently live in the host-root `.beads/`, even though the plugin
> submodule is the SHA-contract owner. Deliberate trade-off at N=1.
> Migration to `.beads-plugin/` import pattern triggers when plugin
> count reaches 2 — see `docs/VERSIONING.md §Future Migrations`.

## 3. Seeded baseline issues

| Bd ID                       | Sector | Title                                 | Status |
|-----------------------------|--------|---------------------------------------|--------|
| `Unreal_Nice_Plugins-qkc`   | M1.S1  | Add LogSamplePlugin startup log       | open   |
| `Unreal_Nice_Plugins-rff`   | M1.S2  | Tag v0.1.0 + AC2 rollback prep        | open (blocked by qkc) |
| `Unreal_Nice_Plugins-c4u`   | M1.S3  | Verify regenerate.ps1 idempotency     | open   |

Created with:

```powershell
bd create "M1.S1: Add LogSamplePlugin startup log" --type task --priority 1 --description "..."
bd create "M1.S2: Tag v0.1.0 + AC2 rollback prep"   --type task --priority 1 --description "..."
bd create "M1.S3: Verify regenerate.ps1 idempotency" --type task --priority 2 --description "..."
```

Labels (one label per call — `bd label add` accepts only one label
per invocation; colons in labels work but only when passed as the
last argument):

```powershell
bd label add Unreal_Nice_Plugins-qkc plugin:SamplePlugin
bd label add Unreal_Nice_Plugins-qkc sector:M1.S1
bd label add Unreal_Nice_Plugins-qkc ac:AC1
bd label add Unreal_Nice_Plugins-qkc bootstrap

bd label add Unreal_Nice_Plugins-rff plugin:SamplePlugin
bd label add Unreal_Nice_Plugins-rff sector:M1.S2
bd label add Unreal_Nice_Plugins-rff ac:AC2

bd label add Unreal_Nice_Plugins-c4u plugin:host
bd label add Unreal_Nice_Plugins-c4u sector:M1.S3
bd label add Unreal_Nice_Plugins-c4u ac:AC3
```

Dependency (M1.S2 blocked by M1.S1):

```powershell
bd link Unreal_Nice_Plugins-rff Unreal_Nice_Plugins-qkc
# Semantics: id2 (qkc) blocks id1 (rff). M1.S2 ready only after M1.S1 closes.
```

## 4. Verify

```powershell
bd ready
# Expect: M1.S1 (qkc) and M1.S3 (c4u) listed; M1.S2 (rff) hidden until qkc closes.

bd show Unreal_Nice_Plugins-qkc
```

## 5. Daily commands

| Command                                      | Purpose                                     |
|----------------------------------------------|---------------------------------------------|
| `bd ready`                                   | List unblocked issues — what to work on next |
| `bd show <id>`                               | Show full issue                             |
| `bd update <id> --claim`                     | Claim work (set in_progress)                |
| `bd close <id>`                              | Mark complete                               |
| `bd label add <id> <label>`                  | Add one label                               |
| `bd link <id1> <id2>`                        | id2 blocks id1                              |
| `bd prime`                                   | Print full bd workflow context              |

## 6. hooksPath workaround

`bd` installs hooks under `.beads/hooks` that can conflict with
submodule-aware git operations. When committing or pushing manually
and you hit hook failures, swap the hooksPath for the duration of the
operation:

```powershell
git config core.hooksPath .git/hooks
git add ...
git commit -m "..."
git push
git config core.hooksPath .beads/hooks
```

`scripts/sector-commit.ps1` performs this swap automatically as part of
its transactional flow.

## 7. Adding new sectors

When defining a new sector:

1. Add a row to `planning/MILESTONES.md` (real `bd` ID in the `Bd`
   column).
2. Create the bd issue: `bd create "<M.S>: <title>" --type task --priority <1|2|3>`.
3. Apply the three labels (`plugin:`, `sector:`, `ac:`).
4. If the sector has prerequisites, add a `bd link` for each blocker.
5. Create `docs/sectors/<M.S>.md` with the DoD.
