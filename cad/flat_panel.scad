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
 *   [main_body]          LED tray; bracket post on +X side for linkage arm
 *   ── sky side ──
 *   [driver_enclosure]   ULN2003 tray screwed to main_body top face
 *
 * ── PARTS ────────────────────────────────────────────────────────
 *   adapter_ring()       ×1  black  bore tube + enclosed motor housing; flat top face
 *   motor_cover()        ×1  black  back plate sealing motor housing
 *   diffuser_ring()      ×2  white  both rings identical — no arm variant needed
 *   air_gap_ring()       ×1  black  hollow spacer
 *   main_body()          ×1  black  LED tray + arm bracket post + driver mount bosses
 *   linkage_arm_L()      ×1  black  separate L-arm; hub on D-shaft, slot bolts to body
 *   driver_enclosure()   ×1  black  ULN2003 board tray; bolts to main_body top face
 *   driver_lid()         ×1  black  lid for driver enclosure
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

 include <BOSL2/std.scad>
 include <BOSL2/screws.scad>
 include <BOSL2/shapes3d.scad>
 
 
// ═══════════════════════════════════════════════════════════════
//  GLOBAL TOGGLE
// ═══════════════════════════════════════════════════════════════

ENABLE_SKIRT = false;   // true → Option B skirt; false → Option A foam gasket

// ═══════════════════════════════════════════════════════════════
//  PARAMETERS  — edit before printing
// ═══════════════════════════════════════════════════════════════

// ── Telescope interface ──────────────────────────────────────
dew_shield_od = 84.0;      // Measured OD of RedCat 51 dew shield (mm) 
dew_shield_r = dew_shield_od / 2;
fit_gap       =  0.4;      // Radial clearance for friction fit

// ── Acrylic diffuser — 56×56 mm square ──────────────────────
acrylic_sq  = 56.0;
acrylic_t   =  3.4;        // 3 mm acrylic + 0.4 mm clearance
slot_sq     = acrylic_sq + 0.4;
shelf_h     =  2.0;        // shelf the acrylic rests on
aperture_d  = 68.0;        // circular light aperture below shelf

// ── Part heights ─────────────────────────────────────────────
led_h      = 8;          // LED tray height
air_gap_h   =  10;          // air gap spacer
diffuser_h  =  5;          // each diffuser ring
diffuser_ailette_h = 1;
diffuser_ailette_w = 6;
pad_holder_h = 5;

wall_t = 3;             // Wall thickness
extra_diameter = 10;    // Extra space to add diffuser shelves and avoid border issues
// ── Pivot arm ────────────────────────────────────────────────

arm_pivot_d          = 14;
arm_horiz_len        = 51;
arm_w                = 7;
arm_vert_len         = 55;
arm_vert_offset      = 10;
arm_slot_start       =  5;
arm_slot_len         =  40;
arm_slot_w           =  3.4;
arm_slot_margin      =  3;
arm_holder_length    = 25;
arm_holder_thickness = 10;
arm_cylinder_d       = 10;

arms_spacing = 10;         // space between both arms

// ── LED holder ────────────────────────────────────────────────

cable_hole_r = 2.5;

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

// ── ULN2003 driver board  ─────────────────────────────────────
// *** Update these once you have the physical board ***
uln_pcb_w     = 100.0;  // PCB width  (long axis, X direction)
uln_pcb_l     = 50.0;  // PCB length (short axis, Y direction into enclosure)
uln_pcb_t     =  1.6;  // PCB thickness
uln_comp_h    = 15.0;  // component height above PCB (tallest element)
uln_wall      =  2.0;  // enclosure wall thickness
uln_side_wall =  10;   // side wall where screw will pass through
uln_mount_d   =  2.4;  // M2 PCB standoff hole diameter

flat_panel_arm_offset = 10;

m3_clear     = 4;   // previous value: 3.4
m3_insert    = m3_clear + 0.2;
m3_head_d    = 6.5;

$fn = 256;

// ═══════════════════════════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════════════════════════

// D-shaft press-fit hole
module d_shaft_hole(h = 6) {
    rotate([-90, 0, 0])
        linear_extrude(h)
        difference() {
            rotate([180, 0, 0]) {
                difference() {
                    circle(d = shaft_d + 0.4);
                    translate([0, shaft_flat + shaft_d / 2])
                        square([shaft_d + 1, shaft_d], center = true);
                }
            }
            translate([0, shaft_flat + shaft_d / 2])
                square([shaft_d + 1, shaft_d], center = true);
        }
}

// Arms
module linkage_arm_L() {

    module arm_bar(p1, p2, w) {
        hull() {
            translate(p1) cylinder(h = arm_w, d = w);
            translate(p2) cylinder(h = arm_w, d = w);
        }
    }
    module arm_slot(p1, p2, w) {
        hull() {
            translate(p1) cylinder(h = arm_w + 2, d = w);
            translate(p2) cylinder(h = arm_w + 2, d = w);
        }
    }

    difference() {
        union() {
            cylinder(h = arm_w, d = arm_pivot_d);
            arm_bar([0, 0], [arm_horiz_len, -arm_vert_offset], arm_w);
            arm_bar(
                [arm_horiz_len, -arm_vert_offset],
                [arm_horiz_len, -arm_vert_offset - arm_vert_len],
                arm_w
            );
        }
       
        // Adjustable slot (M3 bolt to main_body bracket)
        arm_slot(
            [arm_horiz_len, -arm_vert_offset - arm_slot_margin - arm_slot_start, -1],
            [arm_horiz_len, -arm_vert_offset - arm_slot_margin - (arm_slot_start + arm_slot_len), -1],
            arm_slot_w
        );
    }
}

module linkage_arm_N() {

    module arm_bar(p1, p2, w) {
        hull() {
            translate(p1) cylinder(h = arm_w, d = w);
            translate(p2) cylinder(h = arm_w, d = w);
        }
    }
    module arm_slot(p1, p2, w) {
        hull() {
            translate(p1) cylinder(h = arm_w + 2, d = w);
            translate(p2) cylinder(h = arm_w + 2, d = w);
        }
    }

    difference() {
        union() {
            cylinder(h = arm_w, d = arm_pivot_d);
            arm_bar([arm_pivot_d/4, 0], [arm_pivot_d/4, -arm_vert_offset], arm_w);
            arm_bar([-arm_pivot_d/4, 0], [arm_pivot_d/4, -arm_vert_offset], arm_w);
            arm_bar([arm_pivot_d/4, -arm_vert_offset], [arm_horiz_len, -arm_vert_offset], arm_w);
            arm_bar(
                [arm_horiz_len, -arm_vert_offset],
                [arm_horiz_len, -arm_vert_offset - arm_vert_len],
                arm_w
            );
        }
       
        // Adjustable slot (M3 bolt to main_body bracket)
        arm_slot(
            [arm_horiz_len, -arm_vert_offset - arm_slot_margin - arm_slot_start, -1],
            [arm_horiz_len, -arm_vert_offset - arm_slot_margin - (arm_slot_start + arm_slot_len), -1],
            arm_slot_w
        );
    }
}

module linkage_arm_L_shaft() {  
    //difference() {
        difference() {
            linkage_arm_N();
            
            // D-shaft hole — axis along +Z (arm thickness direction)
            translate([0, 0, -3]) {
                rotate([90, 0, 0]) {
                    d_shaft_hole();
                }
            }
        }
        
        // M3 set screw — +Y face, radial to shaft
        //translate([0, arm_pivot_d / 2 + 1, arm_thickness / 2])
        //    rotate([90, 0, 0])
        //        cylinder(d = 3.0, h = arm_pivot_d / 2 + 2);
                
    //}
}

module linkage_arms() {  
    union() {
        translate([0, 0, -(arm_w + (arms_spacing/2))])
            linkage_arm_L_shaft();
    
        translate([0, 0, -arms_spacing/2])
            cylinder(h=arms_spacing, r=arm_cylinder_d/2);
    
        translate([0, 0, arms_spacing/2])
            linkage_arm_N();
    }
}

// LED body
module led_body_holder() {
    difference() {
        difference() {
            cube([arm_holder_thickness, arm_holder_length, arms_spacing], center = true);
        
            translate([(arm_holder_thickness-arm_w)/2,(arm_holder_length-arm_slot_w)/2 - 3,0]) cylinder(h = 15, d = arm_slot_w, center = true);
        }
        translate([(arm_holder_thickness-arm_w)/2,-(arm_holder_length-arm_slot_w)/2 + 3,0]) cylinder(h = 15, d = arm_slot_w, center = true);
    }
}

module screw_hole(height, diameter, hollow_d) {
    difference() {
        cylinder(h=height, r=diameter, center = true);
        cylinder(h=height, r=diameter-hollow_d, center = true);
    }
 }

// 3× M3 bolt flanges at 120° spacing
module flanges(h, screw = false, insert=false) {
    for (a = [0, 120, 240])
        rotate([0, 0, a])
            translate([0, dew_shield_r + extra_diameter - wall_t + 1, 0])
                if (screw)
                    if (insert)
                        cylinder(d = m3_insert,         h = h + 2, center = true);
                    else
                        cylinder(d = m3_clear,         h = h + 2, center = true);
                else
                    cylinder(d = m3_head_d * 1.4,  h = h, center = true); 
 }

module ghost_dew_shield() {
    color("orange", 0.5)
        translate([0, 0, wall_t])
            cylinder(h=10, r=dew_shield_r, center = true);
} 
 
module led_body() {
    union() {
        difference() {
            union() {
                difference() {
                difference() {
                        translate([0, 0, (led_h + wall_t)/2])
                            cylinder(h=led_h + wall_t, r=dew_shield_r + extra_diameter + wall_t, center = true);
                        
                        translate([0, 0, led_h/2 + wall_t])
                            cylinder(h=led_h + 1, r=dew_shield_r + extra_diameter, center = true);
                    }
                    translate([-(dew_shield_r + extra_diameter + wall_t), 0, led_h + 2.5])
                        rotate([0, 90, 0])
                            cylinder(h=15, r=cable_hole_r, center = true);
                }
                
                
                translate([0, 0, (led_h + wall_t)/2])
                    flanges(h = led_h + wall_t);
                
            }
            translate([0, 0, (led_h + wall_t)/2 + 2])
                    flanges(h = led_h + wall_t, screw = true, insert = true);
        }
        
        translate([0, dew_shield_r - 10, -arm_holder_thickness/2])
            rotate([0, 90, 0])
                //led_body_holder();
        translate([0, 0, -(uln_pcb_t + uln_comp_h)/2 - wall_t]) {
            //led_circuit_box_top();
            //led_circuit_box_bottom();
        }
     }
}

module led_circuit_box_whole() {
    difference() {
        minkowski() {
            difference() {
                cube([uln_pcb_w, uln_pcb_l + uln_side_wall, uln_pcb_t + uln_comp_h], center = true);
                cube([uln_pcb_w - uln_wall, uln_pcb_l - uln_wall, uln_pcb_t + uln_comp_h - uln_wall], center = true);
            }
            sphere(r=5);
        }
        translate([uln_wall+15, uln_pcb_l/2 + 2, 0])
            rotate([0, 90, 0])
                cylinder(h=80, r=4, center = true);
        translate([uln_wall+15, -uln_pcb_l/2 - 2, 0])
            rotate([0, 90, 0])
                cylinder(h=80, r=4, center = true);
    }    
}

module cutting_cube() {
    translate([uln_pcb_w/2 - 10, 0, 0])
    cube([uln_pcb_w + 20, uln_pcb_l + 20, uln_pcb_t + uln_comp_h + 20], anchor=RIGHT);
}

module led_circuit_box_top() {
    intersection(){
        led_circuit_box_whole();
        cutting_cube();
    }
}

module led_circuit_box_bottom() {
    difference(){
        led_circuit_box_whole();
        cutting_cube();
    }
}

module gap(h, flange_h){
    difference() {
        union() {
            difference() {
                cylinder(h=h, r=dew_shield_r + extra_diameter + wall_t, center = true);     
                cylinder(h=h + 2, r=dew_shield_r + extra_diameter, center = true);
            }
            translate([0, 0, (h - flange_h)/2])
            flanges(h = flange_h);
        }
        translate([0, 0, (h - flange_h)/2])
        flanges(h = flange_h, screw = true);
    }
}

module diffuser(h, flange_h) {
    difference() {
        union() {
            difference() {
                difference() {
                    cylinder(h=h, r=dew_shield_r + extra_diameter + wall_t, center = true);     
                    translate([0, 0, diffuser_ailette_h])
                    cylinder(h=h, r=dew_shield_r + extra_diameter, center = true);
                }
                cylinder(h=h + 2, r=dew_shield_r + extra_diameter - diffuser_ailette_w, center = true);
            }
            translate([0, 0, (h - flange_h)/2])
            flanges(h = flange_h);
        }
        translate([0, 0, (h - flange_h)/2])
        flanges(h = flange_h + 10, screw = true);
    }
}

module pad_holder(h) {
    difference() {
        union() {
            difference() {
                //difference() {
                    cylinder(h=h, r=dew_shield_r + extra_diameter + wall_t, center = true);
                    //translate([0, 0, h])
                    //cylinder(h=h, r=dew_shield_r + extra_diameter, center = true);
                //}
                cylinder(h=h + 2, r=dew_shield_r + 2, center = true);
            }
            flanges(h=h);
        }
        translate([0, 0, 0])
        flanges(h=h, screw = true);
    }
}

module assembly(){

// Arms
linkage_arms();

// LED body
translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
    rotate([0, -90, 0])
        translate([0, -(dew_shield_r - 10), arm_holder_thickness/2])
            led_body();
            
// Diffuser 1
translate([-led_h - diffuser_h, 0, 0])
    translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
        rotate([0, 90, 0])
            translate([0, -(dew_shield_r - 10), -arm_holder_thickness/2])
                diffuser(5, 3);            
            
// Gap
translate([-led_h - diffuser_h - (air_gap_h/2), 0, 0])
    translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
        rotate([0, -90, 0])
            translate([0, -(dew_shield_r - 10), arm_holder_thickness/2])
                gap(air_gap_h, air_gap_h);
                
// Diffuser 2
translate([-led_h - diffuser_h * 2 - (air_gap_h/2), 0, 0])
    translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
        rotate([0, 90, 0])
            translate([0, -(dew_shield_r - 10), -arm_holder_thickness/2])
                diffuser(5, 3);

// Pad holder
translate([-led_h - diffuser_h * 2 - (air_gap_h/2) - pad_holder_h, 0, 0])
    translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
        rotate([0, 90, 0])
            translate([0, -(dew_shield_r - 10), -arm_holder_thickness/2])
                pad_holder(pad_holder_h);    
            
}


module gabarit_diffuser(){
 difference(){
    cylinder(h=2, r=dew_shield_r + extra_diameter - 1);
    diffuser(5, 3);
    translate([0, 0, (h - flange_h)/2])
    flanges(h = 6);
    }
}
//linkage_arms();
//linkage_arm_N();

//translate([arm_horiz_len - (arm_holder_thickness/2 - arm_w), -arm_vert_offset - arm_slot_margin - (arm_slot_start + arm_slot_len/2)])

//translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2), 0])
//    led_body_holder();

//translate([arm_horiz_len - (arm_holder_thickness/2 - arm_w), -arm_vert_offset - arm_slot_margin - (arm_slot_start + arm_slot_len/2)])
//rotate([0, -90, 0])
//translate([0, -(dew_shield_r - 10), -(-arm_holder_thickness/2 + wall_t)])
//led_body();
//translate([arm_horiz_len - (arm_holder_thickness/2 - arm_w), -arm_vert_offset - arm_slot_margin - (arm_slot_start + arm_slot_len/2)])

    //led_body();
//led_body();
//led_circuit_box_whole();
//led_circuit_box_top();
//led_circuit_box_bottom();

//gap(air_gap_h, air_gap_h);

diffuser(5, 2);

//pad_holder(pad_holder_h);

OPEN_ANGLE = $t * 270;

//rotate([0, 0, OPEN_ANGLE])
//    assembly();

/*
translate([-led_h - diffuser_h * 2 - (air_gap_h/2) - pad_holder_h - 10, 0, 0])
    translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2), 0])
        rotate([0, 90, 0])
            translate([0, -(dew_shield_r - 10), -arm_holder_thickness/2])
                ghost_dew_shield();
*/

// Test screw hole
/*
difference(){
cylinder(d = m3_head_d * 1.4,  h = 5, center = true); 
cylinder(d = m3_clear,         h = 5 + 2, center = true);
}
*/

//gabarit_diffuser();

