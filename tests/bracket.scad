// Cap screws must land on the 14mm grid with screwdriver clearance. Run: task test
use <../bracket.scad>
for (w = [10 : 0.7 : 200], wall = [2, 3, 4.5], clear = [3, 4.5]) {
    s = hole_span(w, wall, clear);
    o = hole_off(w, wall, clear);
    assert(s % 14 == 0, str("span off-grid w=", w));
    assert(o >= clear && o < clear + 7, str("bad hole offset w=", w, " o=", o));
}
for (h = [40 : 0.3 : 300], wall = [2, 3, 4.5], t_min = [0, 1.5, 4]) {
    t = cap_hole_t(h, wall, t_min);
    a = (h - t[0] - t[1]) / 14;
    assert(abs(a - round(a)) < 1e-9, str("caps off-grid h=", h));
    assert(t[0] >= t_min - 1e-9 && t[0] < t_min + 14, str("bad cap A hole t h=", h, " t=", t));
    assert(t[1] >= t_min - 1e-9 && t[1] < t_min + 14 + 1e-9, str("bad cap B hole t h=", h, " t=", t));
    // cap A's end wall reach is flush with a plate edge: pitch/2 - edge_gap mod pitch
    r = (t[0] + wall - 6.7) / 14;
    assert(abs(r - round(r)) < 1e-9, str("cap A not edge-flush h=", h, " t=", t));
}
echo("PASS bracket");
