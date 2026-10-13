// openGrid stacking piece
// A 1x1 openGrid tile on a solid floor with 4 countersunk screw holes on the gearplate
// hole pattern. Screw it onto a gearplate's face (into its inserts), then click the
// next gearplate's corner snaps into it.
//
// Tile geometry: opengrid-tile.scad (vendored QuackWorks openGrid.scad)
// (openGrid by David D, OpenSCAD by BlackjackDuck, CC-BY-NC-SA 4.0). Requires BOSL2.
//
// Output is in print orientation: floor on the bed, grid opening up.

// BOSL2 $-globals must be defined here: a used file's top-level $vars stay hidden
include <BOSL2/std.scad>
use <opengrid-tile.scad>
use <gearplate.scad>  // chamfered_box()

// Use an openGrid Lite tile (4mm instead of 6.8mm)
lite = false;
// Solid floor under the tile in mm
floor_thickness = 3.5;
// Screw clearance hole diameter (M3 default)
screw_d = 3.4;
// Screw head recess: countersunk cone or flat-bottomed counterbore
head_type = "countersunk"; // [countersunk, counterbore]
// Head diameter (M3 countersunk ISO 10642: 6.72; socket ISO 4762: 5.5)
head_d = 6.8;
// Head height (M3 countersunk: 1.86; socket: 3); heads sit flush with the floor top
head_h = 1.9;
// Clearance per edge so neighbouring pieces don't collide
edge_gap = 0.3;
// 45° chamfer on all outer edges (0 = none)
chamfer = 0.4;

/* [Hidden] */
cell = 28;
pitch = 14;
// Tile corner block reach from the cell corner along the diagonal (openGridTileAp1 cornerOffset)
corner_reach = 5.56985;
tile_h = lite ? 4 : 6.8;
$fs = 0.5;
$fa = 5;

// Hole centres relative to the cell centre: the gearplate's 4 holes per cell (D1)
hole_offsets = [-pitch/2, pitch/2];

assert(head_type == "countersunk" || head_type == "counterbore", "head_type must be countersunk or counterbore");
assert(chamfer >= 0 && 2*chamfer < floor_thickness, "chamfer must be >= 0 and < floor_thickness/2");
assert(head_d > screw_d, "head_d must be > screw_d");
assert(head_h < floor_thickness, "head_h must be < floor_thickness");
assert(pitch/2 * sqrt(2) - head_d/2 > corner_reach, "head_d too big: hits the tile's corner blocks");

module stacking() {
    eps = 0.01;
    w = cell - 2*edge_gap;
    difference() {
        // clip to the edge_gap footprint and chamfer every outer edge in one go
        intersection() {
            translate([-w/2, -w/2, 0]) chamfered_box([w, w, floor_thickness + tile_h - eps], chamfer);
            union() {
                translate([-w/2, -w/2, 0]) cube([w, w, floor_thickness]);
                translate([0, 0, floor_thickness - eps])
                    if (lite) openGridLite(Board_Width=1, Board_Height=1, anchor=BOT);
                    else openGrid(Board_Width=1, Board_Height=1, anchor=BOT);
            }
        }
        for (x = hole_offsets, y = hole_offsets) translate([x, y, 0]) {
            translate([0, 0, -eps]) cylinder(d=screw_d, h=floor_thickness + 2*eps);
            translate([0, 0, floor_thickness - head_h])
                if (head_type == "counterbore") cylinder(d=head_d, h=head_h + eps);
                else cylinder(d1=screw_d, d2=head_d, h=head_h + eps);
        }
    }
}

if (is_undef(assembly)) stacking();
