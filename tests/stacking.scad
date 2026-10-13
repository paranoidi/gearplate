// Stacking piece holes must land on gearplate holes. Run: task test
use <../gearplate.scad>
include <../stacking.scad>
// one cell's gearplate holes, relative to the cell centre
assert([for (p = hole_pos(1)) p - cell/2] == hole_offsets, "holes off the gearplate grid");
assert(pitch/2 * sqrt(2) - head_d/2 > corner_reach);
echo("PASS stacking");
