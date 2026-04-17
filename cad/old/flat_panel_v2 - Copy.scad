/*
 * RedCat 51 DIY Flat Panel v2 — Parametric OpenSCAD Model
 *
 * Printer  : Bambu Lab A1 mini (180 × 180 × 180 mm bed)
 * Motor    : 28BYJ-48 stepper + ULN2003 driver
 * Firmware : STEPS_OPEN = 1536  →  270° swing (Pegasus FlatMaster NEO style)
 *
 * ── COLLISION-FREE GEOMETRY ──────────────────────────────────────
 *  The adapter bore tube is intentionally narrower (~73 mm OD) than
 *  the panel stack (88 mm OD).  During the 270° swing the panel
 *  overhangs the adapter by ~7.5 mm per side, so the far edge always
 *  clears the adapter wall with >7 mm margin at any angle.
 *
 * ── LIGHT PATH (telescope → sky) ────────────────────────────────
 *
 *   [telescope aperture 51 mm]
 *        ↑ light enters here
 *   [adapter_ring]     tapered bore tube, grips 63 mm dew shield
 *                      motor bracket on +X side; shaft at top face
 *   ──── hinge axis (Y) ─────────────────────────────────────────
 *   [diffuser_ring × 1]  bottom of stack; 56×56 mm frosted acrylic
 *   [air_gap_ring]        5 mm gap between diffuser layers
 *   [diffuser_ring × 1]  top; 56×56 mm frosted acrylic
 *   [main_body]          LED tray; COB strip on ceiling; solid top
 *   ── sky side ──
 *
 * ── PARTS ────────────────────────────────────────────────────────
 *   adapter_ring()                   ×1  black  bore tube + enclosed motor housing
 *   motor_cover()                    ×1  black  back plate sealing motor housing
 *   diffuser_ring(with_arm=true, …)  ×1  white  bottom ring — has flat arm
 *   diffuser_ring()                  ×1  white  top ring — plain optical
 *   air_gap_ring()                   ×1  black  hollow spacer
 *   main_body()                      ×1  black  LED tray (no arm)
 *   driver_enclosure()               ×1  black  ULN2003 board tray
 *   driver_lid()                     ×1  black  lid for driver enclosure
 *
 * ── LIGHT SEAL OPTIONS ───────────────────────────────────────────
 *   Option A (default): 2–3 mm black EVA foam ring on adapter top face.
 *   Option B          : set ENABLE_SKIRT = true — prints a 360° overlap
 *                       skirt on the bottom diffuser ring instead.
 *
 * ── PRINT SETTINGS ───────────────────────────────────────────────
 *   0.2 mm layer · 3 perimeters · 25 % infill · no supports needed
 *   Black PLA/PETG for all parts except diffuser rings (white/natural)
 */

// ═══════════════════════════════════════════════════════════════
//  GLOBAL TOGGLE
// ═══════════════════════════════════════════════════════════════

ENABLE_SKIRT = false;   // true → Option B skirt; false → Option A foam gasket

// ═══════════════════════════════════════════════════════════════
//  PARAMETERS  — edit before printing
// ═══════════════════════════════════════════════════════════════

// ── Telescope interface ──────────────────────────────────────
dew_shield_od = 63.0;      // Measured OD of RedCat 51 dew shield (mm)
fit_gap       =  0.4;      // Radial clearance for friction fit

// ── Housing geometry ─────────────────────────────────────────
inner_d    = 80.0;         // Inner cavity diameter of panel stack
wall       =  4.0;         // Wall thickness (diffuser rings, main body)
housing_od = inner_d + 2 * wall;   // 88 mm — panel stack OD

// ── Adapter bore tube (intentionally narrower than housing_od) ─
adapter_id  = dew_shield_od + fit_gap;   // 63.4 mm
adapter_wall =  4.0;                      // wall thickness of bore tube
                                          // (4 mm gives 1.3 mm arm clearance vs. 0.3 mm at 5 mm)
adapter_od  = adapter_id + 2 * adapter_wall;  // 71.4 mm
adapter_h   = 25;          // height of adapter ring

// ── Acrylic diffuser — 56×56 mm square ──────────────────────
acrylic_sq  = 56.0;
acrylic_t   =  3.4;        // 3 mm acrylic + 0.4 mm clearance
slot_sq     = acrylic_sq + 0.4;
shelf_h     =  2.0;        // shelf the acrylic rests on
aperture_d  = 68.0;        // circular light aperture below shelf

// ── Part heights ─────────────────────────────────────────────
body_h      = 10;          // LED tray height
diffuser_h  =  5;          // each diffuser ring
air_gap_h   =  5;          // air gap spacer

// ── Pivot arm ────────────────────────────────────────────────
arm_t       =  3;          // arm thickness / recess depth on adapter top
arm_hub_d   = 14;          // hub diameter at D-shaft end

// ── 28BYJ-48 stepper motor ───────────────────────────────────
stepper_d   = 28.2;        // body diameter
stepper_len = 19.5;        // body length (shaft end to back)
shaft_d     =  5.0;        // D-shaft diameter
shaft_flat  =  1.6;        // flat cut offset from shaft centre

// ── 28BYJ-48 mounting ear geometry ───────────────────────────
ear_hole_d    =  4.2;      // mounting ear hole diameter
ear_spacing   = 35.0;      // centre-to-centre between ear holes
ear_screw_d   =  3.4;      // M3 clearance for ear screws
taper_extra   =  3.0;      // extra OD at adapter bottom for dew shield entry flare

// ── Motor housing geometry ───────────────────────────────────
bracket_wall = 3.0;        // wall thickness of motor housing
arm_clear    = arm_hub_d / 2 + 2;  // 9 mm — clear zone at y=0 for arm sweep

// ── ULN2003 driver board  ─────────────────────────────────────
// *** Update these once you have the physical board ***
uln_pcb_w     = 28.0;  // PCB width  (long axis, X direction)
uln_pcb_l     = 32.0;  // PCB length (short axis, Y direction into enclosure)
uln_pcb_t     =  1.6;  // PCB thickness
uln_comp_h    = 12.0;  // component height above PCB (tallest element)
uln_wall      =  2.0;  // enclosure wall thickness
uln_mount_d   =  2.4;  // M2 PCB standoff hole diameter

// shaft_cx: X position of stepper shaft centre.
//
// Must satisfy TWO constraints:
//   ① Bracket clears arm sweep zone (motor body outside adapter OD):
//        shaft_cx ≥ adapter_od/2 + stepper_d/2 + bracket_wall
//   ② Main body clears bracket at 270°:
//        At 270° the body corner z' = stepper_z + (housing_od/2 − shaft_cx).
//        For z' < bracket_bottom (= stepper_z − stepper_d/2 − bracket_wall):
//        shaft_cx > housing_od/2 + stepper_d/2 + bracket_wall  (+margin)
//
// Constraint ② is always tighter (housing_od/2 > adapter_od/2).
// Use housing_od/2 + stepper_d/2 + bracket_wall + 5 mm safety margin.
shaft_cx = housing_od / 2 + stepper_d / 2 + bracket_wall + 5;
// = 44 + 14.1 + 3 + 5 = 66.1 mm
// Body-corner z' at 270° = 25 + (44 − 66.1) = 2.9 mm  < bracket_bottom 7.9 mm ✓

// stepper_z: Z height of shaft centre = adapter top face (pivot at top)
stepper_z    = adapter_h;  // 25 mm

// (Z-bracket arm removed — arm is now a flat horizontal lever on the
//  bottom diffuser ring.  Sweeps at constant Z so it never intersects
//  the adapter bore tube wall during the full 270° arc.)

// ── Light-sealing skirt (Option B) ──────────────────────────
skirt_h      =  8.0;       // overlap with adapter bore tube OD
skirt_t      =  2.0;       // skirt wall thickness
skirt_gap    =  0.35;      // radial clearance: skirt ID over adapter_od

// ── Bolt pattern ─────────────────────────────────────────────
bolt_r       = housing_od / 2 - 5;   // M3 bolt circle radius (44 - 5 = 39 mm)

// ── Hardware clearances ───────────────────────────────────────
m3_clear     = 3.4;
m3_head_d    = 6.5;

$fn = 128;

// ═══════════════════════════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════════════════════════

// D-shaft press-fit hole (flat on one side) — bores along +Y
// After rotate([-90,0,0]): profile lies in XZ plane, extrusion goes along +Y.
// D-flat faces −Z (downward).  Place at [cx, y_start, shaft_z]; h spans +Y.
module d_shaft_hole(h = 10) {
    rotate([-90, 0, 0])
        linear_extrude(h)
            difference() {
                circle(d = shaft_d + 0.4);
                translate([0, shaft_flat + shaft_d / 2])
                    square([shaft_d + 1, shaft_d], center = true);
            }
}

// 3× M3 bolt flanges at 120° spacing on bolt_r
module flanges(h, screw = false) {
    for (a = [0, 120, 240])
        rotate([0, 0, a])
            translate([bolt_r, 0, 0])
                if (screw)
                    cylinder(d = m3_clear,         h = h + 2);
                else
                    cylinder(d = m3_head_d * 1.4,  h = h);
}

// Rounded-corner square slot for acrylic (sharp-cornered acrylic fits fine)
module rounded_square_slot(s, corner_r, h) {
    hull()
        for (x = [-s/2 + corner_r, s/2 - corner_r],
                 y = [-s/2 + corner_r, s/2 - corner_r])
            translate([x, y, 0])
                cylinder(r = corner_r, h = h);
}

// Arm cross-section shape (hull between body wall tangent and shaft hub)
// Used for the arm recess on the adapter top face and for the arm itself.
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
//  Narrow bore tube (~71 mm OD) that grips the 63 mm dew shield.
//  Intentionally narrower than the panel stack (88 mm OD) so the
//  panel sweeps freely through 270° without hitting the adapter wall.
//
//  Motor housing on +X side — fully enclosed rectangular box:
//    • Box wraps around the 28BYJ-48 body with bracket_wall on all sides
//    • Motor slides in from the open +Y back face; motor_cover() seals it
//    • Front face (y = arm_clear) has shaft bore + 2× M3 ear screw holes
//    • Wire exit slot at bottom-back corner for the 5-wire motor cable
//    • The housing is within 17.1 mm radius of the shaft — always inside
//      the rotating panel's inner cavity (min distance 26.1 mm) → no
//      clearance cut needed on the housing itself
//
//  Panel-sweep clearance:
//    Only the bridge rib (x = 0 → housing) needs trimming above adapter_h.
//    The rib at the adapter wall (radius ~30 mm from shaft) enters the swept
//    volume above z = adapter_h.  Cylindrical cut at r > 24 mm removes it.
//
//  Light seal:
//    • Option A (foam): flat top face — lay adhesive EVA foam ring here.
//    • Option B (skirt): bottom diffuser ring skirt slides over adapter_od.
//
//  Mounting: friction fit over dew shield + 2× M3 nylon-tipped set screws.
// ═══════════════════════════════════════════════════════════════

module adapter_ring() {
    straight_h  = adapter_h * 0.55;          // ~13.75 mm — upper straight section
    taper_h     = adapter_h - straight_h;    // ~11.25 mm — lower taper

    // Ear positions: symmetrical about shaft_cx along X
    ear_x1      = shaft_cx - ear_spacing / 2;   // 48.6 mm
    ear_x2      = shaft_cx + ear_spacing / 2;   // 83.6 mm

    // Motor housing box dimensions
    hx_min      = ear_x1 - bracket_wall;    //  45.6 mm  (left wall outer face)
    hx_max      = ear_x2 + bracket_wall;    //  86.6 mm  (right wall outer face)
    hy_min      = arm_clear;                //   9.0 mm  (front wall outer face, y=0 side)
    hy_max      = arm_clear + bracket_wall + stepper_len + bracket_wall;  // 34.5 mm
    hz_min      = stepper_z - stepper_d / 2 - bracket_wall;  //   7.9 mm
    hz_max      = stepper_z + stepper_d / 2 + bracket_wall;  //  42.1 mm
    // Front wall (y = hy_min to hy_min+bracket_wall) contains ear holes + shaft bore.
    // Back face (y = hy_max) is open — motor slides in; motor_cover() seals it.

    // Bridge rib: thin web connecting adapter wall to housing, y = arm_clear plane
    bridge_top  = hz_max;   // same height as housing

    difference() {
        union() {
            // ── Upper straight bore tube
            translate([0, 0, taper_h])
                cylinder(d = adapter_od, h = straight_h);

            // ── Lower taper — wider at bottom for smooth dew shield entry
            hull() {
                cylinder(d = adapter_od + taper_extra, h = 1);
                translate([0, 0, taper_h])
                    cylinder(d = adapter_od, h = 1);
            }

            // ── Bridge rib: connects adapter wall to motor housing
            // Starts at x = 0 (bore centre) so bore subtraction creates a proper
            // face bond at the adapter wall (not just a tangent line contact).
            translate([0, hy_min, 0])
                cube([hx_min, bracket_wall, bridge_top]);

            // ── Enclosed motor housing box
            translate([hx_min, hy_min, hz_min])
                cube([hx_max - hx_min, hy_max - hy_min, hz_max - hz_min]);
        }

        // ── Bore through full adapter height
        translate([0, 0, -1])
            cylinder(d = adapter_id, h = adapter_h + 2);

        // ── Arm recess on top face (arm sits here when panel is closed)
        translate([0, 0, adapter_h - arm_t])
            arm_shape(h = arm_t + 1);

        // ── Hub boss pocket — recess for the ~1 mm collar below the arm hub
        //    pocket_z = adapter_h − hub_boss_h/2 = 25 − 4 = 21 mm
        //    pocket_h = hub_boss_h/2 − arm_t + 0.2 = 1.2 mm
        translate([shaft_cx, 0, adapter_h - (shaft_d + 3) / 2])
            cylinder(d = arm_hub_d + 0.6,
                     h = (shaft_d + 3) / 2 - arm_t + 0.2);

        // ── Motor body pocket inside housing (motor slides in from +Y)
        translate([shaft_cx, hy_min + bracket_wall - 1, stepper_z])
            rotate([-90, 0, 0])
                cylinder(d = stepper_d + 0.6,
                         h = stepper_len + 2);

        // ── Shaft bore: from y = −1 through front wall into arm swing zone
        translate([shaft_cx, -1, stepper_z])
            rotate([-90, 0, 0])
                cylinder(d = shaft_d + 2, h = arm_clear + bracket_wall + 2);

        // ── M3 ear screw holes through front wall (motor ears screw in from outside)
        for (ex = [ear_x1, ear_x2])
            translate([ex, hy_min - 1, stepper_z])
                rotate([-90, 0, 0])
                    cylinder(d = ear_screw_d, h = bracket_wall + 4);

        // ── Motor cover screw holes: 2× M2 on top and bottom of back edge
        //    (back edge = y = hy_max face, centred in X, near top and bottom of housing)
        for (zz = [hz_min + 4, hz_max - 4])
            translate([shaft_cx, hy_max + 1, zz])
                rotate([90, 0, 0])
                    cylinder(d = uln_mount_d, h = bracket_wall + 2);

        // ── Wire exit slot at bottom-back corner (5-wire motor cable)
        translate([shaft_cx - 4, hy_max - bracket_wall - 1, hz_min - 1])
            cube([8, bracket_wall + 2, 6]);

        // ── Panel-sweep clearance above adapter_h — only the bridge rib needs this
        // The housing itself (radius ≤17.1 mm from shaft) is safe.
        // The bridge at the adapter wall (radius ~30 mm) is trimmed above z = adapter_h.
        intersection() {
            // Half-space: above adapter_h, within bridge Y extent
            translate([-200, hy_min - 1, adapter_h])
                cube([400, bracket_wall + 2, bridge_top - adapter_h + 5]);
            // Remove bridge material outside 24 mm from shaft axis
            difference() {
                translate([-200, hy_min - 2, stepper_z - 100])
                    cube([400, bracket_wall + 4, 200]);
                translate([shaft_cx, hy_min - 3, stepper_z])
                    rotate([-90, 0, 0])
                        cylinder(r = 24, h = bracket_wall + 8);
            }
        }

        // ── Nylon-tipped M3 set screws × 2 (180° apart) in taper section
        for (a = [0, 180])
            rotate([0, 0, a])
                translate([adapter_id / 2 + 3, 0, taper_h * 0.45])
                    rotate([0, 90, 0])
                        cylinder(d = 3.0, h = 12, center = true);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 2 — DIFFUSER RING   (print × 2)
//
//  Holds a 56×56 mm square of 3 mm frosted acrylic (score-and-snap).
//
//  with_arm   = false (default) — plain ring.
//  with_arm   = true  — BOTTOM ring: adds flat horizontal arm below
//                       the ring body.  The arm sits in the adapter recess
//                       when closed and sweeps at constant Z throughout the
//                       270° arc — no collision with the adapter wall.
//                       Has D-shaft press-fit hole + M3 set screw.
//
//  with_skirt = false (default) — use foam gasket (Option A).
//  with_skirt = true  — Option B skirt; adds arm notch (~16 mm arc) at
//                       azimuth 0° so the arm passes through.  Cover the
//                       notch gap with a strip of 2 mm black foam tape.
//
//  Print bottom ring: diffuser_ring(with_arm=true, with_skirt=ENABLE_SKIRT)
//  Print top ring:    diffuser_ring()
// ═══════════════════════════════════════════════════════════════

module diffuser_ring(with_arm = false, with_skirt = false) {
    difference() {
        union() {
            cylinder(d = housing_od, h = diffuser_h);
            translate([0, 0, diffuser_h - 4])
                flanges(h = 4);

            // Flat pivot arm — extends below ring bottom, sits in adapter recess
            if (with_arm) {
                translate([0, 0, -arm_t])
                    arm_shape(h = arm_t);
                // Thickened hub boss — taller than arm_t so the Y-axis D-shaft
                // hole has adequate wall on both sides of the shaft.
                // Boss extends from z = -(shaft_d/2+1.5) to z = +(shaft_d/2+1.5).
                // The 1 mm collar below arm_t seats in the adapter hub pocket.
                hub_boss_h = shaft_d + 3;   // 8 mm: 4 mm each side of z=0
                translate([shaft_cx, 0, -(hub_boss_h / 2)])
                    cylinder(d = arm_hub_d, h = hub_boss_h);
            }

            // Option B: light-sealing skirt below ring
            if (with_skirt) {
                skirt_base_z = with_arm ? -arm_t - skirt_h : -skirt_h;
                difference() {
                    translate([0, 0, skirt_base_z])
                        cylinder(d = housing_od + 2 * (skirt_gap + skirt_t),
                                 h = skirt_h);
                    translate([0, 0, skirt_base_z - 1])
                        cylinder(d = housing_od + 2 * skirt_gap,
                                 h = skirt_h + 2);
                    // Arm notch — only needed when both arm and skirt are present
                    if (with_arm)
                        translate([housing_od / 2 + skirt_gap + skirt_t / 2,
                                   0,
                                   skirt_base_z - 1])
                            cube([skirt_t + 2, arm_hub_d + 4, skirt_h + 2],
                                 center = true);
                }
            }
        }

        // Circular light aperture — from below arm (or ring bottom) up to shelf
        translate([0, 0, with_arm ? -arm_t - 1 : -1])
            cylinder(d = aperture_d, h = shelf_h + (with_arm ? arm_t : 0) + 2);

        // Rounded-corner square slot — shelf to top face
        translate([0, 0, shelf_h])
            rounded_square_slot(s = slot_sq, corner_r = 4,
                                h = diffuser_h - shelf_h + 1);

        // Flange bolt holes
        translate([0, 0, diffuser_h - 4])
            flanges(h = 4, screw = true);

        // D-shaft hole through hub — bores along Y axis (matches motor shaft)
        // d_shaft_hole() with rotate([-90,0,0]) bores along +Y from origin.
        // Place at y = -(hub_radius+1), z = 0 (shaft height); h spans full hub.
        if (with_arm)
            translate([shaft_cx, -(arm_hub_d / 2 + 1), 0])
                d_shaft_hole(h = arm_hub_d + 2);

        // M3 set screw — Z-axis (perpendicular to shaft), entering from hub top.
        // D-flat faces −Z; screw from above clamps shaft against hub floor.
        if (with_arm)
            translate([shaft_cx, 0, -1])
                cylinder(d = 3.0, h = shaft_d / 2 + 1.5 + 2);
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
//  Sky-facing cap; cavity opens downward onto the diffuser stack.
//  COB LED strip (8 mm wide) in two parallel channels on the ceiling.
//  The pivot arm lives on the bottom diffuser ring — this part is
//  purely structural/optical.
//
//  Print orientation: solid top on build plate (sky side down).
// ═══════════════════════════════════════════════════════════════

module main_body() {
    solid_top  = 4;
    led_w      = 9;
    led_depth  = 2;
    led_offset = inner_d / 2 * 0.55;   // ~22 mm — two strip positions

    difference() {
        union() {
            cylinder(d = housing_od, h = body_h);
            flanges(h = 4);
        }

        // Cavity — opens at bottom (z=0), ceiling at body_h - solid_top
        translate([0, 0, -1])
            cylinder(d = inner_d, h = body_h - solid_top + 1);

        // LED strip channels on ceiling
        for (y = [-led_offset, led_offset])
            translate([0, y, body_h - solid_top - led_depth])
                cube([inner_d - 2, led_w, led_depth + 1], center = true);

        // Wire exit notch in side wall for LED USB cable
        translate([0, -(housing_od / 2), body_h / 3])
            cube([7, 5, 6], center = true);

        // Bottom flange bolt holes
        flanges(h = 4, screw = true);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 6 — FOAM GASKET CUTTING TEMPLATE  (Option A light seal)
//  Export this module, print flat, and use as a tracing guide
//  on a sheet of 2–3 mm black EVA foam.  Cut with scissors.
//
//  Gasket dimensions:  ID = adapter_id (63.4 mm)
//                      OD = adapter_od  (73.4 mm)
// ═══════════════════════════════════════════════════════════════

module gasket_template() {
    t = 0.8;   // thin print — just a flat tracing guide
    difference() {
        cylinder(d = adapter_od + 2, h = t);
        translate([0, 0, -1])
            cylinder(d = adapter_id - 2, h = t + 2);
    }
    // Tick marks at N/S/E/W for alignment
    for (a = [0, 90, 180, 270])
        rotate([0, 0, a])
            translate([adapter_od / 2 + 1, 0, 0])
                cube([3, 0.8, t], center = true);
}

// ═══════════════════════════════════════════════════════════════
//  PART 5 — MOTOR COVER
//
//  Back plate that seals the open +Y face of the motor housing.
//  Motor slides in from +Y; this cover is screwed on with 2× M2 screws
//  (holes in housing at shaft_cx ± 0, hz_min+4 and hz_max-4).
//  Wire exit notch at bottom centre aligns with housing slot.
//  Print flat on bed (XY plane).
// ═══════════════════════════════════════════════════════════════

module motor_cover() {
    ear_x1 = shaft_cx - ear_spacing / 2;
    ear_x2 = shaft_cx + ear_spacing / 2;
    hx_min = ear_x1 - bracket_wall;
    hx_max = ear_x2 + bracket_wall;
    hz_min = stepper_z - stepper_d / 2 - bracket_wall;
    hz_max = stepper_z + stepper_d / 2 + bracket_wall;
    w = hx_max - hx_min;      // 41 mm — X width of housing
    h = hz_max - hz_min;      // 34.2 mm — Z height of housing
    t = 2.5;                  // cover plate thickness

    difference() {
        cube([w, t, h]);

        // 2× M2 screw holes — matching positions in adapter_ring back edge
        for (zz = [4, h - 4])
            translate([w / 2, -1, zz])
                rotate([-90, 0, 0])
                    cylinder(d = uln_mount_d, h = t + 2);

        // Wire exit notch at bottom centre — aligns with housing cable slot
        translate([w / 2 - 4, -1, 0])
            cube([8, t + 2, 6]);
    }
}

// ═══════════════════════════════════════════════════════════════
//  PART 7 — DRIVER ENCLOSURE  (ULN2003 board tray)
//
//  Separate parametric box for the ULN2003 stepper driver breakout.
//  Update uln_pcb_w / uln_pcb_l / uln_comp_h once you have the real board.
//
//  Assembly: PCB drops in, lid snaps/screws down.
//  Mount to bench or zip-tie to cable bundle — not attached to panel.
//
//  Estimated dimensions (standard blue ULN2003 board):
//    PCB  : 28 × 32 mm   (uln_pcb_w × uln_pcb_l)
//    Comps: 12 mm tall    (uln_comp_h)
//    Holes: 4× M2 at corners, ~24×28 mm spacing
// ═══════════════════════════════════════════════════════════════

module driver_enclosure() {
    cav_w  = uln_pcb_w + 1.0;                     // cavity X (pcb + 0.5 mm each side)
    cav_l  = uln_pcb_l + 1.0;                     // cavity Y
    cav_h  = uln_pcb_t + 2.0 + uln_comp_h;        // floor gap + pcb + components
    ow     = cav_w + 2 * uln_wall;                // outer X = 33 mm
    ol     = cav_l + 2 * uln_wall;                // outer Y = 37 mm
    oh     = cav_h + uln_wall;                    // outer Z (floor wall + cavity)
    so_h   = 2.0;                                  // PCB standoff height above floor
    so_inset = 2.0;                                // standoff inset from PCB corner

    difference() {
        cube([ow, ol, oh]);

        // Main cavity — open top
        translate([uln_wall, uln_wall, uln_wall])
            cube([cav_w, cav_l, cav_h + 1]);

        // Motor cable slot — −Y wall, centred, above standoff + PCB height
        translate([ow / 2 - 5, -1, uln_wall + so_h + uln_pcb_t])
            cube([10, uln_wall + 2, 8]);

        // Arduino jumper slot — +Y wall, centred
        translate([ow / 2 - 5, ol - uln_wall - 1, uln_wall + so_h + uln_pcb_t])
            cube([10, uln_wall + 2, 8]);
    }

    // 4× PCB standoffs at corners
    for (sx = [uln_wall + so_inset, uln_wall + cav_w - so_inset],
             sy = [uln_wall + so_inset, uln_wall + cav_l - so_inset])
        translate([sx, sy, uln_wall])
            difference() {
                cylinder(d = uln_mount_d + 2.5, h = so_h);
                translate([0, 0, -1])
                    cylinder(d = uln_mount_d, h = so_h + 2);
            }
}

// ═══════════════════════════════════════════════════════════════
//  PART 8 — DRIVER LID
//
//  Snap-fit lid for driver_enclosure().  Snap lip fits inside the
//  enclosure walls (0.2 mm radial clearance per side).
//  3× ventilation slots for the ULN2003 DIP chip.
//  Print flat on bed (XY plane).
// ═══════════════════════════════════════════════════════════════

module driver_lid() {
    cav_w  = uln_pcb_w + 1.0;
    cav_l  = uln_pcb_l + 1.0;
    ow     = cav_w + 2 * uln_wall;
    ol     = cav_l + 2 * uln_wall;
    t      = 1.5;     // lid plate thickness
    lip_h  = 2.0;     // snap lip height (drops inside enclosure walls)
    lip_t  = 0.8;     // snap lip wall thickness
    gap    = 0.2;     // clearance between lip and enclosure inner wall

    difference() {
        union() {
            // Lid plate
            cube([ow, ol, t]);
            // Snap lip (outside lip fits inside enclosure cavity)
            translate([uln_wall + gap, uln_wall + gap, -lip_h])
                difference() {
                    cube([cav_w - 2 * gap, cav_l - 2 * gap, lip_h]);
                    translate([lip_t, lip_t, -1])
                        cube([cav_w - 2 * gap - 2 * lip_t,
                              cav_l - 2 * gap - 2 * lip_t,
                              lip_h + 2]);
                }
        }
        // 3× ventilation slots across width, centred on lid
        for (i = [-1, 0, 1])
            translate([ow / 2 + i * 8 - 2, ol * 0.25, -1])
                cube([4, ol * 0.5, t + 2]);
    }
}

// ═══════════════════════════════════════════════════════════════
//  ASSEMBLY PREVIEW
//
//  OPEN_ANGLE : 0 = closed (panel over aperture)
//               270 = fully open (panel parked behind adapter)
//
//  Rotation axis: Y axis passing through (shaft_cx, 0, stepper_z).
//  The panel swings in the XZ plane — from "flat over aperture" to
//  "standing behind the adapter" at 270°.
//
//  Set $t in OpenSCAD animation to sweep 0→270° continuously:
//    OPEN_ANGLE = $t * 270;
// ═══════════════════════════════════════════════════════════════

//OPEN_ANGLE = 0;   // 0 = closed · 270 = fully open
OPEN_ANGLE = $t * 270;

module assembly() {
    z_diff1 = adapter_h;
    z_gap   = z_diff1 + diffuser_h;
    z_diff2 = z_gap   + air_gap_h;
    z_body  = z_diff2 + diffuser_h;

    // ── Fixed adapter ring (stays on telescope) ───────────────
    color("red", 0.90)
        adapter_ring();

    // ── Motor cover (back plate of motor housing) ─────────────
    ear_x1_a = shaft_cx - ear_spacing / 2;
    hx_min_a = ear_x1_a - bracket_wall;
    hy_max_a = arm_clear + bracket_wall + stepper_len + bracket_wall;
    hz_min_a = stepper_z - stepper_d / 2 - bracket_wall;
    color("tomato", 0.70)
        translate([hx_min_a, hy_max_a, hz_min_a])
            motor_cover();

    // ── Ghost stepper motor body + ear tabs (orange, semi-transparent) ──
    color("orange", 0.35) {
        translate([shaft_cx, 0, stepper_z])
            rotate([90, 0, 0])
                cylinder(d = stepper_d, h = stepper_len);
        // Ear tabs at x = shaft_cx ± ear_spacing/2, at front face (y = 0)
        for (ex = [shaft_cx - ear_spacing / 2, shaft_cx + ear_spacing / 2])
            translate([ex, 0, stepper_z])
                rotate([90, 0, 0])
                    cylinder(d = ear_hole_d + 3, h = 1.0);
    }

    // ── Phantom rotation axis (cyan line along Y) ─────────────
    axis_len = housing_od + 60;
    color("cyan", 0.80)
        translate([shaft_cx, -axis_len / 2, stepper_z])
            rotate([-90, 0, 0])
                cylinder(d = 1.2, h = axis_len);
    color("cyan", 0.80)
        translate([shaft_cx, axis_len / 2, stepper_z])
            rotate([-90, 0, 0])
                cylinder(d1 = 4, d2 = 0, h = 6);

    // ── Rotating panel stack ──────────────────────────────────
    translate([shaft_cx, 0, stepper_z])
        rotate([0, OPEN_ANGLE, 0])
            translate([-shaft_cx, 0, -stepper_z]) {
                color("white",   0.85)
                    translate([0, 0, z_diff1])
                        diffuser_ring(with_arm = true, with_skirt = ENABLE_SKIRT);
                color("dimgray", 0.50)
                    translate([0, 0, z_gap])
                        air_gap_ring();
                color("white",   0.85)
                    translate([0, 0, z_diff2])
                        diffuser_ring();
                color("blue",   0.80)
                    translate([0, 0, z_body])
                        main_body();
            }
}

// ═══════════════════════════════════════════════════════════════
//  PRINT LAYOUT
//  Uncomment ONE part → File → Export → STL
// ═══════════════════════════════════════════════════════════════

assembly();   // ← comment out when exporting a part

// adapter_ring();                                          // ×1  black
// motor_cover();                                           // ×1  black
// diffuser_ring(with_arm=true, with_skirt=ENABLE_SKIRT);  // ×1  white  (bottom)
// diffuser_ring();                                         // ×1  white  (top)
// air_gap_ring();                                          // ×1  black
// main_body();                                             // ×1  black
// driver_enclosure();                                      // ×1  black
// driver_lid();                                            // ×1  black
// gasket_template();   // trace onto EVA foam, cut with scissors
