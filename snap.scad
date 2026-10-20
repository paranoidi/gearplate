// openGrid snap with gearplate holes
// A standalone openGrid snap with 4 heat-set insert holes at +-7mm from its centre.
// Snaps sit centred on grid cells, so the holes of neighbouring snaps continue the
// gearplate's 14mm hole pattern across the grid (DESIGN.md D1).
//
// Snap geometry: opengrid-snap.scad (vendored)
// (openGrid by David D, OpenSCAD by metasyntactic, CC-BY-NC-SA 4.0). Requires BOSL2.
//
// Output is in print orientation: top plate (insert openings) on the bed, click nubs up.

include <opengrid-snap.scad>

// Use an openGrid Lite snap (3.4mm instead of 6.8mm)
lite = false;
// Heat-set insert hole diameter (M3 default); holes go through the snap
insert_d = 4.0;
// 45° chamfer on the insert holes at the top plate (0 = none)
chamfer = 0.4;

/* [Hidden] */
pitch = 14;
snap_h = lite ? 3.4 : 6.8;
$fs = 0.5;
$fa = 5;

// Hole centres relative to the snap (= cell) centre: the gearplate's 4 holes per cell
hole_offsets = [-pitch/2, pitch/2];

module snap() {
    eps = 0.01;
    difference() {
        // top plate on the bed, as in gearplate.scad
        translate([0, 0, snap_h/2]) rotate([180, 0, 0]) openGridSnap(lite=lite);
        for (x = hole_offsets, y = hole_offsets) translate([x, y, -eps]) {
            cylinder(d=insert_d, h=snap_h + 2*eps);
            if (chamfer > 0) cylinder(r1=insert_d/2 + chamfer + eps, r2=insert_d/2, h=chamfer + eps);
        }
    }
}

snap();
