// Assembly: every cap screw lands on a plate hole. Run: task test
include <../assembly.scad>
for (x = screw_xs) assert(len(search(x, hole_pos(cells_x))) == 1, str("screw x=", x, " off the hole grid"));
for (y = screw_ys) assert(len(search(y, hole_pos(cells_y))) == 1, str("screw y=", y, " off the hole grid"));
echo("PASS assembly");
