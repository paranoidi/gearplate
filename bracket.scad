// Device end caps for gearplate
// A pair of caps that screw onto the gearplate's 14mm insert grid, one over each end of
// a box-shaped device. Seen from the end, each cap is a hat:
//
//     |------------|      front strap over the device face
//     |  ________  |      end wall, with optional notches open from the plate side
// ----|  |      |  |----  flanges with screws, outboard (screwdriver clears the walls)
//
// Output is in print orientation: both caps lying on their end wall, side by side.

// Device width in mm
device_w = 60;
// Device height (distance between the two caps) in mm
device_h = 100;
// Device depth (plate to front face) in mm
device_d = 25;
// Clearance per side around the device
fit = 0.5;
// Wall, end wall and strap thickness
wall = 3;
// Flange thickness
flange_t = 4;
// How far a cap reaches along the device, end wall included (grows if a screw needs room)
cap_len = 15;
// Screw clearance hole (M3)
screw_d = 3.4;
// Screwdriver / screw head clearance diameter
driver_d = 7;
// Extra margin around the screwdriver
driver_margin = 1;

/* [Cutouts, cap A] */
// End-wall notches [w, h, x_offset], open from the plate side, seen from outside with
// the strap on top: x_offset 0 = centred, + = right. [0,0,0] = off.
a_cut1 = [0, 0, 0];
a_cut2 = [0, 0, 0];
a_cut3 = [0, 0, 0];
a_cut4 = [0, 0, 0];

/* [Cutouts, cap B] */
b_cut1 = [0, 0, 0];
b_cut2 = [0, 0, 0];
b_cut3 = [0, 0, 0];
b_cut4 = [0, 0, 0];

/* [Hidden] */
pitch = 14;
$fs = 0.5;
$fa = 5;

// Distance between the left and right hole rows: the smallest multiple of the hole
// pitch that leaves `clear` between each side wall and its screw centre, so both rows
// land on the gearplate grid.
function hole_span(inner_w, wall, clear) = pitch * ceil((inner_w + 2*wall + 2*clear) / pitch);
// Side wall outer face -> screw centre.
function hole_off(inner_w, wall, clear) = (hole_span(inner_w, wall, clear) - inner_w) / 2 - wall;
// End wall inner face -> first screw, >= t_min, chosen so cap A's and cap B's screws
// are a multiple of the pitch apart along the device.
function cap_hole_t(inner_h, t_min) = (inner_h - pitch * floor((inner_h - 2*t_min) / pitch)) / 2;

clear = driver_d/2 + driver_margin;
inner_w = device_w + 2*fit;
in_d = device_d + fit;
inner_h = device_h + fit;
off = hole_off(inner_w, wall, clear);
t = cap_hole_t(inner_h, max(0, clear - wall));
clen = max(cap_len, wall + t + clear);
hole_zs = [for (z = [wall + t : pitch : clen - clear]) z];
flange_w = off + clear;
outer_w = inner_w + 2*wall;
wall_h = in_d + wall;

assert(device_w > 0 && device_h > 0 && device_d > 0, "device dimensions must be > 0");
assert(inner_h >= 2*max(0, clear - wall), "device_h too small for the screw spacing");

cuts = [[a_cut1, a_cut2, a_cut3, a_cut4], [b_cut1, b_cut2, b_cut3, b_cut4]];
for (b = [0, 1], k = [0 : 3]) let (c = cuts[b][k], name = str(b ? "b" : "a", "_cut", k+1))
    if (c != [0, 0, 0]) {
        assert(len(c) == 3, str(name, " must be [w, h, x_offset]"));
        assert(c[0] > 0 && c[1] > 0 && abs(c[2]) + c[0]/2 <= inner_w/2 && c[1] <= in_d,
               str(name, " must fit inside the end wall (", inner_w, " wide, ", in_d, " high)"));
    }

echo(str("Cap hole rows are ", hole_span(inner_w, wall, clear) / pitch, " holes apart across; ",
         "cap A and cap B screws are ", (inner_h - 2*t) / pitch, " holes apart along the device"));

// x across the device (0 = inner face of the left side wall), y up from the plate,
// z along the device from the end wall's outer face (print bed).
module cap(cutouts) {
    eps = 0.01;
    difference() {
        union() {
            translate([-wall, 0, 0]) cube([outer_w, wall_h, wall]);                   // end wall
            translate([-wall, 0, 0]) cube([wall, wall_h, clen]);                      // side walls
            translate([inner_w, 0, 0]) cube([wall, wall_h, clen]);
            translate([-wall, in_d, 0]) cube([outer_w, wall, clen]);                  // front strap
            for (x = [-wall - flange_w, inner_w + wall])                              // flanges
                translate([x, 0, 0]) cube([flange_w, flange_t, clen]);
        }
        for (x = [-wall - off, inner_w + wall + off], z = hole_zs)
            translate([x, -eps, z]) rotate([-90, 0, 0]) cylinder(d=screw_d, h=flange_t + 2*eps);
        // the print bed view is from below, so +x_offset (right, seen from outside) is -x here
        for (c = cutouts) if (c != [0, 0, 0])
            translate([inner_w/2 - c[2] - c[0]/2, -eps, -eps]) cube([c[0], c[1] + eps, wall + 2*eps]);
    }
}

cap(cuts[0]);
translate([outer_w + 2*flange_w + 5, 0, 0]) cap(cuts[1]);
