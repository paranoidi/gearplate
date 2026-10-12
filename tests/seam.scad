// Hole pattern must continue at 14mm pitch across adjacent boards. Run: task test
use <../gearplate.scad>
for (c = [1:6], n = [1:6]) {
    a = hole_pos(c);
    b = [for (p = hole_pos(n)) p + c*28];
    assert(b[0] - a[len(a)-1] == 14, str("seam broken c=", c, " n=", n));
    assert(a[0] == 7 && a[len(a)-1] == c*28 - 7);
}
for (c = [1:6]) assert(len(snap_pos(c)) == (c == 1 ? 1 : 2));
echo("PASS seam");
cube(1); // openscad needs geometry to export
