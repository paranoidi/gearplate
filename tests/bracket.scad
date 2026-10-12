// Cap screws must land on the 14mm grid with screwdriver clearance. Run: task test
use <../bracket.scad>
for (w = [10 : 0.7 : 200], wall = [2, 3, 4.5], clear = [3, 4.5]) {
    s = hole_span(w, wall, clear);
    o = hole_off(w, wall, clear);
    assert(s % 14 == 0, str("span off-grid w=", w));
    assert(o >= clear && o < clear + 7, str("bad hole offset w=", w, " o=", o));
}
for (h = [20 : 0.3 : 300], t_min = [0, 1.5, 4]) {
    t = cap_hole_t(h, t_min);
    assert(abs((h - 2*t) / 14 - round((h - 2*t) / 14)) < 1e-9, str("caps off-grid h=", h));
    assert(t >= t_min && t < t_min + 7, str("bad cap hole t h=", h, " t=", t));
}
echo("PASS bracket");
