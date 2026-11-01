// center_x (D30): an even screw span gets one more pitch, so the device centres on the
// plate. unifi-8-60w: 12 -> 13 holes, screws on columns 0 and 13 of a 7-cell plate. Run: task test
include <../assembly.scad>
device_w = 148;
device_h = 100;
center_x = true;
assert(n == 13 && cells_x == 7 && i0 == 0, str("expected span 13 on 7 cells from column 0, got n=", n, " cells_x=", cells_x, " i0=", i0));
assert(abs(X0 + inner_w/2 - cells_x*cell/2) < 1e-9, str("device not centred: ", X0 + inner_w/2, " vs ", cells_x*cell/2));
assert(hole_off(inner_w, wall, clear) == 7 + (12*pitch - inner_w)/2 - wall, "flange should grow by 7 mm per side");
echo("PASS center");
