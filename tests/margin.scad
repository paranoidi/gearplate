// Plate margins (D27): whole cells added to the smallest plate, the device keeps its
// place on the original cells, and a slot may not cut a cap screw hole (D28). Run: task test
include <../assembly.scad>
margin_a = 1;
margin_b = 2;
margin_l = 1;
margin_r = 0;
// The default 60x100x25 device gets a 4 x 4 plate (tests/assembly.scad), placed at i0 = 1, j0 = 0.
assert(cells_x == 4 + 1 && cells_y == 4 + 3, str("expected 5 x 7 cells, got ", cells_x, " x ", cells_y));
assert(i0 == 1 + 2 && j0 == 0 + 2, str("device should shift by 2 holes per margin cell, got i0=", i0, " j0=", j0));
assert(foot_x[0] >= margin_l*cell && foot_x[1] <= (cells_x - margin_r)*cell, "cap footprint left the non-margin cells across");
assert(foot_y[0] >= margin_a*cell && foot_y[1] <= (cells_y - margin_b)*cell, "cap footprint left the non-margin cells along");
assert(in_slot(keep[0]) == false, "no slots, yet a screw hole is in one");
echo("PASS margin");
