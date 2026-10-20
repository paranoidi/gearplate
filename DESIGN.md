# gearplate: design reference

> **Living document.** This file records the current understanding of the design, and it gets updated whenever a feature is refined. If the code and this file disagree, fix one of them in the same change.
>
> Last updated: 2026-10-20

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
6. **R6. Cable slots.** Up to 8 rounded through-slots, each given as `x1,y1 → x2,y2` in hole-grid coordinates. Slots can sit mid-board or open out of an edge, and they must **never** overlap a corner snap.
7. **R7. Device end caps** (`bracket.scad`). This is a pair of caps, one over each end of a box-shaped device, sized from `device_w/h/d`. Each cap screws onto the hole grid. Screws need room for a screwdriver plus a margin. The end wall is the lip at the cap's edge, and the cap prints lying on it with no supports. Each cap has its own end-wall notches, given as width, height and x offset, where 0 means centred.
8. **R8. Assembly view** (`assembly.scad`). One preview shows a plate, both end caps screwed onto real plate holes, and the device as a block, roughly centred on the plate. It is a fit check, not a printable part.
9. **R9. Stacking piece** (`stacking.scad`). This is a 1×1 openGrid tile on a solid floor with 4 screw holes on the gearplate hole pattern, either countersunk or counterbored. You screw it onto a gearplate's face (into its inserts), and the next gearplate's corner snaps or posts click into it, so gearplates can be stacked. The screw head type and size are parametric, and they default to M3 countersunk. The outer edges are chamfered like the rest of the project.
10. **R10. Device workflow** (`task fit`). The user names a device (e.g. `switch`), then enters its size and both caps' end-wall cutouts at prompts. The answers are saved to `devices/<name>/<name>.json`, which can be hand-edited and rebuilt (`task device D=<name>`, or `task` for all). The build goes into the same directory: `assembly.3mf`/`.png`, `plate.stl` and `caps.stl`. The plate is the **smallest** one where every cap screw lands on a hole and the whole cap footprint (flanges and end walls) stays on the board.
11. **R11. Holed snap** (`snap.scad`). This is a standalone openGrid snap with 2×2 insert holes. When snaps are clicked into neighbouring cells, their holes continue the gearplate's 14 mm hole pattern across the grid, so anything that screws onto a gearplate (the end caps, for example) screws onto loose snaps too. Full or Lite.

## Current design decisions
| # | Decision | Why |
|---|---|---|
| D1 | Holes sit on a **14 mm pitch, offset 7 mm from the cell lattice** (`hole_pos()`), not from the board edge | Positions come from the lattice, so a neighbour placed n×28 mm away continues the exact 14 mm pattern (R2). That's 4 holes per cell. |
| D2 | Holes go **through the board** (Ø4.0, M3 heat-set) | User request. Inserts get pressed in from the front, and a longer screw can pass through. In the corner cells, the snap (or post) behind the board closes off the far end. |
| D8 | The board is **5 mm** thick (`board_thickness`) | User request: 7 mm was too thick. |
| D3 | The board measures `cells×28 − 2×edge_gap` per side (gap 0.3 mm) | Adjacent boards don't collide. |
| D4 | Snaps are **fused** to the board and centred on the corner cells (`snap_pos()`), de-duplicated | One printed part. A 1-wide board gets 2 snaps, and a 1×1 board gets 1. |
| D5 | The post has the **snap's own outline**: a 24.8 mm square with the top plate's 45° corner cuts (`snap_w`, `snap_corner`; it's the same BOSL2 `cuboid(rounding=3.262743, $fn=2)` as in `opengrid-snap.scad`) | User request: the post should match the openGrid snap. It continues the snap straight down to the board, and it's stiffer than the old Ø18 cylinder. |
| D6 | The model is output in **print orientation**: device face on the bed, snaps up | No supports are needed, and each snap prints the way a standalone snap does. |
| D9 | Slots have **r = 7 mm (14 mm wide, one hole pitch)** and cut the board only | The slot edge falls halfway between hole rows, so neighbouring rows keep their holes with about 5 mm of wall. That's wide enough for USB-C or barrel plugs. |
| D10 | Slot coordinates are **hole indices seen from the device face**: (0,0) is the bottom-left hole. −1 or 2×cells means "exit through that edge": the end is clamped to the edge row and extended straight out (D12) | `slot_pt()` mirrors X because print orientation flips the face. Positions are lattice-based like D1, so a slot on the same row continues across neighbouring boards. |
| D12 | Slot ends at an edge get a **straight extension out through the edge** (`slot_segs()`), perpendicular to that edge, with walls along the circle's tangents. An end qualifies if its index is −1/2×cells (clamped to the edge row) or its circle comes within `slot_r + edge_min_wall` (2 mm, hidden) of the edge | User report: an r=7 circle on the edge row (centre 6.7 mm from the edge) grazed the edge and left razor-thin spikes. With r=7, edge-row ends always open; a smaller `slot_r` keeps a wall of at least 2 mm. Extensions are included in the snap-overlap check. |
| D11 | A slot overlapping a corner snap is an **error** (`slot_hits_snap()` + `assert`). It checks the snap square grown by `slot_r`, which is conservative at the corners | User rule: slots never go over a corner connector. It also guarantees slots never cut a post. |
| D13 | Seen from the end, the cap is a **hat**: outboard flanges carrying the screws, side walls up the device's depth, and a front strap across the full width. An end wall closes it off | This matches the user's sketch. Nothing sits above the screws, so the screwdriver reaches them straight down past the side walls. |
| D14 | **Screws are snapped to the 14 mm grid in both directions.** Across the device, `hole_span()` picks the smallest multiple of 14 that keeps `driver_d/2 + driver_margin` between each side wall and its screw. Along the device, `cap_hole_t()` returns the end wall → first screw distance per cap: cap A's makes its end wall reach `pitch/2 − edge_gap` past the screw (plus whole pitches if `t_min` needs it), so it can sit flush on the plate edge like the flanges (D20); cap B takes the rest, so the screws stay a multiple of 14 apart. The caps can differ in length. `cap_len` grows if a screw needs more room | Both caps land on gearplate holes. The build echoes both hole counts. User report: symmetric caps (cloudkey, 120 mm) missed a 5-cell plate by 0.55 mm and got 6 cells; the asymmetric split gives the minimum `ceil((device_h + fit + 2·wall + 2·edge_gap) / 28)`. |
| D20 | Flanges reach **`pitch/2 − edge_gap` (6.7 mm) outboard of the screw** (at least `driver_d/2 + driver_margin`) | User request: a cap on the edge hole row left 2.2 mm of plate unused. Now the flange ends flush with the plate edge. `edge_gap` is shared with `gearplate.scad` |
| D15 | The **end wall is the print base**: the cap is output lying on it, with the walls, strap and flanges rising from it | Nothing overhangs, so no supports are needed. |
| D16 | Cutouts are **end-wall notches open from the plate side**, `[w, h, x_offset]`. The offset is seen from outside with the strap on top, + to the right. Each notch is asserted to stay inside the inner width and below the strap | For cables or ports leaving the device's end. The side walls and strap always stay whole. |
| D17 | Caps get a **0.4 mm chamfer** (`chamfer`) on every outside edge. The parts are modelled as overlapping boxes, each shrunk by the chamfer, unioned, then `minkowski`'d with an octahedron. Screw holes get conical chamfers at both ends, and notches get hull-built chamfers on both end-wall faces and on the plate side. Inside corners stay sharp | User request. The overlap at joints (the flanges reach into the side walls) means the seams have no grooves. |
| D18 | The board gets a **0.4 mm 45° chamfer** (`chamfer`) on all outer edges, vertical corners included, and on both rims of every cable slot. The board is a hull of octahedra inset by `chamfer` (`chamfered_box()`). Each slot cutter is three separate hulls: the straight wall plus a flare at each face (`chamfered_slot()`). The snap-overlap check uses `slot_r + chamfer` | User request. A single hull over both flares would have filled the whole slot out to r + c. That happened in the first attempt, and slicing the STL caught it. Insert holes get a 0.4 mm conical chamfer on the device face only (the side opposite the snaps), where the inserts go in; the snap side stays sharp. |
| D19 | The assembly **`include`s both models**. Their top-level part calls are guarded with `if (is_undef(assembly))`, so standalone builds don't change. Caps are snapped to hole indices `i0 = round((2·cells − 1 − n)/2)` (the same for rows), where n is the screw spacing in holes. That centres exactly when n is odd and lands 7 mm off when it's even, then it's clamped so the cap footprint stays on the board (D23). It is an error if the plate is too small | `use` would hide `-D`/Customizer overrides from the models' globals. The models share no top-level names except identical ones (`pitch`, `octahedron`) and `chamfer`, which becomes one knob for both. |
| D21 | The assembly exports as **3MF with `--enable=lazy-union`**, one top-level statement per part | Plain export unions everything, and the parts touch, so the STL was one fused mesh that OrcaSlicer couldn't split. Lazy-union gives one 3MF object per part (plate, cap A, cap B, device). Catch: lazy-union also stops `for` from unioning, so a `for` inside `minkowski()` must be wrapped in `union()`. Otherwise every box is minkowski'd together into one big block, which is how the caps first came out. |
| D22 | The stacking piece **reuses the QuackWorks openGrid tile**, vendored unmodified as `opengrid-tile.scad` (AndyLevesque/QuackWorks `openGrid/openGrid.scad` @ aeac2d3) and pulled in with `use`, so its own demo tile doesn't render. It sits on a `floor_thickness` floor. Both are clipped to `cell − 2·edge_gap` (D3). Holes sit at ±7 from the centre (D1). `head_type` picks the recess: `countersunk` is a cone from `head_d` at the floor top down to `screw_d` at depth `head_h`, and `counterbore` is a flat-bottomed Ø`head_d` × `head_h` bore. Either way the heads are flush and don't foul the snap that fills the cell. The tile corners are left square to match the floor. The edge_gap clip is `chamfered_box()` from `gearplate.scad` (`use`d), so all 12 outer edges get the 0.4 mm `chamfer` (D18) in the same intersection. An `assert` checks that the head clears the tile's corner blocks (reach 5.57 mm along the diagonal) | Accurate grid geometry for free. `stacking.scad` must `include <BOSL2/std.scad>` itself, because the `$`-globals of a `use`d file stay hidden and BOSL2 attachments fail without them. |
| D23 | **The assembly plate defaults to the smallest that fits** (`min_cells()` in `assembly.scad`). Per axis, the footprint reaches `r` past the outer screws: across, `max(clear, pitch/2 − edge_gap)` (the flange, D20); along, `t[0] + wall` / `t[1] + wall` (cap A's / cap B's end wall, D14). The lowest first-screw index is `i_min(r)` (footprint clears `edge_gap`), and the cells are the fewest whose edge clears the last screw + `r`. `-D cells_x=…` still overrides. Catch: an overriding top-level assignment is evaluated where the variable was *first* assigned (in `gearplate.scad`), so `bracket.scad` is included first and the expressions use only bracket-scope values (`2*pitch`, not `cell`). Device answers reach the models as `-D` overrides, not `-p`/`-P`: `-p` only sets the main file's own parameters, and the device ones live in the included `bracket.scad` | User request: smallest plate for a given device, with no part of a cap overhanging. |
| D24 | The holed snap is **`openGridSnap()` minus 4 through-holes at (±7, ±7)** from its centre, Ø`insert_d` (4.0, M3 heat-set) like D2, with the D18 0.4 mm chamfer on the top plate (the outward face, where inserts go in). It is output top plate down, as on the gearplate (D6) | Snaps sit centred on cells, so ±7 is exactly the D1 lattice (`tests/snap.scad` checks it against `hole_pos()`). The Ø4 holes reach 9 mm from the centre and clear the click slots (11.1 mm) and the top-plate corner nubs. A full snap is 6.8 mm deep, enough for a 5.7 mm insert; a Lite snap (3.4 mm) is too shallow for a standard insert |
| D7 | The snap geometry is **reused, not remodelled**, via `include <opengrid-snap.scad>`, vendored from nnarain/opengrid-snap-mount-generator @ c9a1339 | It's an existing, accurate model (by David D / metasyntactic). |

## Parameters (`gearplate.scad`)
`cells_x`, `cells_y`, `board_thickness` (5), `post_height` (0), `lite` (false), `insert_d` (4.0), `edge_gap` (0.3).
`chamfer` (0.4; board edges, slot rims, and insert holes on the device face).
Cable slots: `slot1`…`slot8` = `[x1, y1, x2, y2]` (`[0,0,0,0]` means off), and `slot_r` (7). Indices must be integers in `-1 … 2×cells`.
Hidden: `cell` = 28, `pitch` = 14.

### `bracket.scad`
`device_w`, `device_h`, `device_d` (60/100/25), `fit` (0.5), `wall` (3), `flange_t` (4), `cap_len` (15, the end wall included), `screw_d` (3.4), `driver_d` (7), `driver_margin` (1), `chamfer` (0.4, 0 means sharp). Hidden: `edge_gap` (0.3, same as the gearplate's; sets the flange width, D20).
Cutouts: `a_cut1..4`, `b_cut1..4` = `[w, h, x_offset]` (`[0,0,0]` means off). Presets are in `bracket.json`, with names prefixed `bracket-`.

### `assembly.scad`
All parameters of both models apply. `cells_x`/`cells_y` default to the smallest plate that fits (D23; 4×4 for the default 60×100×25 device); `-D` overrides them. Hidden `part`: `"all"` (the fit check) or `"plate"` (only the gearplate, in print orientation, for `plate.stl`). The frame has the device face at z=0, X across the device and Y along it. Open it in the GUI and preview (F5) to see the colours.

### `stacking.scad`
`lite` (false), `floor_thickness` (3.5), `screw_d` (3.4), `head_type` (`countersunk` or `counterbore`), `head_d` (6.8, M3 ISO 10642 dk 6.72), `head_h` (1.9, k 1.86), `edge_gap` (0.3), `chamfer` (0.4, 0 means sharp). Presets are in `stacking.json`: `stacking`, `stacking-lite`, and `stacking-counterbore` (M3 socket head ISO 4762: `head_d` 6, `head_h` 3.2, `floor_thickness` 5).

### `snap.scad`
`lite` (false), `insert_d` (4.0), `chamfer` (0.4, 0 means none). Presets are in `snap.json`: `snap` and `snap-lite`.

## Tooling
| What | How |
|---|---|
| Presets | `gearplate.json`, which holds OpenSCAD Customizer parameter sets. They also show up in the GUI Customizer. |
| Build all presets | `task` writes `out/<preset>.stl`. Presets build in parallel, and ones that are already up to date are skipped. |
| One preset | `task stl P=2x3`. An unknown preset name is an error. Bracket and stacking presets work the same way (`task stl P=bracket-example`, `task stl P=stacking`, `task stl P=snap`), because the task finds which preset file defines P. `task` builds all four preset files. |
| Assembly | `task assembly` writes `out/assembly.3mf` (one object per part) and a coloured `out/assembly.png` from `assembly.scad` with its default parameters. `task` builds it too. |
| Device workflow | `task fit` prompts for a device name, then its width, height, depth and up to 4 end-wall cutouts per cap (`w,h,x`). If the device already exists, its saved answers are the defaults, so Enter keeps them. It saves `devices/<name>/<name>.json` (Customizer format, one parameter set named after the device; other `bracket.scad` parameters such as `fit` or `wall` can be added by hand) and builds the device. `task device D=<name>` rebuilds one device, and `task` rebuilds all of them. The generated files in `devices/` are gitignored, and the answers are tracked. |
| One-off | `task custom NAME=4x2 ARGS='-D cells_x=4 -D cells_y=2'` |
| Logic tests | `task test` runs `tests/seam.scad` (seam continuity, snap de-duplication) and `tests/slots.scad` (front-view mapping, edge indices, the snap-overlap rule) `tests/bracket.scad` (cap screws on the grid both ways, screwdriver clearance) `tests/assembly.scad` (every cap screw in the assembly lands on a plate hole, the cap footprint stays on the plate, and the plate is minimal) `tests/stacking.scad` (stacking holes land on gearplate holes, and the head clears the tile corners) and `tests/snap.scad` (snap holes land on gearplate holes). |
| Tooling | `task setup` downloads the latest OpenSCAD nightly AppImage and BOSL2 into `.tools/` (gitignored). Re-running it updates both, and it skips the download if that nightly is already installed. |
| Engine choice | `$OPENSCAD` env if set, otherwise `.tools/openscad --backend=Manifold` if present, otherwise system `openscad`. BOSL2 comes from `.tools/libraries` (`OPENSCADPATH`) when present. A new nightly rebuilds every STL. |
| List tasks | `task --list` |

Dependencies are [Task](https://taskfile.dev) (go-task), `jq`, `curl` and `git`. `task setup` covers OpenSCAD and BOSL2. The fallback is system OpenSCAD 2021.01 with BOSL2 in `~/.local/share/OpenSCAD/libraries/BOSL2`. Tests export to `.echo` (no geometry needed), and failed asserts are found by searching that output, because OpenSCAD exits 0 on them in that mode.

## Known issues and limits
- **Non-manifold warning.** Each snap has 4 edges where a click nub touches the snap body along a single line. This comes from the upstream snap file, which gives the same warning when rendered on its own. With CGAL (2021.01), bigger boards (4×4 and up) also show a few more edges at the snap top plate; Manifold builds don't have those, and Manifold itself reports no errors. The board, posts and slots add none. Slicers normally repair it.
- **Render speed.** With the nightly and Manifold (`task setup`), all 10 presets build in about 6 s. With the system 2021.01 and CGAL, the same build takes about 75 s.
- **Insert length vs. board.** A standard M3 insert is 5.7 mm long, longer than the 5 mm board. It will stick out about 0.7 mm at the back, or bottom out against the snap in the corner cells. Either use short (≤ 5 mm) inserts or don't press them fully home.
- **Corner-cell holes are effectively blind.** The snap fully covers the 4 holes in each corner cell, and the post covers them partly.
- **Stacking piece not yet verified by printing.** Snap fit on the floored tile, flush heads, and whether the corner-cell inserts of the lower plate hold (they can bottom out against its snap, see above) are all untested.
- **End caps not yet verified by printing.** Fit (`fit`), how firmly the caps hold the device, and whether the M3 screw heads fit in the `driver_d` clearance are all untested.
- **Holed snap not yet verified by printing.** Whether the snap still clicks firmly with 4 holes through its core, and insert fit in the 6.8 mm snap, are untested. Lite snaps are too thin for standard inserts.
- **Not yet verified by printing:** snap fit on a real grid, insert hole fit, and post strength. The tuning values are `insert_d` and `edge_gap`.

## Open questions and ideas
- Corner-cell holes: should they be skipped, or drilled through the snap/post as well? A hole at (±7, ±7) from the snap centre misses the click nubs and slots.
- Post shape: is a cylinder enough, or should it be a square or have a fillet for strength?
- Directional or lock snaps: `openGridSnap(directional=true)` already exists upstream.
- Device-specific cutouts or features on the board face.
- Shallow diagonal slots exiting an edge leave a thin (but square-ended) lip between the slot and the edge, about 1.7 mm for slope 1:3. Should it be widened or removed?
- Crossing or touching slots can leave acute wedges between them, and diagonal slots can clip holes. Should these be warned about?

## Changelog
- **2026-10-20.** Added the holed snap (R11, D24): `snap.scad`, `snap.json` and `tests/snap.scad`.
- **2026-10-20.** Caps along the device are asymmetric (D14): cap A's end wall can sit flush on the plate edge, so plates are up to a cell shorter (cloudkey 3×6 → 3×5, default device 4×5 → 4×4).
- **2026-10-13.** Gearplate insert holes: 0.4 mm chamfer on the device face (D18).
- **2026-10-13.** Device workflow (R10, D23): `task fit` / `task device`, per-device answers in `devices/<name>/`, and the assembly plate now auto-sizes to the smallest that keeps the cap footprint on the board. `tests/assembly.scad` checks the footprint and minimality.
- **2026-10-13.** Stacking piece: counterbore option (`head_type`, preset `stacking-counterbore`) and a 0.4 mm chamfer on all outer edges (D22).
- **2026-10-13.** Added the stacking piece (R9, D22): `stacking.scad`, `stacking.json`, vendored `opengrid-tile.scad`, and `tests/stacking.scad`.
- **2026-10-13.** Assembly exports as 3MF with one object per part, so slicers can separate them (D21).
- **2026-10-13.** Cap flanges widened to end flush with the plate edge (D20).
- **2026-10-13.** Added `assembly.scad` (R8, D19): plate, caps and device block in one view, plus `tests/assembly.scad` and `task assembly`.
- **2026-10-12.** Posts now use the snap outline instead of a Ø18 cylinder (D5). `post_diameter` removed.
- **2026-10-12.** Gearplate: 0.4 mm chamfer on board edges and slot rims (D18).
- **2026-10-12.** Caps: 0.4 mm chamfer on all outside edges, holes and notches (D17).
- **2026-10-12.** Added device end caps (R7, D13–D16): `bracket.scad`, `bracket.json`, and `tests/bracket.scad`. The Taskfile `stl` task picks the model from whichever preset file defines the preset.
- **2026-10-12.** Fixed sharp spikes at edge slots: ends at an edge get straight extensions (D12). Added preset `4x4-edge-slots`.
- **2026-10-12.** Added `task setup` (OpenSCAD nightly with Manifold, and BOSL2, in `.tools/`), which is picked up automatically. Tests switched to `.echo` export because BOSL2's `cube()` override broke the old `cube(1)` placeholder under `use`.
- **2026-10-12.** Cable slots (R6, D9–D11): `slot1..8`, `slot_r`, preset `4x4-slots`, and `tests/slots.scad`.
- **2026-10-12.** Vendored `opengrid-snap.scad`, so the `reference/` checkout is no longer needed.
- **2026-10-12.** Holes go through the board (`insert_depth` removed). The board is 5 mm instead of 7. Taskfile now uses `method: checksum`, because `timestamp` keeps one shared state for all presets.
- **2026-10-12.** Initial generator covering R1–R5, plus presets, a Taskfile and the seam test.
