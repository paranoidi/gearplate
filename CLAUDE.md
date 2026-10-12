# gearplate

openGrid device-board generator (OpenSCAD). Read `DESIGN.md` first.

- `DESIGN.md` is a living design doc: when the user refines a feature, update its Requirements / Decisions / Parameters / Changelog in the same change.
- Build: `task` (presets in `gearplate.json`), verify: `task test`. No Makefiles; user prefers Taskfile.
- `opengrid-snap.scad` is vendored third-party code (CC-BY-NC-SA); keep it unmodified.
