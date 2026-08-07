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

$fn = 128;

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

//linkage_arms();