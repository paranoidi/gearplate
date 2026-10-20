// Assembly: every cap screw lands on a plate hole, the cap footprint stays on the plate,
// and the auto-sized plate is the smallest that does. Run: task test
include <../assembly.scad>
for (x = screw_xs) assert(len(search(x, hole_pos(cells_x))) == 1, str("screw x=", x, " off the hole grid"));
for (y = screw_ys) assert(len(search(y, hole_pos(cells_y))) == 1, str("screw y=", y, " off the hole grid"));
for (a = [[foot_x, cells_x], [foot_y, cells_y]])
    assert(a[0][0] >= edge_gap - 1e-9 && a[0][1] <= a[1]*cell - edge_gap + 1e-9, str("cap footprint ", a[0], " off the plate"));
assert(cells_x == 1 || i_min(rx) > i_max(cells_x - 1, n, rx), "plate not minimal across");
assert(cells_y == 1 || i_min(ry) > i_max(cells_y - 1, m, ry2), "plate not minimal along");
echo("PASS assembly");
