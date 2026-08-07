/* [Arms] */

arm_pivot_d          = 14;
arm_horiz_len        = 51;
arm_w                = 7;
arm_vert_len         = 75;
arm_vert_offset      = 10;
arm_slot_start       =  25;
arm_slot_len         =  40;
arm_slot_w           =  3.4;
arm_slot_margin      =  3;
arm_holder_length    = 25;
arm_holder_thickness = 10;
arm_cylinder_d       = 10;

arms_spacing = 10;         // space between both arms

// ── 28BYJ-48 stepper motor ───────────────────────────────────
stepper_d   = 28.2;        // body diameter
stepper_len = 19.5;        // body length (shaft end to back)
shaft_d     =  5.0;        // D-shaft diameter
shaft_flat  =  1.6;        // flat cut offset from shaft centre

m3_clear     = 4;   // previous value: 3.4
m3_insert    = m3_clear + 0.2;
m3_head_d    = 6.5;


$fn = 128;

// Arms


// D-shaft press-fit hole
module d_shaft_hole(h = 10) {
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
        difference() {
            translate([0, 0, -(arm_w + (arms_spacing/2))])
                linkage_arm_L_shaft();
    
            // Securing screw hole
            rotate([90,0,0])
                translate([0,-(arms_spacing + arm_w)/2,-5])
                    cylinder(d = m3_insert, h = 7, center = true);   
        }
    
        translate([0, 0, -arms_spacing/2])
            cylinder(h=arms_spacing, r=arm_cylinder_d/2);
    

        translate([0, 0, arms_spacing/2])
            linkage_arm_N();
    }
}

//linkage_arms();