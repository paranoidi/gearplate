// openGrid device board generator
// A board with heat-set insert holes on a 14mm pitch that stays continuous across
// adjacent boards, with an openGrid snap (optionally on a post) at each corner cell.
//
// Snap geometry: opengrid-snap.scad (vendored)
// (openGrid by David D, OpenSCAD by metasyntactic, CC-BY-NC-SA 4.0). Requires BOSL2.
//
// Output is in print orientation: device face (insert openings) on the bed, snaps up.

include <opengrid-snap.scad>

// Board width in openGrid cells
cells_x = 2; // [1:20]
// Board height in openGrid cells
cells_y = 2; // [1:20]
// Board thickness in mm
board_thickness = 5;
// Post height between board and snap in mm (0 = snap directly on board)
post_height = 0;
// Post diameter in mm (snap is 24.8mm wide)
post_diameter = 18;
// Use openGrid Lite snaps (3.4mm instead of 6.8mm)
lite = false;
// Heat-set insert hole diameter (M3 default); holes go through the board
insert_d = 4.0;
// Clearance per board edge so neighbouring boards don't collide
edge_gap = 0.3;

/* [Hidden] */
cell = 28;
pitch = 14;
snap_h = lite ? 3.4 : 6.8;
$fs = 0.5;
$fa = 5;

// Hole centres along one axis, relative to the cell lattice (not the board edge),
// so a neighbour offset by n*28 continues the same 14mm pattern.
function hole_pos(cells) = [for (i = [0 : 2*cells - 1]) pitch/2 + i*pitch];
// Corner-cell centres along one axis, de-duplicated for 1-cell boards.
function snap_pos(cells) = cells == 1 ? [cell/2] : [cell/2, cells*cell - cell/2];

assert(cells_x >= 1 && cells_y >= 1, "cells must be >= 1");
assert(post_diameter <= 24.8, "post_diameter must fit within the 24.8mm snap");

module gearplate() {
    eps = 0.01;
    difference() {
        translate([edge_gap, edge_gap, 0])
            cube([cells_x*cell - 2*edge_gap, cells_y*cell - 2*edge_gap, board_thickness]);
        for (x = hole_pos(cells_x), y = hole_pos(cells_y))
            translate([x, y, -eps]) cylinder(d=insert_d, h=board_thickness + 2*eps);
    }
    for (x = snap_pos(cells_x), y = snap_pos(cells_y)) translate([x, y, 0]) {
        if (post_height > 0)
            translate([0, 0, board_thickness - eps])
                cylinder(d=post_diameter, h=post_height + 2*eps);
        // snap top faces the board, grid-side points up
        translate([0, 0, board_thickness + post_height + snap_h/2 - eps])
            rotate([180, 0, 0]) openGridSnap(lite=lite);
    }
}

gearplate();
