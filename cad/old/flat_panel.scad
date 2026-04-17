/*
 * RedCat 51 DIY Flat Panel — Parametric OpenSCAD Model
 * Based on user sketch (transversal cross-section)
 *
 * Printer: A1 mini (180 × 180 × 180 mm bed)
 *
 * ── GEOMETRY NOTE ────────────────────────────────────────────
 *  A square of side s fits inside a circle of radius r only if
 *  r ≥ s×√2/2  (half the diagonal).
 *  For s = 56 mm → r ≥ 39.6 mm → inner_d ≥ 79.2 mm.
 *  We use inner_d = 80 mm → housing_od = 88 mm (4 mm walls).
 *  The "80 mm" dimension in the sketch is the INNER diameter.
 *
 * ── LIGHT PATH (telescope → sky) ────────────────────────────
 *
 *   [telescope aperture 51 mm]
 *        ↑ light enters here
 *   ──── hinge axis ────────────────────────────────────────
 *   [diffuser_ring ×1]    bottom of stack; holds 56×56 mm frosted acrylic
 *   [air_gap_ring]        5 mm gap between diffuser layers
 *   [diffuser_ring ×1]    holds 56×56 mm frosted acrylic
 *   [main_body]           LED strip on ceiling, solid top (sky)
 *                         Z-bracket arm drives the hinge
 *                         LEDs shine downward ↓
 *   ── sky side ──
 *
 *  When CLOSED: stack sits centered over the telescope aperture.
 *  When OPEN:   stepper rotates 270° → entire stack parks
 *               alongside the tube (parallel, minimal wind catch).
 *
 * ── PARTS ────────────────────────────────────────────────────
 *   motor_housing()   ×1  black   holds 28BYJ-48; velcro-straps to tube
 *   diffuser_ring()   ×2  white   56×56 mm square acrylic slot
 *   air_gap_ring()    ×1  black   5 mm hollow spacer
 *   main_body()       ×1  black   LED tray + Z-bracket pivot arm
 *
 * ── PRINT SETTINGS ───────────────────────────────────────────
 *   0.2 mm layer · 3 perimeters · 25 % infill · no supports needed
 */

// ═══════════════════════════════════════════════════════════════
//  PARAMETERS  — edit before printing
// ═══════════════════════════════════════════════════════════════

// Velcro strap (for motor_housing attachment to scope tube)
strap_w   = 20;   // strap width (mm) — standard 20 mm hook-and-loop tape
strap_t   =  4;   // slot height (mm) — strap thickness + clearance

// Housing geometry  (from user sketch)
inner_d       = 80.0;      // Inner cavity diameter — acrylic spans this
wall          =  4.0;      // Wall thickness for main parts
housing_od    = inner_d + 2 * wall;   // 88 mm outer diameter

// Acrylic diffuser — 56×56 mm square (score-and-snap, two cuts)
// Fits inside 80 mm inner circle: corner radius = 56×√2/2 = 39.6 mm < 40 mm ✓
// Fully contains the 51 mm telescope aperture (51 < 56) ✓
acrylic_sq    = 56.0;      // Square side length (mm)
acrylic_t     =  3.4;      // 3 mm acrylic + 0.4 mm clearance
slot_sq       = acrylic_sq + 0.4;   // slot with insertion clearance
shelf_h       =  2.0;      // shelf height the acrylic rests on
aperture_d    = 68.0;      // circular light aperture below shelf (> 51 mm aperture)

// Part heights (from sketch)
adapter_h     = 25;        // tall enough for stepper pocket + set screws
body_h        = 10;        // LED tray
diffuser_h    =  5;        // each diffuser ring
air_gap_h     =  5;        // air gap between diffusers
arm_t         =  3;        // pivot arm thickness (also = recess depth in adapter top)

// 28BYJ-48 stepper motor
stepper_d     = 28.2;
stepper_len   = 19.5;
shaft_d       =  5.0;
shaft_flat_y  =  1.6;      // flat cut offset from centre on D-shaft

// Light-sealing skirt (on bottom diffuser ring)
// When closed the skirt slides over the adapter OD, creating a narrow
// annular gap + a 90° turn that blocks ambient light.
// The arm notch in the skirt (~16 mm arc) is the only break —
// fill it with a strip of 2 mm black craft foam tape after assembly.
skirt_h   =  8.0;   // overlap length (adapter OD covered by skirt)
skirt_t   =  2.0;   // skirt wall thickness
skirt_gap =  0.35;  // radial clearance between skirt inner face and adapter OD

// Hardware
m3_clear      = 3.4;
m3_head_d     = 6.5;
m2_clear      = 2.4;

// Derived
bolt_r        = housing_od / 2 - 5;        // bolt circle radius (all parts)

// ── Motor placement (tangential mount) ──────────────────────────
//
//  The 28BYJ-48 body runs along Y (tangential to the housing).
//  Shaft points in -Y, emerges at y = 0 (the XZ plane of the arm).
//  Motor body extends from y = 0 to y = +stepper_len.
//
//  shaft_cx = X position of shaft = housing outer wall + half motor diameter + clearance
//  This keeps the full motor body outside the housing OD so it never
//  enters the arc swept by the rotating lid.
//
//  The arm (in the XZ plane, y = 0) reaches from x = 0 to x = shaft_cx.
//  The bracket extends in +Y only — perpendicular to the lid's sweep plane.
//  → lid rotates freely through 0°–90° with no collision.
//
bracket_wall  =  3.0;   // bracket wall thickness around motor body
arm_hub_d     = 14;    // arm hub diameter (around D-shaft hole)
arm_clear     = arm_hub_d / 2 + 2;   // Y gap reserved at y=0 for arm passage (= 9 mm)
                                      // bracket material only exists at y > arm_clear
                                      // so the arm sweeps freely in the XZ plane (y≈0)
shaft_cx      = housing_od / 2 + stepper_d / 2 + bracket_wall + 1;  // ~62 mm
stepper_z     = adapter_h - arm_t;   // shaft centre Z (flush with adapter top)

$fn = 128;

// ═══════════════════════════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════════════════════════

module d_shaft_hole(h = 10) {
    linear_extrude(h)
        difference() {
            circle(d = shaft_d + 0.4);
            translate([0, shaft_flat_y + shaft_d / 2])
                square([shaft_d + 1, shaft_d], center = true);
        }
}

// Three M3 bolt flanges at bolt_r, 120° spacing
module flanges(h, screw = false) {
    for (a = [0, 120, 240])
        rotate([0, 0, a])
            translate([bolt_r, 0, 0])
                if (screw)
                    cylinder(d = m3_clear, h = h + 2);
                else
                    cylinder(d = m3_head_d * 1.4, h = h);
}

// Rounded-corner square (avoids sharp interior corners for printability)
// The acrylic (sharp corners) fits because the slot is wider in the corners
module rounded_square_slot(s, corner_r, h) {
    hull()
        for (x = [-s/2 + corner_r, s/2 - corner_r],
                 y = [-s/2 + corner_r, s/2 - corner_r])
            translate([x, y, 0])
                cylinder(r = corner_r, h = h);
}

// Pivot arm shape (reused for both the arm and the recess)
module arm_shape(h) {
    hull() {
        translate([housing_od / 2 - arm_hub_d / 2, 0, 0])
            cylinder(d = arm_hub_d, h = h);
        translate([shaft_cx, 0, 0])
            cylinder(d = arm_hub_d, h = h);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 1 — MOTOR HOUSING
//
//  Standalone box that holds the 28BYJ-48 stepper motor and attaches
//  to the telescope tube with velcro straps — no adapter ring needed.
//
//  The motor body runs along Y; the D-shaft emerges at y = 0 and
//  connects to the pivot arm on main_body.
//
//  Two oblong strap slots are cut through the housing on the ±Z faces
//  (above and below the motor pocket).  Thread a velcro strap through
//  each slot, wrap both straps under the scope tube, and press the
//  velcro faces together to secure the housing.
//
//  Placement in assembly: translate([shaft_cx, 0, stepper_z])
//
//  Side view (XZ plane, scope tube below):
//
//    ┌─[slot]─┐
//    │        │   ← housing body (rounded box)
//    │  (==)  │   ← motor pocket (cylinder along Y)
//    │        │
//    └─[slot]─┘
//         ↓ ↓     ← velcro straps wrap under scope tube
//    ─────────    ← scope tube (dew shield OD ≈ 63 mm)
//
// ═══════════════════════════════════════════════════════════════

module motor_housing() {
    // Housing body dimensions (centred on shaft axis)
    bw     = stepper_d / 2 + bracket_wall;   // XZ half-width (motor + wall): ~17 mm
    bd     = stepper_len + bracket_wall;      // Y depth (motor + back wall):  ~23 mm

    // Strap slot Z offset: slot sits just outside the motor pocket,
    // centred in the extra wall material between motor OD and housing OD.
    slot_z = stepper_d / 2 + strap_t / 2 + 1.5;   // ~17.9 mm from shaft axis
    bw_z   = slot_z + strap_t / 2 + bracket_wall;  // total Z half-height: ~22.9 mm

    difference() {
        // Rounded rectangular box — hull of 8 spheres at the corners
        hull()
            for (x = [-bw + bracket_wall,  bw - bracket_wall],
                     y = [bracket_wall,     bd - bracket_wall],
                     z = [-bw_z + bracket_wall, bw_z - bracket_wall])
                translate([x, y, z])
                    sphere(d = bracket_wall * 2);

        // Motor pocket — cylindrical bore along Y (open at y = 0 face)
        translate([0, bd / 2, 0])
            rotate([90, 0, 0])
                cylinder(d = stepper_d + 0.4, h = bd + 2, center = true);

        // Shaft bore — small clearance at the y = 0 (shaft) face
        translate([0, -1, 0])
            rotate([-90, 0, 0])
                cylinder(d = shaft_d + 1.5, h = bracket_wall + 2);

        // Strap slots — two oblong through-holes (±Z), running all the
        // way through in X so the strap exits on the scope-facing side.
        // Elongated in Y (strap_w) so the strap seats cleanly.
        for (s = [-1, 1])
            translate([-bw - 1,
                       (bd - strap_w) / 2,
                       s * slot_z - strap_t / 2])
                cube([2 * bw + 2, strap_w, strap_t]);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 2 — DIFFUSER RING   (print × 2)
//
//  Holds a 56×56 mm square of 3 mm frosted acrylic.
//  Score-and-snap the acrylic — two straight cuts, no circle cutter needed.
//
//  Plain optical rings — NO pivot arm.  The arm lives on main_body (see
//  Part 4), exactly like the Pegasus FlatMaster Neo: structural attachment
//  at the back of the housing, not on the diffuser elements.
//
//  The BOTTOM ring (with_skirt = true) has a full 360° light-sealing skirt
//  that slides over the adapter OD when closed. No arm notch needed — the
//  skirt is unbroken, giving better ambient-light rejection than before.
//
//  Light path (bottom → top):
//   ① 68 mm circular aperture at the bottom lets light through.
//   ② Acrylic rests on the 2 mm shelf just above the aperture.
//   ③ Light passes through the frosted acrylic and exits the top.
//
//  Acrylic insertion: drop the 56×56 mm square in from the TOP.
//  The rounded-corner slot allows the square (sharp corners) to slide in.
//  For the topmost ring: two small drops of CA glue on opposite corners.
// ═══════════════════════════════════════════════════════════════

module diffuser_ring(with_skirt = false) {
    difference() {
        union() {
            cylinder(d = housing_od, h = diffuser_h);
            translate([0, 0, diffuser_h - 4])
                flanges(h = 4);

            // Full 360° light-sealing skirt on bottom ring — slides over adapter OD.
            // No arm notch needed (arm is on main_body), so the skirt is continuous.
            if (with_skirt)
                difference() {
                    // Skirt body: thin-walled cylinder below ring bottom
                    translate([0, 0, -skirt_h])
                        cylinder(d = housing_od + 2 * (skirt_gap + skirt_t), h = skirt_h);
                    // Hollow interior (clearance over adapter OD)
                    translate([0, 0, -skirt_h - 1])
                        cylinder(d = housing_od + 2 * skirt_gap, h = skirt_h + 2);
                }
        }

        // ① Circular light aperture — from bottom up to shelf
        translate([0, 0, -1])
            cylinder(d = aperture_d, h = shelf_h + 2);

        // ② Rounded-corner square slot — from shelf through top face
        translate([0, 0, shelf_h])
            rounded_square_slot(s = slot_sq, corner_r = 4, h = diffuser_h - shelf_h + 1);

        // Flange bolt holes
        translate([0, 0, diffuser_h - 4])
            flanges(h = 4, screw = true);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 3 — AIR GAP RING
//  5 mm hollow spacer between the two diffuser layers.
// ═══════════════════════════════════════════════════════════════

module air_gap_ring() {
    difference() {
        union() {
            difference() {
                cylinder(d = housing_od, h = air_gap_h);
                translate([0, 0, -1])
                    cylinder(d = inner_d, h = air_gap_h + 2);
            }
            translate([0, 0, air_gap_h - 4])
                flanges(h = 4);
        }
        translate([0, 0, air_gap_h - 4])
            flanges(h = 4, screw = true);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 4 — MAIN BODY (LED TRAY)
//
//  Sky-facing outer cap.  Cavity OPENS DOWNWARD onto the diffusers.
//  LED strip is mounted on the CEILING (inner top face), shining down.
//  The solid top (sky side) seals the assembly — no separate cover needed.
//
//  The pivot arm is integral to this part (like the Pegasus FlatMaster):
//  it extends downward from the body base, spanning the full stack height,
//  and terminates at the stepper shaft with a D-shaft press-fit hub.
//  The diffuser rings have no mechanical role — they are plain optical rings.
//
//  The COB LED strip (8 mm wide) runs in two straight parallel channels
//  across the ceiling, spaced to give even coverage.
//  Paint the inner walls and ceiling WHITE for better reflectivity.
//
//  Cross-section:
//    ┌──────────────────────────────┐  ← solid top (sky side, 4 mm)
//    │ ┌────────────┐ ┌───────────┐ │  ← LED channel 1  LED channel 2
//    │                             │  ← inner ceiling (white)
//    │                             │
//    │           open              │  ← 10 mm cavity, open at bottom
//    │                             │
//    └─────────────────────────────┘  ← open bottom (diffuser ring below)
//    │arm│                            ← pivot arm continues downward
//    │   │                              arm_ext = diffuser×2 + air_gap + arm_t
//    [hub]                           ← D-shaft hub at stepper shaft level
// ═══════════════════════════════════════════════════════════════

module main_body() {
    solid_top  = 4;
    led_w      = 9;
    led_depth  = 2;
    led_offset = inner_d / 2 * 0.55;
    // Total downward reach from body bottom to stepper shaft centre
    arm_ext    = diffuser_h + air_gap_h + diffuser_h + arm_t;  // 5+5+5+3 = 18 mm

    difference() {
        union() {
            cylinder(d = housing_od, h = body_h);
            flanges(h = 4);

            // Pivot arm — Z-bracket with two 90° bends (like Pegasus FlatMaster Neo
            // side view). Three segments, all axis-aligned, no diagonals:
            //
            //  [main_body sky face]
            //  ●━━━━┓   ← seg 1: short horizontal outward from housing wall to arm_body_x
            //       ┃   ← seg 2: long vertical — arm BODY runs outside housing OD
            //       ┃             alongside the full diffuser stack
            //       ┗━━━●  ← seg 3: short horizontal outward to shaft_cx (D-shaft hub)
            //  [stepper shaft level]
            //
            // arm_body_x: arm body runs just proud of the housing OD so it is
            // fully clear of all rotating/fixed rings at every open angle.
            {
                arm_body_x = housing_od / 2 + arm_hub_d / 2 + 2;  // 44+7+2 = 53 mm
                union() {
                    // Segment 1 — short horizontal on sky (back) face of main_body
                    hull() {
                        translate([housing_od / 2 - arm_hub_d / 2, 0, body_h - arm_t])
                            cylinder(d = arm_hub_d, h = arm_t);
                        translate([arm_body_x, 0, body_h - arm_t])
                            cylinder(d = arm_hub_d, h = arm_t);
                    }
                    // Segment 2 — long vertical arm body alongside the diffuser stack
                    hull() {
                        translate([arm_body_x, 0, body_h - arm_t])
                            cylinder(d = arm_hub_d, h = arm_t);
                        translate([arm_body_x, 0, -arm_ext])
                            cylinder(d = arm_hub_d, h = arm_t);
                    }
                    // Segment 3 — short horizontal to D-shaft hub at shaft_cx
                    hull() {
                        translate([arm_body_x, 0, -arm_ext])
                            cylinder(d = arm_hub_d, h = arm_t);
                        translate([shaft_cx, 0, -arm_ext])
                            cylinder(d = arm_hub_d, h = arm_t);
                    }
                }
            }
        }

        // Cavity — opens at the BOTTOM (z = 0), ceiling at (body_h - solid_top)
        translate([0, 0, -1])
            cylinder(d = inner_d, h = body_h - solid_top + 1);

        // LED strip channels on ceiling
        for (y = [-led_offset, led_offset])
            translate([0, y, body_h - solid_top - led_depth])
                cube([inner_d - 2, led_w, led_depth + 1], center = true);

        // Wire exit notch in side wall (for LED USB cable)
        translate([0, -(housing_od / 2), body_h / 3])
            cube([7, 5, 6], center = true);

        // Bottom flange bolt holes
        flanges(h = 4, screw = true);

        // D-shaft hole in arm hub (at arm tip — stepper shaft level)
        translate([shaft_cx, 0, -arm_ext - 1])
            d_shaft_hole(h = arm_t + 2);

        // M3 set screw radially through arm hub (locks to D-shaft flat)
        translate([shaft_cx, 0, -arm_ext + arm_t / 2])
            rotate([90, 0, 0])
                cylinder(d = 3.0, h = arm_hub_d, center = true);
    }
}


// ═══════════════════════════════════════════════════════════════
//  ASSEMBLY PREVIEW
//  Telescope side at BOTTOM (z = 0), sky side at TOP.
//
//  OPEN_ANGLE controls the panel position for preview:
//    0  = closed (panel covers aperture, perpendicular to tube)
//    90 = open   (panel lies alongside tube, parallel to tube axis)
//
//  ROTATION AXIS (shown in cyan):
//    The stepper shaft points along Y (TANGENTIAL to the housing).
//    Rotation happens in the XZ plane — like a hinged lid.
//    The panel swings from flat-over-aperture to flat-alongside-tube.
//
//    Why Y and not X?
//      • Tube axis = Z
//      • Panel must move in X and Z to fold alongside the tube → XZ plane
//      • Axis perpendicular to XZ plane = Y  ✓
//
//  Motor body: tangentially mounted (body along Y, centred at shaft_cx in X).
// ═══════════════════════════════════════════════════════════════

OPEN_ANGLE = 90;   // 0 = closed, 90 = open alongside tube

module assembly() {
    z_diff1  = adapter_h;             // bottom diffuser ring (= stepper_z + arm_t)
    z_gap    = z_diff1 + diffuser_h;
    z_diff2  = z_gap   + air_gap_h;
    z_body   = z_diff2 + diffuser_h;

    // ── Motor housing — fixed to scope tube via velcro straps ─
    // Shaft centre at (shaft_cx, 0, stepper_z) in global frame.
    color("black", 0.90)
        translate([shaft_cx, 0, stepper_z])
            motor_housing();

    // ── Phantom shaft / rotation axis (cyan line along Y) ─────
    // Passes through (shaft_cx, 0, stepper_z), extends in ±Y direction
    shaft_vis_len = housing_od + 40;
    color("cyan", 0.85)
        translate([shaft_cx, -shaft_vis_len / 2, z_adapt + stepper_z])
            rotate([-90, 0, 0])
                cylinder(d = 1.5, h = shaft_vis_len);

    // Arrow-head at +Y end to show axis direction
    color("cyan", 0.85)
        translate([shaft_cx, shaft_vis_len / 2, z_adapt + stepper_z])
            rotate([-90, 0, 0])
                cylinder(d1 = 4, d2 = 0, h = 6);

    // ── Panel stack — rotates about Y axis at (shaft_cx, 0, stepper_z) ─
    translate([shaft_cx, 0, z_adapt + stepper_z])
        rotate([0, OPEN_ANGLE, 0])
            translate([-shaft_cx, 0, -(z_adapt + stepper_z)]) {
                color("white",   0.85) translate([0, 0, z_diff1]) diffuser_ring(with_skirt = true);
                color("dimgray", 0.50) translate([0, 0, z_gap])   air_gap_ring();
                color("white",   0.85) translate([0, 0, z_diff2]) diffuser_ring();
                color("black",   0.90) translate([0, 0, z_body])  main_body();
            }
}

// ═══════════════════════════════════════════════════════════════
//  PRINT LAYOUT — uncomment ONE part, then File → Export → STL
// ═══════════════════════════════════════════════════════════════

assembly();   // full preview — comment out when exporting a part

// motor_housing();
// diffuser_ring(with_skirt = true); // bottom ring — has light-seal skirt (print ×1)
// diffuser_ring();                  // top ring    — plain                 (print ×1)
// air_gap_ring();
// main_body();
