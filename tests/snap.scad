// Snap holes must land on gearplate holes. Run: task test
use <../gearplate.scad>
cell = 28;
include <../snap.scad>
// one cell's gearplate holes, relative to the cell centre (snaps sit centred on cells)
assert([for (p = hole_pos(1)) p - cell/2] == hole_offsets, "holes off the gearplate grid");
echo("PASS snap");
