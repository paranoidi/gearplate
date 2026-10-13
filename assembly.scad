// Fit check: gearplate + both end caps + the device as a block, in one view.
// Caps sit on real plate holes, device roughly centred on the plate. Preview (F5)
// for colours. Not a printable part.
//
// The plate defaults to the smallest one that holds every cap screw on a hole and the
// whole cap footprint (flanges, end walls) inside the board edge; -D cells_x=.. overrides.
//
// Frame: plate device face at z=0 facing +Z, X across the device, Y along it
// (device_h). Hole i sits at pitch/2 + i*pitch on both axes (as seen from the face).
// All gearplate.scad and bracket.scad parameters apply (-D or Customizer); `chamfer`
// is shared by board and caps.

// bracket first: cells_x below is evaluated where gearplate.scad first assigns it, so it
// may only use values bracket.scad has already defined (not `cell`, not n/m below)
include <bracket.scad>
include <gearplate.scad>

cells_x = min_cells(hole_span(inner_w, wall, clear) / pitch, max(clear, pitch/2 - edge_gap));
cells_y = min_cells((inner_h - 2*t) / pitch, t + wall);

/* [Hidden] */
assembly = true;
// "all" = fit check; "plate" = only the gearplate, in print orientation
part = "all";

function hole(i) = pitch/2 + i*pitch;
// Footprint placement along one axis: outer screws n holes apart, footprint reaching r
// past each of them. Lowest / highest first-screw index that keeps it on a c-cell plate.
function i_min(r) = max(0, ceil((edge_gap + r - pitch/2) / pitch));
function i_max(c, n, r) = floor((c*2*pitch - edge_gap - r - pitch/2) / pitch) - n;
function min_cells(n, r) = max(1, ceil((hole(i_min(r) + n) + r + edge_gap) / (2*pitch)));
// Centred (exact when n is odd, 7mm off when even), nudged to keep the footprint on.
function place(c, n, r) = min(max(round((2*c - 1 - n) / 2), i_min(r)), i_max(c, n, r));

n = hole_span(inner_w, wall, clear) / pitch;  // hole rows between the screws, across
m = (inner_h - 2*t) / pitch;                  // between cap A's and cap B's first screws
rx = max(clear, pitch/2 - edge_gap);          // flange reach past the screw (D20)
ry = t + wall;                                // end wall reach past the first screw
i0 = place(cells_x, n, rx);
j0 = place(cells_y, m, ry);
assert(i0 >= i_min(rx), str("plate too small for device: needs ", min_cells(n, rx), " cells across"));
assert(j0 >= i_min(ry), str("plate too small for device: needs ", min_cells(m, ry), " cells along"));
echo(str("Assembly: plate ", cells_x, " x ", cells_y, " cells; screws on hole columns ", i0, " and ", i0 + n,
         ", rows from ", j0, " (cap A) and ", j0 + m, " (cap B)"));

// Inner faces of the left side wall and of cap A's end wall.
X0 = hole(i0) + wall + off;
Y0 = hole(j0) - t;
// Screw centres and cap footprint [min, max] in this frame, for tests/assembly.scad.
screw_xs = [hole(i0), hole(i0 + n)];
screw_ys = concat([for (z = hole_zs) Y0 - wall + z], [for (z = hole_zs) Y0 + inner_h + wall - z]);
foot_x = [hole(i0) - rx, hole(i0 + n) + rx];
foot_y = [Y0 - wall, Y0 + inner_h + wall];

if (part == "plate") gearplate();
else {
    color("silver") translate([cells_x*cell, 0, 0]) rotate([0, 180, 0]) gearplate();
    // One top-level statement per part: with lazy-union each becomes its own 3MF object.
    // (x,y,z) -> (-x, z, y)
    color("steelblue") translate([X0 + inner_w, Y0 - wall, 0]) rotate([0, 0, 180]) rotate([90, 0, 0]) cap(cuts[0]);
    // (x,y,z) -> (x, -z, y)
    color("steelblue") translate([X0, Y0 + inner_h + wall, 0]) rotate([90, 0, 0]) cap(cuts[1]);
    color("orange", 0.8) translate([X0 + fit, Y0 + fit/2, 0]) cube([device_w, device_h, device_d]);
}
