# Sector Schema

Defines the `MILESTONES.md` table format and the manager-agent parsing
contract. The schema is deliberately minimal — additional metadata lives
in the per-sector `docs/sectors/<M.S>.md` markdown.

## Columns

| Column   | Meaning                                                                  |
|----------|--------------------------------------------------------------------------|
| Status   | `[ ]` = pending, `[x]` = complete. The manager-agent treats `[ ]` as work-to-do. |
| ID       | `M{milestone}.S{sector}` — no `<Plugin>:` prefix (Critic amendment #5).  |
| Plugin   | Plugin name (e.g. `SamplePlugin`) **or** the literal `host` for host-only sectors. |
| Title    | Human-readable summary; informational only.                              |
| Bd       | Beads issue ID (e.g. `samp-1`). Closed by `sector-commit.ps1` after host push lands. |
| Detail   | Repo-relative path to the sector detail markdown (e.g. `docs/sectors/M1.S1-bootstrap.md`). |

## Parsing Rules

1. The first table whose header row contains `Status | ID | Plugin | Title | Bd | Detail` is authoritative.
2. Rows are scanned **top-to-bottom**; the first row with `Status == [ ]` is the next sector.
3. The `Plugin` value is matched verbatim against `HostProject/Plugins/<name>` directory names. The literal value `host` means: do not `cd` into a submodule; operate at host repo root only.
4. Sector IDs must be unique across the whole table. A duplicate ID is a hard error.
5. The `Detail` path is read by ralph as the sector spec; missing files are a hard error.

## `start` vs `next` Semantics

- `start` (bootstrap):
  1. Validate `MILESTONES.md` parses cleanly.
  2. Run `bd ready` and print the available bd issues.
  3. Print the next pending sector summary.
  4. Wait for the user to type `next`.

- `next` (execute):
  1. Re-parse `MILESTONES.md` and pick the next pending row.
  2. If `Plugin != host`: `cd HostProject/Plugins/<Plugin>`.
  3. Spawn ralph with `verifier = architect-verifier`, passing the `Detail` markdown as the sector spec.
  4. On verifier approval, the sector edit is committed on the plugin's `dev` branch (or directly on the host for `Plugin == host`).
  5. Run `scripts/sector-commit.ps1 -Plugin <Plugin> -SectorId <ID> -BdId <Bd>` (skipped for `host` sectors that do not change a submodule pin).
  6. On exit code 0, print `Continue to next sector?` and wait for the next user prompt.

## Manager-Agent Algorithm (pseudocode)

```text
fn next():
    rows = parse_milestones("planning/MILESTONES.md")
    row  = first rows where row.Status == "[ ]"
    if row is None: print "All sectors complete."; return

    detail_md = read_file(row.Detail)
    plugin    = row.Plugin

    if plugin != "host":
        with chdir("HostProject/Plugins/" + plugin):
            ralph(spec = detail_md, verifier = "architect-verifier")
    else:
        ralph(spec = detail_md, verifier = "architect-verifier")

    if plugin != "host":
        run("scripts/sector-commit.ps1",
            "-Plugin",   plugin,
            "-SectorId", row.ID,
            "-BdId",     row.Bd)

    print "Continue to next sector?"
```

## Adding a New Sector

1. Append a row to `MILESTONES.md` with `Status = [ ]`.
2. Create `docs/sectors/<M.S>.md` with the sector's DoD and verification.
3. `bd add` the issue with labels `plugin:<name>`, `sector:<M.S>`, `ac:<ACn>`.
4. Add a row to `TASK_ASSIGNMENTS.md` with `Status = unclaimed`.
