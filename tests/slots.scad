// Slot coordinate mapping and corner-snap overlap rule. Run: task test
use <../gearplate.scad>
// front view mirrors X: index 0 is the leftmost hole as seen from the device face
assert(slot_pt(0, 0, 2) == [49, 7]);
assert(slot_pt(3, 3, 2) == [7, 49]);
// -1 / 2*cells sit one pitch outside the board, so the slot opens out of the edge
assert(slot_pt(-1, 0, 2)[0] == 63 && slot_pt(4, 0, 2)[0] == -7);
// 4x4 board: hole indices 0,1 and 6,7 are the corner cells on each axis
assert(slot_hits_snap([1, 0, 2, 0], 4, 4, 7));     // ends inside a corner cell
assert(slot_hits_snap([-1, 1, 1, 1], 4, 4, 7));    // edge slot through a corner cell
assert(slot_hits_snap([2, 0, 6, 0], 4, 4, 7));     // bottom edge row reaching a corner
assert(slot_hits_snap([3, 3, 1, 1], 4, 4, 7));     // diagonal into a corner
assert(!slot_hits_snap([2, 0, 5, 0], 4, 4, 7));    // bottom edge row between corners
assert(!slot_hits_snap([2, 6, 2, 8], 4, 4, 7));    // just beside a corner cell, out the top edge
assert(!slot_hits_snap([-1, 3, 3, 3], 4, 4, 7));   // left edge, mid height
assert(!slot_hits_snap([2, 2, 5, 5], 4, 4, 7));    // mid-board diagonal
// radius counts: col 2 is 21mm from the snap centre; clear at r=7, hits at r=10
assert(!slot_hits_snap([2, 1, 3, 1], 4, 4, 7));
assert(slot_hits_snap([2, 1, 3, 1], 4, 4, 10));
// edge extensions (4x4 board, 112mm, board edge at 0.3 / 111.7)
assert(len(slot_segs([2, 2, 5, 5], 4, 4, 7)) == 1);             // mid-board: plain capsule
er = slot_segs([2, 0, 5, 0], 4, 4, 7);                          // edge row: both ends open down
assert(len(er) == 3 && er[1][1][1] < -7 && er[2][1][1] < -7 && er[1][1][0] == er[1][0][0]);
px = slot_segs([-1, 3, 1, 3], 4, 4, 7);                         // -1 clamps to col 0, exits left
assert(len(px) == 2 && px[0][0] == slot_pt(0, 3, 4) && px[1][1][0] > 112 + 7 && px[1][1][1] == px[0][0][1]);
assert(len(slot_segs([2, 0, 5, 0], 4, 4, 4)) == 1);             // small r keeps its edge wall
assert(!slot_hits_snap([5, -1, 3, 2], 4, 4, 7));                // diagonal exit between snaps
echo("PASS slots");
