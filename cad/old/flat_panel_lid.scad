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
 *   [adapter_ring]        tapered, grips 63 mm dew shield
 *                         stepper shaft at top face of adapter
 *   ──── hinge axis ────────────────────────────────────────
 *   [diffuser_ring ×1]    bottom of stack; arm drives the hinge
 *                         holds 56×56 mm frosted acrylic
 *   [air_gap_ring]        5 mm gap between diffuser layers
 *   [diffuser_ring ×1]    holds 56×56 mm frosted acrylic
 *   [main_body]           LED strip on ceiling, solid top (sky)
 *                         LEDs shine downward ↓
 *   ── sky side ──
 *
 *  When CLOSED: stack sits centered over the telescope aperture.
 *  When OPEN:   stepper rotates 270° → entire stack parks
 *               alongside the tube (parallel, minimal wind catch).
 *
 * ── PARTS ────────────────────────────────────────────────────
 *   adapter_ring()    ×1  black   tapered; stepper bracket on side
 *   diffuser_ring()   ×2  white   56×56 mm square acrylic slot
 *                               BOTTOM one also has pivot arm
 *   air_gap_ring()    ×1  black   5 mm hollow spacer
 *   main_body()       ×1  black   LED tray; open bottom; strip on ceiling
 *   stepper_plate()   ×1  black   retains 28BYJ-48 in adapter pocket
 *
 * ── PRINT SETTINGS ───────────────────────────────────────────
 *   0.2 mm layer · 3 perimeters · 25 % infill · no supports needed
 */

// ═══════════════════════════════════════════════════════════════
//  PARAMETERS  — edit before printing
// ═══════════════════════════════════════════════════════════════

// Telescope interface
dew_shield_od = 63.0;      // Measured OD of RedCat 51 dew shield (mm)
fit_gap       =  0.4;      // Radial clearance for friction fit

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
adapter_id    = dew_shield_od + fit_gap;   // 63.4 mm bore
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
arm_clear     = arm_hub_d / 2 + 2;   // Y gap reserved at y=0 for arm passage (= 9 mm)
                                      // bracket material only exists at y > arm_clear
                                      // so the arm sweeps freely in the XZ plane (y≈0)
shaft_cx      = housing_od / 2 + stepper_d / 2 + bracket_wall + 1;  // ~62 mm
stepper_z     = adapter_h - arm_t;   // shaft centre Z (flush with adapter top - arm recess)

arm_hub_d     = 14;   // arm hub diameter (around D-shaft hole)

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
//  PART 1 — ADAPTER RING
//
//  Tapered frustum: wide at top (housing_od) narrows to dew-shield bore.
//  The stepper bracket sits on the side, shaft at the very top face.
//  A recess on the top face receives the pivot arm when the panel is closed.
//
//  Cross-section (side view):
//   housing_od ──┐     ┌── housing_od
//                │     │
//                │     │   ← straight upper section
//                │     │
//                 \   /    ← tapered section
//                  │ │     ← bore (adapter_id)
//
// ═══════════════════════════════════════════════════════════════

module adapter_ring() {
    straight_h = adapter_h * 0.55;
    taper_h    = adapter_h - straight_h;

    difference() {
        union() {
            // Upper straight section
            translate([0, 0, taper_h])
                cylinder(d = housing_od, h = straight_h);

            // Lower tapered section
            wall_bot = 5;
            hull() {
                cylinder(d = adapter_id + 2 * wall_bot, h = 1);
                translate([0, 0, taper_h])
                    cylinder(d = housing_od, h = 1);
            }

            // Tangential stepper bracket
            // Occupies y = arm_clear … stepper_len + bracket_wall ONLY.
            // y = 0 … arm_clear is left completely open → arm swings freely in XZ plane.
            // Motor shaft end (at y=0) is supported by the adapter top-face wall only.
            translate([housing_od / 2,
                       arm_clear,
                       stepper_z - stepper_d / 2 - bracket_wall])
                cube([shaft_cx - housing_od / 2 + stepper_d / 2 + bracket_wall,
                      stepper_len + bracket_wall - arm_clear,
                      stepper_d + 2 * bracket_wall]);

            // Flanges on top face — connect to first diffuser_ring
            translate([0, 0, adapter_h - 4])
                flanges(h = 4);
        }

        // Bore through entire adapter
        translate([0, 0, -1])
            cylinder(d = adapter_id, h = adapter_h + 2);

        // Set-screw holes × 2 (M3, 180° apart) in taper section
        for (a = [0, 180])
            rotate([0, 0, a])
                translate([adapter_id / 2 + 3, 0, taper_h * 0.45])
                    rotate([0, 90, 0])
                        cylinder(d = 3.0, h = 10, center = true);

        // Motor pocket — cylindrical bore along Y through bracket body
        translate([shaft_cx, stepper_len / 2, stepper_z])
            rotate([90, 0, 0])
                cylinder(d = stepper_d + 0.4, h = stepper_len + 2, center = true);

        // Shaft bore through adapter top face (thin wall at y=0 supports shaft end)
        translate([shaft_cx, -1, stepper_z])
            rotate([-90, 0, 0])
                cylinder(d = shaft_d + 2, h = arm_clear + 2);

        // Retainer plate screw holes (M2) on far face of bracket
        for (x = [-3.9, 3.9])
            translate([shaft_cx + x, stepper_len + bracket_wall + 1, stepper_z])
                rotate([90, 0, 0])
                    cylinder(d = m2_clear, h = bracket_wall + 2);

        // Pivot arm recess on top face — arm sits here when panel is closed
        translate([0, 0, adapter_h - arm_t])
            arm_shape(h = arm_t + 1);

        // Flange bolt holes
        translate([0, 0, adapter_h - 4])
            flanges(h = 4, screw = true);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 2 — DIFFUSER RING   (print × 2)
//
//  Holds a 56×56 mm square of 3 mm frosted acrylic.
//  Score-and-snap the acrylic — two straight cuts, no circle cutter needed.
//
//  The BOTTOM diffuser ring (with_arm = true) has a pivot arm on its
//  underside that connects to the stepper shaft. This arm sits in the
//  recess on the adapter top face when the panel is closed.
//  The arm has a D-shaft hole — press-fit onto the 28BYJ-48 output shaft.
//  Add one M3 set screw through the arm hub into the flat for security.
//
//  The entire assembled stack (diffuser × 2 + air gap + main body) pivots
//  as one rigid unit around this shaft. Stepper rotates 270° to open.
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

module diffuser_ring(with_arm = false) {
    difference() {
        union() {
            cylinder(d = housing_od, h = diffuser_h);
            translate([0, 0, diffuser_h - 4])
                flanges(h = 4);

            // Pivot arm — extends below the ring, sits in adapter recess
            if (with_arm)
                translate([0, 0, -arm_t])
                    arm_shape(h = arm_t);

            // Light-sealing skirt — slides over adapter OD when closed
            // Creates a narrow annular gap + 90° turn that stops ambient light.
            // Arm notch (at azimuth 0°, +X) breaks the skirt ~16 mm wide;
            // cover that notch with a strip of 2 mm black foam tape.
            if (with_arm)
                difference() {
                    // Skirt body: thin-walled cylinder below ring bottom
                    translate([0, 0, -skirt_h])
                        cylinder(d = housing_od + 2 * (skirt_gap + skirt_t), h = skirt_h);
                    // Hollow interior (clearance over adapter OD)
                    translate([0, 0, -skirt_h - 1])
                        cylinder(d = housing_od + 2 * skirt_gap, h = skirt_h + 2);
                    // Arm notch — rectangular slot at azimuth 0°
                    // Width = arm_hub_d + 4 mm clearance; depth cuts full skirt wall
                    translate([housing_od / 2 + skirt_gap + skirt_t / 2, 0, -skirt_h - 1])
                        cube([skirt_t + 2, arm_hub_d + 4, skirt_h + 2], center = true);
                }
        }

        // ① Circular light aperture — from bottom up to shelf
        translate([0, 0, -arm_t - 1])
            cylinder(d = aperture_d, h = shelf_h + arm_t + 2);

        // ② Rounded-corner square slot — from shelf through top face
        translate([0, 0, shelf_h])
            rounded_square_slot(s = slot_sq, corner_r = 4, h = diffuser_h - shelf_h + 1);

        // D-shaft hole in pivot arm hub
        if (with_arm)
            translate([shaft_cx, 0, -arm_t - 1])
                d_shaft_hole(h = arm_t + 2);

        // M3 set screw into arm hub (locks arm to D-shaft flat)
        if (with_arm)
            translate([shaft_cx, 0, -arm_t / 2])
                rotate([90, 0, 0])
                    cylinder(d = 3.0, h = arm_hub_d, center = true);

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
// ═══════════════════════════════════════════════════════════════

module main_body() {
    solid_top  = 4;
    led_w      = 9;
    led_depth  = 2;
    led_offset = inner_d / 2 * 0.55;

    difference() {
        union() {
            cylinder(d = housing_od, h = body_h);
            flanges(h = 4);
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
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 5 — STEPPER RETAINER PLATE
//  Screws into the adapter bracket to retain the 28BYJ-48 motor.
// ═══════════════════════════════════════════════════════════════

module stepper_plate() {
    s = stepper_d + 8;
    t = 4;
    difference() {
        hull()
            for (x = [-s/2+4, s/2-4], y = [-s/2+4, s/2-4])
                translate([x, y, 0]) cylinder(d = 8, h = t);
        translate([0, 0, -1]) cylinder(d = 10, h = t + 2);
        for (y = [-3.9, 3.9])
            translate([0, y, -1]) cylinder(d = m2_clear, h = t + 2);
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
    z_adapt  = 0;
    z_diff1  = z_adapt  + adapter_h;
    z_gap    = z_diff1  + diffuser_h;
    z_diff2  = z_gap    + air_gap_h;
    z_body   = z_diff2  + diffuser_h;

    // ── Adapter — fixed on scope ──────────────────────────────
    color("black", 0.90) translate([0, 0, z_adapt]) adapter_ring();

    // ── Ghost stepper motor body (orange) ─────────────────────
    // Body along +Y, shaft at y=0 (connects to arm in XZ plane)
    // Bracket extends in +Y — entirely clear of the lid's XZ sweep
    color("orange", 0.40)
        translate([shaft_cx, 0, z_adapt + stepper_z])
            rotate([90, 0, 0])
                cylinder(d = stepper_d, h = stepper_len);

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
                color("white",   0.85) translate([0, 0, z_diff1]) diffuser_ring(with_arm = true);
                color("dimgray", 0.50) translate([0, 0, z_gap])   air_gap_ring();
                color("white",   0.85) translate([0, 0, z_diff2]) diffuser_ring();
                color("black",   0.90) translate([0, 0, z_body])  main_body();
            }
}

// ═══════════════════════════════════════════════════════════════
//  PRINT LAYOUT — uncomment ONE part, then File → Export → STL
// ═══════════════════════════════════════════════════════════════

assembly();   // full preview — comment out when exporting a part

// adapter_ring();
// diffuser_ring(with_arm = true);   // bottom ring — has pivot arm (print ×1)
// diffuser_ring();                  // top ring    — no arm       (print ×1)
// air_gap_ring();
// main_body();
// stepper_plate();
