/*
 * Motor mount & dew-shield seat — RedCat 51 flip-flat panel
 * Companion to flat_panel.scad (panel stack + linkage arms).
 *
 * ── PARTS (two prints + optional lid) ───────────────────────────
 *   seat()        ×1  saddle strapped to the dew shield with 2 velcro
 *                     strips threaded through slotted ear rails at the
 *                     saddle edges; flat platform on top with 4× M3
 *                     heat-set inserts (Ø4.2 holes)
 *   motor_case()  ×1  28BYJ-48 housing + riser column + base flange,
 *                     bolts to the seat platform with 4× M3×8.
 *                     Motor slides in from the open back with its ear
 *                     tabs riding in full-depth side slots (keyed
 *                     rotation). D-shaft exits the front face into
 *                     the linkage_arm hub.
 *   case_lid()    ×1  flush back cover with a cable notch. 2× M3×25
 *                     pass through the lid, across the ear slots,
 *                     through the motor's ear holes, and self-tap into
 *                     blind pilots in the front wall — one screw pair
 *                     retains both the lid and the motor.
 *
 * ── FRAME OF REFERENCE (preview) ────────────────────────────────
 *   Y = dew shield / optical axis (+Y toward the sky)
 *   Z = up (radial),  X = motor shaft / hinge axis (shaft → +X)
 *   Origin on the optical axis, directly under the hinge.
 *
 * ── LAYOUT NOTES ────────────────────────────────────────────────
 *   • The panel rides ~24.5 mm toward the shaft side of the case
 *     center (it is centered between the two arms while the motor
 *     hangs behind the lower arm), so the case sits offset by
 *     case_x_off on the seat to land the panel on the optical axis.
 *   • The hinge sits only ~21 mm behind the closed panel's back face
 *     (arm horizontal reach 51 mm − panel stack). The seat therefore
 *     extends mostly BACKWARD from the hinge: short nose (seat_front)
 *     toward the sky, long tail toward the mount. Strap the seat so
 *     the hinge lands just behind the dew shield's front rim.
 *
 * ── HEIGHT TUNING ───────────────────────────────────────────────
 *   riser_h raises the hinge axis. The compile log echoes the hinge
 *   height H above the optical axis; the linkage arm slot must be able
 *   to reach H, and H sets how far the panel hangs below the tube at
 *   the end of its 270° swing. riser_h must also keep the case shell
 *   above the closed panel's top edge (checked/echoed). Use
 *   preview_open (0–270) to eyeball collisions in the preview.
 *
 * ── PRINT (Bambu A1 mini, no supports) ──────────────────────────
 *   seat        — auto-oriented standing on a Y end face (ring
 *                 cross-section vertical); use a brim
 *   motor_case  — as modeled, base flange down (bore has a 45°
 *                 teardrop roof; front of the column has a 45° slope)
 *   case_lid    — auto-oriented flat
 */

// BOSL2 must be included here too: flat_panel.scad's modules call BOSL2's
// overridden primitives, which need BOSL2's top-level $-variables in scope
include <BOSL2/std.scad>
include <arms.scad>

use <stepper.scad>
use <flat_panel.scad>

/* [View] */
part = "case"; // [preview, seat, case, lid, arms]
// Arm opening angle in preview (0 = closed on the aperture)
preview_open = 270; // [0:270]
// animate the swing 0→270°: enable this, then View ▸ Animate and set
// e.g. FPS 20 / Steps 100 (overrides preview_open with 270 × $t)
animate = false;
show_motor  = true;
show_arms   = true;
show_panel  = true;
show_shield = true;
show_lid    = true;
add_case_screw_insert = false;

/* [Dew shield / seat] */
dew_shield_od = 84.0;  // measured OD of the RedCat 51 dew shield
fit_gap       = 0.4;   // radial clearance saddle ↔ shield
seat_t        = 4.0;   // saddle wall thickness
seat_arc      = 110;   // angular span of the saddle
// seat nose ahead of the hinge axis — keep < ~20 so the closed panel clears
seat_front    = 18;
// number of velcro straps (= slot pairs along the seat; sets seat length)
strap_count   = 1;
// velcro strap width
strap_w       = 50;
strap_slot_t  = 5.0;   // slot opening (strap thickness + threading room)
ear_ext       = 16;    // tangential ear length past the saddle edge
ear_t         = 5.0;   // ear plate thickness
ear_margin    = 4;     // solid margin at both slot ends
mid_gap       = 6;     // gap between the two strap slots
slot_start    = 4;     // slot begins this far out from the saddle edge

/* [Platform / case interface] */
// case offset along the hinge axis (see LAYOUT NOTES)
case_x_off = -24.5;
plat_bot   = 35;     // platform block underside (above optical axis)
plat_extra = 3;      // platform top above the saddle outer apex
// 4× M3 screw pattern: back row + west-lip pair (the +X/front sides are
// swept by the arm and panel, so no screws there)
scr_back_y  = -33;
scr_back_dx = 8;
scr_side_x  = -18.5;
scr_side_dy = 12;
insert_d    = 4.2;   // heat-set insert hole Ø
insert_dep  = 7;     // heat-set insert hole depth
m3_clear    = 4.0;   // M3 clearance Ø (matches flat_panel.scad)
m3_head_d   = 6.5;

/* [Riser / motor case] */
// raise the hinge axis to clear the panel swing  ** main tuning knob **
riser_h   = 35;
flange_t  = 4;     // base flange thickness
case_wall = 2.5;
front_t   = 2.0;   // front wall (shaft side; holds the blind screw pilots)
case_hw   = 23;    // case half-width along Y
// flange extents (asymmetric: long tail, short nose)
flg_x0    = -22;
flg_y0    = -37;
flg_y1    = 18;
panel_r   = 55.5;  // flat-panel outer radius, for clearance checks
panel_off = -105;   // offset of the flat panel on the arm

/* [28BYJ-48 motor] */
motor_d       = 28.2;
motor_len     = 19.5;
motor_clear   = 2;  // radial + axial pocket clearance
shaft_off     = 8.0;  // shaft offset from body center
flange_hole_d = 10.0; // pass-through for the Ø9 collar
recess_d      = 16;   // front-face relief so the arm hub grabs more shaft
recess_dep    = 2.0;
ear_spacing   = 35.0; // motor ear holes, center-to-center
tab_d         = 7.0;  // motor ear tab end Ø (tabs span ear_spacing + tab_d)
tab_clear     = 0.8;  // ear slot clearance around the tabs
ear_pilot     = 2.7;  // M3 self-tap pilot Ø
wire_w        = 14.6; // blue wire cover
wire_drop     = 17.5; // wire cover bottom below body center

$fn = 128;

// ═══════════════════════════════════════════════════════════════
//  DERIVED
// ═══════════════════════════════════════════════════════════════

r_fit    = dew_shield_od/2 + fit_gap;
r_out    = r_fit + seat_t;
plat_top = r_out + plat_extra;          // platform top above optical axis

slot_len   = strap_w + 3;               // slot length along the shield
ear_len_y  = slot_len + 2*ear_margin;
strap_pitch = ear_len_y + mid_gap;      // center-to-center strap spacing
seat_len   = strap_count*ear_len_y + (strap_count - 1)*mid_gap;  // overall
seat_yc    = seat_front - seat_len/2;   // seat center (asymmetric)
// strap centers, evenly spread about the seat center
strap_ys   = [for (i = [0 : strap_count - 1])
                 seat_yc + (i - (strap_count - 1)/2) * strap_pitch];

// platform screw pattern, shared by the case flange and the seat inserts
scr_pts = [[ scr_back_dx, scr_back_y], [-scr_back_dx, scr_back_y],
           [ scr_side_x,  scr_side_dy], [ scr_side_x, -scr_side_dy]];

bore_d     = motor_d + motor_clear;
bore_dep   = motor_len + motor_clear;
x_front    = 12;                        // case front outer face
x_face     = x_front - front_t;         // motor face plane
x_back     = x_face - bore_dep;         // open back face
z_case     = flange_t + riser_h;        // case shell bottom
z_body     = z_case + case_wall + wire_drop + 0.5;  // motor body center
z_shaft    = z_body + shaft_off;        // hinge axis above platform
case_top   = z_body + motor_d/2 + case_wall + 0.4;
// column front must be set back / sloped until above the closed panel's top
clear_z    = panel_r + 1.5 - plat_top;  // local z where full width is safe

echo(str("Seat: ", seat_len, " mm long, from y=", seat_front, " to y=",
         seat_front - seat_len, "  (shield+tube must carry this behind the rim)"));
echo(str("Hinge axis height H above optical axis: ", plat_top + z_shaft,
         " mm  (arm slot must reach this)"));
// front face y at the closed panel's top height (chamfer keeps it back)
front_y_at_panel_top = flg_y1 - 0.5 + max(0, panel_r - plat_top) * (case_hw - flg_y1) / (clear_z + 5);
echo(str("Case front face at panel-top height: y=", front_y_at_panel_top,
         " mm — ", front_y_at_panel_top < 20.5 ? "OK" : "intrudes on closed panel!",
         " (panel back face ≈ y=21)"));
echo(str("Lid/motor screws: 2× M3×",
         ceil(2.5 - 1.2 + (x_face - x_back) + front_t - 0.9),
         " (lid + ear slot + blind pilot, must NOT reach the front face)"));

// ═══════════════════════════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════════════════════════

// box with rounded vertical edges
module rbox(x0, x1, y0, y1, za, zb, r = 3) {
    hull()
        for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r])
            translate([x, y, za])
                cylinder(h = zb - za, r = r);
}

// horizontal-hole cross-section: circle + 45° roof, flat-topped at +clip
module teardrop2d(d, clip) {
    r = d/2;
    intersection() {
        union() {
            circle(r);
            polygon([[-r*sin(45), r*cos(45)], [0, 1.4142*r], [r*sin(45), r*cos(45)]]);
        }
        translate([-r - 1, -r - 1]) square([d + 2, r + 1 + clip]);
    }
}

// teardrop hole along X, axis at (y, z), from x0 to x1
module teardrop_x(d, x0, x1, y, z, clip) {
    translate([x0, y, z])
        rotate([90, 0, 90])
            linear_extrude(x1 - x0)
                teardrop2d(d, clip);
}

// ═══════════════════════════════════════════════════════════════
//  SEAT  — saddle + velcro ears + platform
// ═══════════════════════════════════════════════════════════════

// constant cross-section in the XZ plane (x right, y2d = up/Z)
module seat_section_2d() {
    half = seat_arc/2;
    union() {
        // saddle ring sector
        intersection() {
            difference() {
                circle(r_out);
                circle(r_fit);
            }
            polygon([[0, 0], [-2*r_out*sin(half), 2*r_out*cos(half)],
                             [ 2*r_out*sin(half), 2*r_out*cos(half)]]);
        }
        // ear rails, tangent at the saddle edges
        for (s = [-1, 1])
            rotate(-s * half)
                translate([s == 1 ? -2 : -ear_ext, r_fit])
                    square([ear_ext + 2, ear_t]);
    }
}

module seat() {
    difference() {
        union() {
            // saddle + ear rails, shifted backward (asymmetric)
            translate([0, seat_yc, 0])
                rotate([90, 0, 0])
                    linear_extrude(seat_len, center = true)
                        seat_section_2d();
            // platform block under the case footprint + screw bosses
            // (asymmetric margins: the +Y edge must stay behind the panel)
            translate([case_x_off + flg_x0 - 3.5, flg_y0 - 3.5, plat_bot])
                cube([x_front - flg_x0 + 6, flg_y1 - flg_y0 + 4.5, plat_top - plat_bot]);
        }

        // dew shield bore
        rotate([90, 0, 0])
            cylinder(h = 3*seat_len, r = r_fit, center = true);

        // velcro slots through the ear rails, flush with the shield
        for (s = [-1, 1], yp = strap_ys)
            rotate([0, s * seat_arc/2, 0])
                translate([s == 1 ? slot_start : -slot_start - strap_slot_t,
                           yp - slot_len/2, r_fit - 2])
                    cube([strap_slot_t, slot_len, ear_t + 4]);

        // M3 heat-set insert holes (match the case flange pattern)
        for (p = scr_pts)
            translate([case_x_off + p[0], p[1], plat_top - insert_dep])
                cylinder(h = insert_dep + 1, d = insert_d);
    }
}

// ═══════════════════════════════════════════════════════════════
//  MOTOR CASE  — flange + riser + 28BYJ-48 housing
//  (modeled print-ready: flange bottom on z=0, sits on the platform)
// ═══════════════════════════════════════════════════════════════

module motor_case() {
    zs = clear_z + 5;                              // slope tops out here
    slope_a = atan(zs / (case_hw - flg_y1));       // slope angle from horizontal
    difference() {
        union() {
            // base flange: long tail, short nose (closed panel sweeps past +Y)
            rbox(flg_x0, x_front, flg_y0, flg_y1, 0, flange_t, 4);
            // screw bosses so every hole is fully surrounded by material
            for (p = scr_pts)
                translate([p[0], p[1], 0]) cylinder(h = flange_t, d = 13);
            // riser column + case shell
            rbox(x_back, x_front, -case_hw, case_hw, 0, case_top, 3);
        }

        // chamfer the front-bottom edge: the column widens from ~flg_y1 at the
        // flange to full width at zs, keeping it behind the closed panel
        // (anchored 0.5 inside flg_y1 to avoid a tangent, zero-volume cut)
        translate([0, flg_y1 - 0.5, 0])
            rotate([slope_a, 0, 0])
                translate([x_back - 1, 0, -30])
                    cube([x_front - x_back + 2, 60, 30]);

        // motor bore, open at the back, 45° teardrop roof
        teardrop_x(bore_d, x_back - 1, x_face, 0, z_body, motor_d/2 + 0.4);

        // full-depth ear slots: the motor slides in with its tabs riding
        // here, which also keys its rotation; the lid screws cross them
        hull()
            for (s = [-1, 1])
                translate([x_back - 1, s * ear_spacing/2, z_body])
                    rotate([0, 90, 0])
                        cylinder(h = x_face - x_back + 1, d = tab_d + tab_clear);

        // wire-cover trench in the cavity floor, runs out the open back
        translate([x_back - 1, -(wire_w/2 + 0.5), z_case - 2])
            cube([x_face - x_back + 1, wire_w + 1, z_body - 10.5 - (z_case - 2)]);

        // shaft collar pass-through
        //teardrop_x(flange_hole_d, x_face - 1, x_front + 1, 0, z_shaft, flange_hole_d/2 * 0.8)
        translate([x_face - 1, 0, z_shaft])
            rotate([90, 0, 90])
            cylinder(h=20, r=flange_hole_d/2)
        
        // front-face relief so the arm hub can ride closer to the shaft base
        translate([x_front - recess_dep, 0, z_shaft])
            rotate([0, 90, 0])
                cylinder(h = recess_dep + 0.1, d = recess_d);

        // blind M3 self-tap pilots in the front wall for the lid screws
        // (blind: they must not break through into the arm's swing plane)
        // Not blind finally, easier to add M3 insert
        if (add_case_screw_insert)
            for (s = [-1, 1])
                translate([x_face - 0.1, s * ear_spacing/2, z_body])
                    rotate([0, 90, 0])
                        cylinder(h = front_t + 0.6, d = ear_pilot);

        // 4× M3 down to the platform inserts, counterbored heads
        for (p = scr_pts)
            translate([p[0], p[1], 0]) {
                translate([0, 0, -1])             cylinder(h = flange_t + 2, d = m3_clear);
                translate([0, 0, flange_t - 2.2]) cylinder(h = 2.3, d = m3_head_d + 0.5);
            }
    }
}

// ═══════════════════════════════════════════════════════════════
//  BACK LID  (optional — modeled in place behind the case)
// ═══════════════════════════════════════════════════════════════

// rounded rectangle in the (y, z) plane
module rrect2d(y0, y1, z0, z1, r = 3) {
    hull()
        for (y = [y0 + r, y1 - r], z = [z0 + r, z1 - r])
            translate([y, z]) circle(r);
}

module case_lid_in_place() {
    lid_t = 2.5;
    difference() {
        translate([x_back - lid_t - 0.1, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(lid_t)
                    rrect2d(-case_hw + 1, case_hw - 1, z_case - 3, case_top, 3);
        // lid screws align with the motor ear holes and the wall pilots
        for (s = [-1, 1])
            translate([x_back - lid_t - 1, s * ear_spacing/2, z_body]) {
                rotate([0, 90, 0]) cylinder(h = lid_t + 2, d = 3.4);
                rotate([0, 90, 0]) cylinder(h = 1.2 + 1, d = m3_head_d + 0.3);
            }
        // cable notch, bottom center
        translate([x_back - lid_t - 1, -8, z_case - 1])
            cube([lid_t + 2, 16, 11]);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PREVIEW
// ═══════════════════════════════════════════════════════════════

module preview() {
    // shield ghost with its front rim where the closed panel's pad
    // holder lands (~21 mm ahead of the hinge)
    if (show_shield)
        color("orange", 0.25)
            rotate([90, 0, 0])
                translate([0, 0, -21])
                    cylinder(h = 220, r = dew_shield_od/2);

    color("SteelBlue") seat();

    translate([case_x_off, 0, plat_top]) {
        color("DimGray") motor_case();
        if (show_lid) color("DimGray") case_lid_in_place();

        if (show_motor)
            translate([x_face, 0, z_body])
                rotate([90, 0, -90])
                    stepper_28byj48();

        // linkage arms + approximate panel envelope, from flat_panel.scad.
        // The 93.5° base rotation points the arm down-forward so the panel
        // roughly meets the optical axis (exact position = arm slot).
        if (show_arms)
            translate([0, 0, z_shaft])
                rotate([90 + (animate ? 270*$t : preview_open), 0, 0])
                    translate([24.5, 0, 0])
                        rotate([0, 90, 0]) {
                            linkage_arms();
                            if (show_panel) {
                                // panel stack ghost: Ø111 × 41, at slot-mid
                                color("white", 0.35)
                                    translate([41, panel_off, 0])
                                        rotate([0, 90, 0])
                                            cylinder(h = 41, r = panel_r, center = true);
                                // Mega/ULN case on the panel back (from
                                // flat_panel.scad) — fattens the swept
                                // envelope; recheck riser_h / hang-down
                                // clearance with this ghost visible
                                //color("red", 0.25)
                                //    translate([33 + 33/2, panel_off, 0])
                                //        rotate([0, -90, 0])
                                //            mega_case_envelope();
                            }
                        }
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART SELECTOR
// ═══════════════════════════════════════════════════════════════

if (part == "preview") {
    preview();
} else if (part == "seat") {
    // standing on a Y end face — prints without supports
    translate([0, 0, seat_len - seat_front]) rotate([90, 0, 0]) seat();
} else if (part == "case") {
    motor_case();          // already flange-down
} else if (part == "lid") {
    // laid flat for printing
    translate([0, 0, x_back - 0.1]) rotate([0, 90, 0]) case_lid_in_place();
} else if (part == "arms") {
    linkage_arms();
}
