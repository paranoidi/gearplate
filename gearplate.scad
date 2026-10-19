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
// Use openGrid Lite snaps (3.4mm instead of 6.8mm)
lite = false;
// Heat-set insert hole diameter (M3 default); holes go through the board
insert_d = 4.0;
// Clearance per board edge so neighbouring boards don't collide
edge_gap = 0.3;
// 45° chamfer on board edges, cable slot rims (both faces) and insert holes (device face) (0 = none)
chamfer = 0.4;

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
// Snap footprint and its top-plate corner (opengrid-snap.scad: w, and BOSL2 rounding
// at $fn=2, which renders as a 45° corner cut). Posts use the same outline.
snap_w = 24.8;
snap_corner = 3.262743;
$fs = 0.5;
$fa = 5;
// Slot ends closer than slot_r + this to an edge open out through it (no thin slivers)
edge_min_wall = 2;

// Hole centres along one axis, relative to the cell lattice (not the board edge),
// so a neighbour offset by n*28 continues the same 14mm pattern.
function hole_pos(cells) = [for (i = [0 : 2*cells - 1]) pitch/2 + i*pitch];
// Corner-cell centres along one axis, de-duplicated for 1-cell boards.
function snap_pos(cells) = cells == 1 ? [cell/2] : [cell/2, cells*cell - cell/2];
// Front-view hole index -> model XY. Print orientation is the device face seen
// from below, so X is mirrored.
function slot_pt(ix, iy, cx) = [cx*cell - (pitch/2 + ix*pitch), pitch/2 + iy*pitch];
// Slot -> capsules [[a, b], ...] in model XY: the main slot plus, for each end that
// meets an edge, a straight extension out past that edge. The extension's sides are
// the circle's tangents, so the notch has parallel walls and leaves no sliver.
// An end meets an edge if its index is -1 / 2*cells (clamped to the edge row) or its
// circle comes within r + edge_min_wall of the edge.
function slot_segs(s, cx, cy, r) =
    let (lim = [2*cx - 1, 2*cy - 1], size = [cx*cell, cy*cell],
         ends = [[s[0], s[1]], [s[2], s[3]]],
         cl = [for (e = ends) [for (ax = [0, 1]) min(max(e[ax], 0), lim[ax])]],
         main = [for (e = cl) slot_pt(e[0], e[1], cx)],
         raw = [for (e = ends) slot_pt(e[0], e[1], cx)])
    concat([main], [for (k = [0, 1], ax = [0, 1])
        let (p = main[k],
             lo = p[ax] - edge_gap, hi = size[ax] - edge_gap - p[ax],
             dir = raw[k][ax] != p[ax] ? sign(raw[k][ax] - p[ax])
                 : lo < r + edge_min_wall ? -1
                 : hi < r + edge_min_wall ? 1 : 0,
             d = (dir < 0 ? lo : hi) + r + 1)
        if (dir != 0) [p, p + dir * d * (ax == 0 ? [1, 0] : [0, 1])]]);
// True if segment a-b, swept by r, comes within reach of any snap footprint (snap_w square).
// ponytail: samples the segment every <=0.5mm and treats the snap as a square grown
// by r, which is conservative near snap corners.
function seg_hits_snap(a, b, cx, cy, r) =
    let (n = max(1, ceil(norm(b - a) / 0.5)))
    len([for (i = [0 : n], x = snap_pos(cx), y = snap_pos(cy))
         let (p = a + (b - a) * i / n)
         if (max(abs(p[0] - x), abs(p[1] - y)) < snap_w/2 + r) 1]) > 0;
// True if any part of slot s = [x1,y1,x2,y2], edge extensions included, hits a snap.
function slot_hits_snap(s, cx, cy, r) =
    len([for (g = slot_segs(s, cx, cy, r)) if (seg_hits_snap(g[0], g[1], cx, cy, r)) 1]) > 0;

assert(cells_x >= 1 && cells_y >= 1, "cells must be >= 1");
assert(slot_r > 0, "slot_r must be > 0");
assert(chamfer >= 0 && 2*chamfer < board_thickness, "chamfer must be >= 0 and < board_thickness/2");

slots = [slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8];
for (k = [0 : len(slots) - 1]) if (slots[k] != [0, 0, 0, 0]) {
    s = slots[k];
    assert(len(s) == 4, str("slot", k+1, " must be [x1, y1, x2, y2]"));
    for (j = [0 : 3]) let (lim = 2 * (j % 2 == 0 ? cells_x : cells_y))
        assert(s[j] == round(s[j]) && s[j] >= -1 && s[j] <= lim,
               str("slot", k+1, " index ", s[j], " must be an integer in -1..", lim));
    assert(!slot_hits_snap(s, cells_x, cells_y, slot_r + chamfer), str("slot", k+1, " overlaps a corner snap"));
}

// ponytail: same octahedron as bracket.scad; move both to a shared file if a third copy appears
module octahedron(r) polyhedron([[r,0,0], [-r,0,0], [0,r,0], [0,-r,0], [0,0,r], [0,0,-r]],
    [[4,2,0], [4,1,2], [4,3,1], [4,0,3], [5,0,2], [5,2,1], [5,1,3], [5,3,0]]);

// Box with all 12 edges chamfered by c at 45°: hull of octahedra inset by c.
module chamfered_box(size, c) {
    if (c > 0)
        hull() for (x = [c, size[0] - c], y = [c, size[1] - c], z = [c, size[2] - c])
            translate([x, y, z]) octahedron(c);
    else cube(size);
}

// Capsule cutter along segment g, radius r, through height h, with 45° flares of c at
// both faces. Each layer is hulled on its own: one hull over both flares would fill
// the whole capsule out to r + c.
module chamfered_slot(g, r, h, c, eps) {
    hull() for (p = g) translate([p[0], p[1], -eps]) cylinder(r=r, h=h + 2*eps);
    if (c > 0) {
        hull() for (p = g) translate([p[0], p[1], -eps]) cylinder(r1=r + c + eps, r2=r, h=c + eps);
        hull() for (p = g) translate([p[0], p[1], h - c]) cylinder(r1=r, r2=r + c + eps, h=c + eps);
    }
}

module gearplate() {
    eps = 0.01;
    difference() {
        translate([edge_gap, edge_gap, 0])
            chamfered_box([cells_x*cell - 2*edge_gap, cells_y*cell - 2*edge_gap, board_thickness], chamfer);
        // insert holes, chamfered at the device face only (the snap side stays sharp)
        for (x = hole_pos(cells_x), y = hole_pos(cells_y)) translate([x, y, -eps]) {
            cylinder(d=insert_d, h=board_thickness + 2*eps);
            if (chamfer > 0) cylinder(r1=insert_d/2 + chamfer + eps, r2=insert_d/2, h=chamfer + eps);
        }
        for (s = slots) if (s != [0, 0, 0, 0]) for (g = slot_segs(s, cells_x, cells_y, slot_r))
            chamfered_slot(g, slot_r, board_thickness, chamfer, eps);
    }
    for (x = snap_pos(cells_x), y = snap_pos(cells_y)) translate([x, y, 0]) {
        if (post_height > 0)
            translate([0, 0, board_thickness - eps])
                cuboid([snap_w, snap_w, post_height + 2*eps], rounding=snap_corner,
                       edges="Z", $fn=2, anchor=BOTTOM);
        // snap top faces the board, grid-side points up
        translate([0, 0, board_thickness + post_height + snap_h/2 - eps])
            rotate([180, 0, 0]) openGridSnap(lite=lite);
    }
}

if (is_undef(assembly)) gearplate();  // assembly.scad places it itself
