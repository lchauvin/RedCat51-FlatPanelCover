/*
 * L-Shaped Slotted Linkage Arm
 * RedCat 51 Flat Panel — separate printed arm that pivots on the
 * 28BYJ-48 D-shaft and bolts to the main_body bracket.
 *
 * Print flat (arm lies in XY plane, thickness in Z = shaft axis direction).
 * Mount on D-shaft at hub; tighten M3 set screw through +Y face.
 * Bolt vertical segment to main_body bracket through slot.
 *
 * Fully parametric · Units: mm
 */

///////////////////////
// PARAMETERS
///////////////////////

// Arm face thickness (= shaft axis direction when mounted)
thickness           =  5;

// Pivot hub
pivot_diameter      = 14;    // matches arm_hub_d in flat_panel_v2.scad
pivot_hole_diameter =  5.4;  // D-shaft clearance (shaft_d 5.0 + 0.4)

// D-shaft geometry (for D-flat cutout in hub)
shaft_d    = 5.0;
shaft_flat = 1.6;   // distance from shaft centre to flat face

// Horizontal arm (hub → elbow); diagonal in XY plane
horizontal_length   = 11;   // X offset to elbow  (≈ shaft_cx − x_break = 66.1 − 55)
arm_width           = 10;   // bar diameter

// Vertical arm (elbow → arm tip carrying bolt slot)
vertical_length     = 10;   // length of vertical segment
vertical_offset     = 10;   // Y offset at elbow (was hardcoded −10)

// Slot in vertical arm (M3 bolt to main_body bracket, Y-adjustable)
slot_length         =  8;   // adjustment range
slot_width          =  3.4; // M3 clearance diameter
slot_margin_bottom  =  3;   // gap from elbow to slot start

// Fillet resolution
$fn = 80;

///////////////////////
// HELPER MODULES
///////////////////////

module rounded_bar(p1, p2, width) {
    hull() {
        translate(p1) cylinder(h = thickness, d = width);
        translate(p2) cylinder(h = thickness, d = width);
    }
}

// Slot: hull of two cylinders, through full thickness + overcut
module slot_cut(p1, p2, width) {
    hull() {
        translate(p1) cylinder(h = thickness + 1, d = width);
        translate(p2) cylinder(h = thickness + 1, d = width);
    }
}

///////////////////////
// MAIN MODULE
///////////////////////

module linkage_arm_L() {
    difference() {

        union() {
            // Pivot hub disc
            cylinder(h = thickness, d = pivot_diameter);

            // Horizontal (diagonal) arm: hub → elbow
            rounded_bar([0, 0], [horizontal_length, -vertical_offset], arm_width);

            // Vertical arm: elbow → arm tip
            rounded_bar(
                [horizontal_length, -vertical_offset],
                [horizontal_length, -vertical_offset - vertical_length],
                arm_width
            );
        }

        // ── D-shaft hole through hub — axis along +Z (arm thickness direction)
        //    D-flat faces +Y so set screw can clamp from the +Y face.
        translate([0, 0, -0.5])
            linear_extrude(thickness + 1)
                difference() {
                    circle(d = pivot_hole_diameter);
                    // Remove the flat: cut material at +Y side of shaft circle
                    translate([0, shaft_flat + shaft_d / 2])
                        square([shaft_d + 1, shaft_d], center = true);
                }

        // ── M3 set screw — enters from +Y face of hub, points toward shaft axis
        translate([0, pivot_diameter / 2 + 1, thickness / 2])
            rotate([90, 0, 0])
                cylinder(d = 3.0, h = pivot_diameter / 2 + 2);

        // ── Adjustable slot in vertical arm (M3 bolt to main_body bracket)
        slot_cut(
            [horizontal_length, -vertical_offset - slot_margin_bottom],
            [horizontal_length, -vertical_offset - slot_margin_bottom - slot_length],
            slot_width
        );
    }
}

///////////////////////
// RENDER
///////////////////////

linkage_arm_L();
