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

/* [Cable slots] */
// Slots are [x1, y1, x2, y2] in hole-grid indices, seen from the device face:
// (0,0) = bottom-left hole. -1 or 2*cells reaches past that edge (slot opens out
// of the board). [0,0,0,0] = off. Slots may not touch the corner snaps.
slot1 = [0, 0, 0, 0];
slot2 = [0, 0, 0, 0];
slot3 = [0, 0, 0, 0];
slot4 = [0, 0, 0, 0];
slot5 = [0, 0, 0, 0];
slot6 = [0, 0, 0, 0];
slot7 = [0, 0, 0, 0];
slot8 = [0, 0, 0, 0];
// Slot radius in mm (7 = 14mm wide, one hole pitch)
slot_r = 7;

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
// Front-view hole index -> model XY. Print orientation is the device face seen
// from below, so X is mirrored.
function slot_pt(ix, iy, cx) = [cx*cell - (pitch/2 + ix*pitch), pitch/2 + iy*pitch];
// True if slot s = [x1,y1,x2,y2] comes within r of any snap footprint (24.8 square).
// ponytail: samples the segment every <=0.5mm and treats the snap as a square grown
// by r, which is conservative near snap corners.
function slot_hits_snap(s, cx, cy, r) =
    let (a = slot_pt(s[0], s[1], cx), b = slot_pt(s[2], s[3], cx),
         n = max(1, ceil(norm(b - a) / 0.5)))
    len([for (i = [0 : n], x = snap_pos(cx), y = snap_pos(cy))
         let (p = a + (b - a) * i / n)
         if (max(abs(p[0] - x), abs(p[1] - y)) < 24.8/2 + r) 1]) > 0;

assert(cells_x >= 1 && cells_y >= 1, "cells must be >= 1");
assert(post_diameter <= 24.8, "post_diameter must fit within the 24.8mm snap");
assert(slot_r > 0, "slot_r must be > 0");

slots = [slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8];
for (k = [0 : len(slots) - 1]) if (slots[k] != [0, 0, 0, 0]) {
    s = slots[k];
    assert(len(s) == 4, str("slot", k+1, " must be [x1, y1, x2, y2]"));
    for (j = [0 : 3]) let (lim = 2 * (j % 2 == 0 ? cells_x : cells_y))
        assert(s[j] == round(s[j]) && s[j] >= -1 && s[j] <= lim,
               str("slot", k+1, " index ", s[j], " must be an integer in -1..", lim));
    assert(!slot_hits_snap(s, cells_x, cells_y, slot_r), str("slot", k+1, " overlaps a corner snap"));
}

module gearplate() {
    eps = 0.01;
    difference() {
        translate([edge_gap, edge_gap, 0])
            cube([cells_x*cell - 2*edge_gap, cells_y*cell - 2*edge_gap, board_thickness]);
        for (x = hole_pos(cells_x), y = hole_pos(cells_y))
            translate([x, y, -eps]) cylinder(d=insert_d, h=board_thickness + 2*eps);
        for (s = slots) if (s != [0, 0, 0, 0])
            hull() for (p = [slot_pt(s[0], s[1], cells_x), slot_pt(s[2], s[3], cells_x)])
                translate([p[0], p[1], -eps]) cylinder(r=slot_r, h=board_thickness + 2*eps);
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
