/* ============================================================
   RedCat 51 DIY Flat Panel — Parametric OpenSCAD Model
   ============================================================ */

// ================= PARAMETERS =================

dew_shield_od = 84.0;
fit_gap       = 0.4;

adapter_id    = dew_shield_od + fit_gap;
wall          = 5.0;
housing_od    = adapter_id + 2 * wall;
cover_od      = housing_od + 4;

// Heights
adapter_h  = 22;
body_h     = 18;
diffuser_h = 6;
air_gap_h  = 8;
cover_t    = 3;

// Acrylic
acrylic_d  = 80.0;
acrylic_t  = 3.4;
slot_d     = acrylic_d + 0.4;
shelf_h    = 2.0;
aperture_d = acrylic_d - 4;

// Hardware
m3_clear = 3.4;
bolt_r   = housing_od/2 - 4;

$fn = 128;

// ================= HELPERS =================

module bolt_pattern(h=20) {
    for (a = [0,120,240]) {
        rotate([0,0,a])
            translate([bolt_r,0,0])
                cylinder(d=m3_clear, h=h);
    }
}

module ring(od, id, h) {
    difference() {
        cylinder(d=od, h=h);
        translate([0,0,-1]) cylinder(d=id, h=h+2);
    }
}

// ================= PARTS =================

// --- Adapter ring ---
module adapter_ring() {
    difference() {
        ring(housing_od, adapter_id, adapter_h);
        bolt_pattern(adapter_h);
    }
}

// --- Diffuser ring ---
module diffuser_ring() {
    difference() {
        union() {
            ring(housing_od, slot_d, diffuser_h);

            // inner shelf
            ring(slot_d, aperture_d, shelf_h);
        }

        bolt_pattern(diffuser_h);
    }
}

// --- Air gap spacer ---
module air_gap_ring() {
    difference() {
        ring(housing_od, slot_d, air_gap_h);
        bolt_pattern(air_gap_h);
    }
}

// --- Main body (LED tray) ---
module main_body() {
    difference() {
        cylinder(d=housing_od, h=body_h);

        // Hollow cavity (opens downward)
        translate([0,0,2])
            cylinder(d=slot_d, h=body_h);

        bolt_pattern(body_h);

        // Wire exit
        translate([housing_od/2 - 5, 0, body_h/2])
            rotate([0,90,0])
                cylinder(d=6, h=10);
    }
}

// --- Stepper mounting plate ---
module stepper_plate() {
    difference() {
        cylinder(d=50, h=4);

        cylinder(d=5, h=10);

        for (a=[0,90,180,270])
            rotate([0,0,a])
                translate([17,0,0])
                    cylinder(d=3, h=10);
    }
}

// --- Hinge knuckle ---
module hinge_knuckle(r=3, w=6) {
    rotate([90,0,0])
        cylinder(d=r*2, h=w);
}

// --- Cover ---
module cover() {
    union() {
        cylinder(d=cover_od, h=cover_t);

        for (x=[-8,8]) {
            translate([x, cover_od/2 - 2, cover_t/2])
                hinge_knuckle();
        }
    }
}

// ================= ASSEMBLY =================

module assembly() {

    translate([0,0,0])
        adapter_ring();

    translate([0,0,adapter_h])
        diffuser_ring();

    translate([0,0,adapter_h + diffuser_h])
        air_gap_ring();

    translate([0,0,adapter_h + diffuser_h + air_gap_h])
        diffuser_ring();

    translate([0,0,adapter_h + diffuser_h + air_gap_h + diffuser_h])
        main_body();

    // Cover parked open
    translate([0,
               -cover_od/2,
               adapter_h + diffuser_h + air_gap_h + diffuser_h + body_h])
        rotate([0,0,90])
            cover();
}

// Preview full assembly
assembly();

// Uncomment to export individual parts:
//adapter_ring();
//diffuser_ring();
//air_gap_ring();
//main_body();
//stepper_plate();
//cover();