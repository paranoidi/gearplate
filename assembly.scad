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

/* [Plate margins] */
// Extra whole openGrid cells added to the smallest plate, seen from the device face:
// A = cap A end (bottom, row 0), B = cap B end, L/R = left/right. Declared before the
// includes: the cells_x/cells_y overrides below are evaluated where gearplate.scad
// first assigns them.
margin_a = 0; // [0:10]
margin_b = 0; // [0:10]
margin_l = 0; // [0:10]
margin_r = 0; // [0:10]

// bracket first: cells_x below is evaluated where gearplate.scad first assigns it, so it
// may only use values bracket.scad has already defined (not `cell`, not n/m below)
include <bracket.scad>
include <gearplate.scad>

cells_x = min_cells(hole_span(inner_w, wall, clear) / pitch, max(clear, pitch/2 - edge_gap)) + margin_l + margin_r;
cells_y = min_cells((inner_h - t[0] - t[1]) / pitch, t[0] + wall, t[1] + wall) + margin_a + margin_b;

/* [Hidden] */
assembly = true;
// "all" = fit check; "plate" = only the gearplate, in print orientation
part = "all";

function hole(i) = pitch/2 + i*pitch;
// Footprint placement along one axis: outer screws n holes apart, footprint reaching r
// past the first and r2 past the last. Lowest / highest first-screw index that keeps it
// on a c-cell plate (1e-9: a reach of exactly pitch/2 - edge_gap is flush, not over).
function i_min(r) = max(0, ceil((edge_gap + r - pitch/2) / pitch - 1e-9));
function i_max(c, n, r2) = floor((c*2*pitch - edge_gap - r2 - pitch/2) / pitch + 1e-9) - n;
function min_cells(n, r, r2 = undef) = let (r2 = is_undef(r2) ? r : r2)
    max(1, ceil((hole(i_min(r) + n) + r2 + edge_gap) / (2*pitch) - 1e-9));
// Footprint centred (to the nearest hole), nudged to keep it on.
function place(c, n, r, r2) = min(max(round((2*c - 1 - n) / 2 - (r2 - r) / (2*pitch)), i_min(r)), i_max(c, n, r2));

n = hole_span(inner_w, wall, clear) / pitch;  // hole rows between the screws, across
m = (inner_h - t[0] - t[1]) / pitch;          // between cap A's and cap B's first screws
rx = max(clear, pitch/2 - edge_gap);          // flange reach past the screw (D20)
ry = t[0] + wall;                             // end wall reach past the first screw, cap A
ry2 = t[1] + wall;                            // and cap B
// Placed on the plate minus its margin cells, then shifted past the A / L margin (D27).
cx0 = cells_x - margin_l - margin_r;
cy0 = cells_y - margin_a - margin_b;
i0 = place(cx0, n, rx, rx) + 2*margin_l;
j0 = place(cy0, m, ry, ry2) + 2*margin_a;
assert(i0 - 2*margin_l >= i_min(rx), str("plate too small for device: needs ", min_cells(n, rx) + margin_l + margin_r, " cells across"));
assert(j0 - 2*margin_a >= i_min(ry), str("plate too small for device: needs ", min_cells(m, ry, ry2) + margin_a + margin_b, " cells along"));
echo(str("Assembly: plate ", cells_x, " x ", cells_y, " cells; screws on hole columns ", i0, " and ", i0 + n,
         ", rows from ", j0, " (cap A) and ", j0 + m, " (cap B)"));

// Inner faces of the left side wall and of cap A's end wall.
X0 = hole(i0) + wall + off;
Y0 = hole(j0) - t[0];
// Screw centres and cap footprint [min, max] in this frame, for tests/assembly.scad.
screw_xs = [hole(i0), hole(i0 + n)];
screw_ys = concat([for (z = hole_zs[0]) Y0 - wall + z], [for (z = hole_zs[1]) Y0 + inner_h + wall - z]);
foot_x = [hole(i0) - rx, hole(i0 + n) + rx];
foot_y = [Y0 - wall, Y0 + inner_h + wall];
// Screw holes in gearplate model XY (print orientation mirrors X), kept when !full_holes.
keep = [for (x = screw_xs, y = screw_ys) [cells_x*cell - x, y]];

// Slots vs holes (model XY): true if the slot cutter (r + rim chamfer) breaks into a
// hole of radius insert_d/2 centred at p. A cap screw hole may not be cut (D28).
function seg_d(p, a, b) = let (ab = b - a, t = ab*ab == 0 ? 0 : max(0, min(1, (p - a)*ab / (ab*ab))))
    norm(p - a - t*ab);
function in_slot(p) = len([for (s = slots) if (s != [0, 0, 0, 0]) for (g = slot_segs(s, cells_x, cells_y, slot_r))
    if (seg_d(p, g[0], g[1]) < slot_r + chamfer + insert_d/2) 1]) > 0;
for (k = keep) assert(!in_slot(k), str("a slot cuts a cap screw hole at hole column ",
    round((cells_x*cell - k[0] - pitch/2) / pitch), ", row ", round((k[1] - pitch/2) / pitch)));

// Hole map for picking slot indices (D28): one char per hole, row 0 (cap A end) at the
// bottom, as seen from the device face. + cap screw, O slot, A / B under cap A / B,
// X under the device, S snap under a cap or the device, s corner snap, . free insert hole.
// Runs of A, B or X/S are joined into blocks.
function cat(l, i = 0) = i >= len(l) ? "" : str(l[i], cat(l, i + 1));
function is_screw(x, y) = len([for (sx = screw_xs, sy = screw_ys) if (abs(sx - x) + abs(sy - y) < 1e-6) 1]) > 0;
function map_ch(i, j) = let (x = hole(i), y = hole(j),
    snap = min([for (sx = snap_pos(cells_x), sy = snap_pos(cells_y)) max(abs(x - sx), abs(y - sy))]) < cell/2,
    in_x = x > foot_x[0] && x < foot_x[1])
    is_screw(x, y) ? "+"
  : in_slot([cells_x*cell - x, y]) ? "O"
  : in_x && y > foot_y[0] && y < Y0 - wall + clen[0] ? (snap ? "S" : "A")
  : in_x && y > foot_y[1] - clen[1] && y < foot_y[1] ? (snap ? "S" : "B")
  : x > X0 + fit && x < X0 + fit + device_w && y > Y0 + fit/2 && y < Y0 + fit/2 + device_h ? (snap ? "S" : "X")
  : snap ? "s" : ".";
// Inside a block, S takes the letter of its neighbour.
function join(a, b) = let (c = a == "S" ? b : a, d = b == "S" ? a : b)
    c == d && (c == "A" || c == "B" || c == "X") ? c : " ";
// Geometry for spec.py (the spec.png drawing), face view in mm. Echo prints this as JSON.
echo(Spec = [["cells", [cells_x, cells_y]], ["cell", cell], ["edge_gap", edge_gap], ["snap_w", snap_w],
    ["slot_r", slot_r], ["margins", [margin_a, margin_b, margin_l, margin_r]],
    ["snaps", [for (x = snap_pos(cells_x), y = snap_pos(cells_y)) [x, y]]],
    ["caps", [[foot_x[0], foot_y[0], foot_x[1], Y0 - wall + clen[0]], [foot_x[0], foot_y[1] - clen[1], foot_x[1], foot_y[1]]]],
    ["device", [X0 + fit, Y0 + fit/2, device_w, device_h]],
    ["screws", [for (x = screw_xs, y = screw_ys) [x, y]]],
    ["slots", [for (k = [0 : len(slots) - 1]) if (slots[k] != [0, 0, 0, 0])
        [k + 1, slots[k], [for (g = slot_segs(slots[k], cells_x, cells_y, slot_r)) [for (q = g) [cells_x*cell - q[0], q[1]]]]]]]]);
// "Map: " is stripped by task device:check.
echo(str("Map:     ", cat([for (i = [0 : 2*cells_x - 1]) str(i % 10, " ")])));
echo("Map:");
for (j = [2*cells_y - 1 : -1 : 0])
    echo(str("Map: ", j < 10 ? " " : "", j, "  ", cat([for (i = [0 : 2*cells_x - 1])
        str(map_ch(i, j), i < 2*cells_x - 1 ? join(map_ch(i, j), map_ch(i + 1, j)) : " ")])));
echo("Map:");
echo("Map: . insert hole  A/B cap  X device  S snap under cap/device  s snap  O slot  + cap screw");

if (part == "plate") gearplate(keep);
else {
    color("silver") translate([cells_x*cell, 0, 0]) rotate([0, 180, 0]) gearplate(keep);
    // One top-level statement per part: with lazy-union each becomes its own 3MF object.
    // (x,y,z) -> (-x, z, y)
    color("steelblue") translate([X0 + inner_w, Y0 - wall, 0]) rotate([0, 0, 180]) rotate([90, 0, 0]) cap(0);
    // (x,y,z) -> (x, -z, y)
    color("steelblue") translate([X0, Y0 + inner_h + wall, 0]) rotate([90, 0, 0]) cap(1);
    color("orange", 0.8) translate([X0 + fit, Y0 + fit/2, 0]) cube([device_w, device_h, device_d]);
}
