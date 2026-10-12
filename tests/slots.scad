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
echo("PASS slots");
