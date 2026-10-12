// Fit check: gearplate + both end caps + the device as a block, in one view.
// Caps sit on real plate holes, device roughly centred on the plate. Preview (F5)
// for colours. Not a printable part.
//
// Frame: plate device face at z=0 facing +Z, X across the device, Y along it
// (device_h). Hole i sits at pitch/2 + i*pitch on both axes (as seen from the face).
// All gearplate.scad and bracket.scad parameters apply (-D or Customizer); `chamfer`
// is shared by board and caps.

include <gearplate.scad>
include <bracket.scad>

cells_x = 4;
cells_y = 5;

/* [Hidden] */
assembly = true;

function hole(i) = pitch/2 + i*pitch;
n = hole_span(inner_w, wall, clear) / pitch;  // hole rows between the screws, across
m = (inner_h - 2*t) / pitch;                  // between cap A's and cap B's first screws
i0 = round((2*cells_x - 1 - n) / 2);
j0 = round((2*cells_y - 1 - m) / 2);
assert(i0 >= 0 && i0 + n <= 2*cells_x - 1, str("plate too small for device: needs ", n + 1, " hole columns, has ", 2*cells_x));
assert(j0 >= 0 && j0 + m <= 2*cells_y - 1, str("plate too small for device: needs ", m + 1, " hole rows, has ", 2*cells_y));
echo(str("Assembly: screws on hole columns ", i0, " and ", i0 + n, ", rows from ", j0, " (cap A) and ", j0 + m, " (cap B)"));

// Inner faces of the left side wall and of cap A's end wall.
X0 = hole(i0) + wall + off;
Y0 = hole(j0) - t;
// Screw centres in this frame, for tests/assembly.scad.
screw_xs = [hole(i0), hole(i0 + n)];
screw_ys = concat([for (z = hole_zs) Y0 - wall + z], [for (z = hole_zs) Y0 + inner_h + wall - z]);

color("silver") translate([cells_x*cell, 0, 0]) rotate([0, 180, 0]) gearplate();
// One top-level statement per part: with lazy-union each becomes its own 3MF object.
// (x,y,z) -> (-x, z, y)
color("steelblue") translate([X0 + inner_w, Y0 - wall, 0]) rotate([0, 0, 180]) rotate([90, 0, 0]) cap(cuts[0]);
// (x,y,z) -> (x, -z, y)
color("steelblue") translate([X0, Y0 + inner_h + wall, 0]) rotate([90, 0, 0]) cap(cuts[1]);
color("orange", 0.8) translate([X0 + fit, Y0 + fit/2, 0]) cube([device_w, device_h, device_d]);
