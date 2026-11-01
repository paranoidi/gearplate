# gearplate

Parametric OpenSCAD generator for device mounting boards that snap onto an openGrid. Screw your device onto the board through M3 heat-set inserts; the board clicks into the grid with openGrid snaps at its corners.

![Device fit check: plate, end caps and device](docs/assembly.png)

## Parts

| | |
|---|---|
| ![4x4 plate with cable slots](docs/4x4-mixed-slots.png) | **Gearplate** (`gearplate.scad`). Any size in 28 mm cells, with insert holes on a 14 mm grid that continues across neighbouring boards. Optional cable slots, which may open out of an edge. Full or Lite snaps. |
| ![6x4 plate on posts](docs/6x4-underware.png) | **Posts.** `post_height` raises the board off the wall, e.g. for running underware channels or plain wires below. |
| ![End caps](docs/bracket-example.png) | **Device end caps** (`bracket.scad`). A pair of caps that hold a box-shaped device by its ends and screw onto the hole grid. Each cap's end wall gets its own cable/port notches. |
| ![Cap with top cutout](docs/bracket-top.png) | **Top cutout.** A window through a cap's front strap, open at the end, e.g. to keep a switch's LEDs visible. It can be combined with end-wall notches. |
| ![Stacking piece](docs/stacking.png) | **Stacking piece** (`stacking.scad`). A 1×1 openGrid tile that screws onto a gearplate, so the next gearplate can snap onto it. |
| ![Holed snap](docs/snap.png) | **Holed snap** (`snap.scad`). A standalone openGrid snap with 2×2 insert holes on the gearplate pattern, so caps can screw onto loose snaps in the grid. |

## Usage

Requires [Task](https://taskfile.dev), `jq`, `curl` and `git`. Optional: `python3` plus `rsvg-convert` or `inkscape` for the device `spec.png` (without a converter you get `spec.svg`; without python3 it is skipped).

```sh
task setup     # download OpenSCAD nightly + BOSL2 into .tools/ (Linux x86_64)
task           # build every preset in *.json into out/*.stl
task stl P=4x4 # build one preset
task device    # interactive: device size, posts, cap cutouts, plate margins + wire slots -> plate + caps
task edit-device D=switch  # same questions, saved answers as defaults
task edit-slots D=switch   # one section only: edit-size, edit-cap-a, edit-cap-b, edit-margin, edit-slots
task test      # logic checks
task images    # re-render the pictures in docs/
```

Plate coordinates for margins and wire slots, seen from the device face (each device build also writes its own `devices/<name>/spec.png`):

![Plate coordinates](docs/coordinates.png)

Presets are OpenSCAD Customizer parameter sets (`gearplate.json`, `bracket.json`, `stacking.json`, `snap.json`), so the `.scad` files also work in the OpenSCAD GUI. See [DESIGN.md](DESIGN.md) for parameters and design decisions.

None of the parts have been verified by printing yet.

## License

[CC BY-NC-SA 4.0](LICENSE). Includes vendored openGrid code: `opengrid-snap.scad` (openGrid by David D, OpenSCAD by metasyntactic, via [nnarain/opengrid-snap-mount-generator](https://github.com/nnarain/opengrid-snap-mount-generator)) and `opengrid-tile.scad` (openGrid by David D, OpenSCAD by BlackjackDuck, via [AndyLevesque/QuackWorks](https://github.com/AndyLevesque/QuackWorks)).
