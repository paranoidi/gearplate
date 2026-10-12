# gearplate: design reference

> **Living document.** This file records the current understanding of the design, and it gets updated whenever a feature is refined. If the code and this file disagree, fix one of them in the same change.
>
> Last updated: 2026-10-12

## Purpose
A parametric OpenSCAD generator for **device mounting boards for openGrid**. A device is screwed onto the board's face using heat-set inserts. The board snaps onto an openGrid wall through snaps at its corners.

## openGrid facts we rely on
| Fact | Value | Source |
|---|---|---|
| Cell pitch | 28 mm | openGrid spec |
| Snap footprint | 24.8 × 24.8 mm | `opengrid-snap.scad` (`w`) |
| Snap height, Full / Lite | 6.8 / 3.4 mm | same (`fulldiff`) |
| Snap orientation | Thin top plate (`+Z`) bonds to the part; the click nubs (`−Z`) go into the grid | same |

## Requirements
1. **R1. Size in cells.** The user sets `cells_x` (width) and `cells_y` (height), each ≥ 1.
2. **R2. Insert holes stay consistent across boards.** When several boards sit next to each other on the grid, the hole pattern continues without a break at the seams.
3. **R3. Corner snaps.** There is an openGrid snap at each corner of the board.
4. **R4. Optional post.** Each snap can be raised off the board by a post. The height is in mm, and 0 means no post.
5. **R5. Lite toggle.** Full or Lite snaps can be chosen.

## Current design decisions
| # | Decision | Why |
|---|---|---|
| D1 | Holes sit on a **14 mm pitch, offset 7 mm from the cell lattice** (`hole_pos()`), not from the board edge | Positions come from the lattice, so a neighbour placed n×28 mm away continues the exact 14 mm pattern (R2). That's 4 holes per cell. |
| D2 | Holes go **through the board** (Ø4.0, M3 heat-set) | User request. Inserts get pressed in from the front, and a longer screw can pass through. In the corner cells, the snap (or post) behind the board closes off the far end. |
| D8 | The board is **5 mm** thick (`board_thickness`) | User request: 7 mm was too thick. |
| D3 | The board measures `cells×28 − 2×edge_gap` per side (gap 0.3 mm) | Adjacent boards don't collide. |
| D4 | Snaps are **fused** to the board and centred on the corner cells (`snap_pos()`), de-duplicated | One printed part. A 1-wide board gets 2 snaps, and a 1×1 board gets 1. |
| D5 | The post is a cylinder, Ø18 mm by default (it must be ≤ 24.8) | It's the simplest shape that fits inside the snap's top plate. |
| D6 | The model is output in **print orientation**: device face on the bed, snaps up | No supports are needed, and each snap prints the way a standalone snap does. |
| D7 | The snap geometry is **reused, not remodelled**, via `include <opengrid-snap.scad>`, vendored from nnarain/opengrid-snap-mount-generator @ c9a1339 | It's an existing, accurate model (by David D / metasyntactic). |

## Parameters (`gearplate.scad`)
`cells_x`, `cells_y`, `board_thickness` (5), `post_height` (0), `post_diameter` (18), `lite` (false), `insert_d` (4.0), `edge_gap` (0.3).
Hidden: `cell` = 28, `pitch` = 14.

## Tooling
| What | How |
|---|---|
| Presets | `gearplate.json`, which holds OpenSCAD Customizer parameter sets. They also show up in the GUI Customizer. |
| Build all presets | `task` writes `out/<preset>.stl`. Presets build in parallel, and ones that are already up to date are skipped. |
| One preset | `task stl P=2x3`. An unknown preset name is an error. |
| One-off | `task custom NAME=4x2 ARGS='-D cells_x=4 -D cells_y=2'` |
| Logic tests | `task test` runs `tests/seam.scad`, whose asserts check seam continuity and snap de-duplication. |
| List tasks | `task --list` |

Dependencies are OpenSCAD (2021.01 is installed), [Task](https://taskfile.dev) (go-task), `jq`, and BOSL2 in `~/.local/share/OpenSCAD/libraries/BOSL2`.

## Known issues and limits
- **Non-manifold warning.** Each snap has 4 edges where a click nub touches the snap body along a single line. This comes from the upstream snap file, which gives the same warning when rendered on its own; the board and posts add no bad edges. Slicers normally repair it.
- **Slow renders.** OpenSCAD 2021.01 uses the CGAL engine, and boards take about 10–35 s each. A 2024+ nightly with `--backend=manifold` is much faster.
- **Insert length vs. board.** A standard M3 insert is 5.7 mm long, longer than the 5 mm board. It will stick out about 0.7 mm at the back, or bottom out against the snap in the corner cells. Either use short (≤ 5 mm) inserts or don't press them fully home.
- **Corner-cell holes are effectively blind.** The snap fully covers the 4 holes in each corner cell, and the post covers them partly.
- **Not yet verified by printing:** snap fit on a real grid, insert hole fit, and post strength. The tuning values are `insert_d` and `edge_gap`.

## Open questions and ideas
- Corner-cell holes: should they be skipped, or drilled through the snap/post as well? A hole at (±7, ±7) from the snap centre misses the click nubs and slots.
- Post shape: is a cylinder enough, or should it be a square or have a fillet for strength?
- Directional or lock snaps: `openGridSnap(directional=true)` already exists upstream.
- Device-specific cutouts or features on the board face.

## Changelog
- **2026-10-12.** Vendored `opengrid-snap.scad`, so the `reference/` checkout is no longer needed.
- **2026-10-12.** Holes go through the board (`insert_depth` removed). The board is 5 mm instead of 7. Taskfile now uses `method: checksum`, because `timestamp` keeps one shared state for all presets.
- **2026-10-12.** Initial generator covering R1–R5, plus presets, a Taskfile and the seam test.
