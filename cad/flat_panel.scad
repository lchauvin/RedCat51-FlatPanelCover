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
 
 include <arms.scad>
 
// ═══════════════════════════════════════════════════════════════
//  GLOBAL TOGGLE
// ═══════════════════════════════════════════════════════════════

show_base = true;
show_diffusers = true;
show_diffuser_gabarit = false;
show_circuit_box = false;
show_spacers = false;
show_pad_holder = false;
show_arms = true;
show_mega_case = false;     // preview the Arduino Mega case behind led_body
show_mega_lid  = false;     // preview its lid too
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

// ── LED holder ────────────────────────────────────────────────

cable_hole_r = 3.0;

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

// ── Arduino Mega 2560 case (screwed to the back of led_body) ──
// Board data from the Adafruit "Arduino Dimensions and Hole Patterns"
// 1:1 drawing: 101.6 × 53.3 mm PCB, six Ø3.2 holes (fit M3), origin at
// the corner next to the USB port, y measured from the jack-side edge.
mega_case_mount = false;    // adds 4 countersunk holes + wire hole to led_body
mega_pcb_l   = 101.6;
mega_pcb_w   = 53.3;
mega_pcb_t   = 1.6;
mega_holes   = [[13.97,  2.54], [96.52,  2.54], [66.04,  7.62],
                [66.04, 35.56], [15.24, 50.80], [90.17, 50.80]];

mcase_wall     = 2.5;     // shell wall
mcase_floor_t  = 3.0;     // floor plate (mates against led_body back)
mcase_lid_t    = 2.5;     // lid plate
mcase_rc       = 8.5;     // exterior corner radius — the lid screws live here
mega_gap_usb   = 2.5;     // PCB connector edge ↔ wall (USB-B lands ~flush outside)
mega_gap       = 2.0;     // PCB clearance, other three sides

// Vertical stack, mate face → lid.  Case depth is derived from these.
// Slim it down if you skip Dupont jumpers (solder / low-profile wiring):
// mega_air 8 and uln_comp_drop 10 save ~14 mm of depth.
mega_standoff_h = 9;      // Mega standoffs (solder tails must clear the bosses)
mega_air        = 16;     // headers + Dupont jumpers above the Mega PCB
uln_comp_drop   = 16;     // ULN2003 parts + plugs hanging toward the Mega
uln_deck_pcb_t  = 1.6;
uln_post_h      = 6;      // ULN2003 posts on the lid

// ULN2003 deck — MEASURE YOUR BOARD, clones differ (28×28 … 45×32 mm)
uln_hole_dx  = 29.0;      // hole spacing along the Mega's long axis
uln_hole_dy  = 26.5;      // hole spacing across
uln_pilot    = 2.7;       // M3 self-tap pilot in the lid posts

// Placement on the back face (led_body frame): the case is shifted −Y so
// its hinge-side wall stays clear of the arm holder + arm bars (y ≥ 19.5).
// Long axis along X, USB/jack windows on the −X wall (cable-hole side).
mega_y_top   = 14.0;      // PCB's +Y edge (jack-side edge, toward the hinge)
mcase_attach_pts = [[44, 2], [-44, 2], [30, -33], [-30, -33]];
mcase_attach_d   = 3.4;   // M3 countersunk clearance through the back wall
mcase_wire_xy    = [-45, -8];   // LED-lead hole through back wall + floor
mcase_wire_d     = 6.0;

// derived — don't edit
mega_x0   = -mega_pcb_l/2;                       // USB-corner x
mci_x0 = mega_x0 - mega_gap_usb;  mci_x1 = mega_x0 + mega_pcb_l + mega_gap;
mci_y0 = mega_y_top - mega_pcb_w - mega_gap;  mci_y1 = mega_y_top + mega_gap;
mce_x0 = mci_x0 - mcase_wall;  mce_x1 = mci_x1 + mcase_wall;
mce_y0 = mci_y0 - mcase_wall;  mce_y1 = mci_y1 + mcase_wall;
mega_hole_xy = [for (h = mega_holes) [mega_x0 + h[0], mega_y_top - h[1]]];
mcase_int_d  = mega_standoff_h + mega_pcb_t + mega_air
             + uln_comp_drop + uln_deck_pcb_t + uln_post_h;
mcase_body_d = mcase_floor_t + mcase_int_d;      // mate face → lid seat
mcase_ext_d  = mcase_body_d + mcase_lid_t;
mcase_lid_pts = [[mce_x0 + mcase_rc, mce_y0 + mcase_rc],
                 [mce_x1 - mcase_rc, mce_y0 + mcase_rc],
                 [mce_x0 + mcase_rc, mce_y1 - mcase_rc],
                 [mce_x1 - mcase_rc, mce_y1 - mcase_rc]];

$fn = 256;

// ═══════════════════════════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════════════════════════

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

            // Mega-case mounting: 4× M3 flat-head countersunk from the tray
            // side into inserts in the case floor, + LED-lead pass-through
            if (mega_case_mount) {
                for (p = mcase_attach_pts) {
                    translate([p[0], p[1], -1])
                        cylinder(h = wall_t + 2, d = mcase_attach_d);
                    // 90° countersink, head flush with the tray floor
                    translate([p[0], p[1], wall_t - 1.8])
                        cylinder(h = 1.81, d1 = mcase_attach_d, d2 = 7.0);
                }
                translate([mcase_wire_xy[0], mcase_wire_xy[1], -1])
                    cylinder(h = wall_t + 2, d = mcase_wire_d);
            }
        }
        
        translate([0, dew_shield_r - 10, -arm_holder_thickness/2])
            rotate([0, 90, 0])
                led_body_holder();
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

// ═══════════════════════════════════════════════════════════════
//  ARDUINO MEGA 2560 + ULN2003 CASE — bolts to the back of led_body
//
//  Modeled in led_body's frame: mate face on the back plane (z = 0),
//  case extends −Z.  Long axis along X, shifted −Y so the hinge-side
//  wall clears the arm holder and arm bars (y ≥ 19.5).  USB-B and
//  barrel-jack windows on the −X wall (same side as the LED cable
//  hole); windows are generous because port positions vary between
//  Mega clones.  ULN2003 rides on parametric posts on the lid,
//  component-side toward the Mega.
//
//  Hardware: 10× M3 heat-set inserts (6 standoffs + 4 floor bosses),
//  6× M3×8 (Mega), 4× M3×8 flat-head countersunk (tray → case),
//  4× M3×12 self-tap (lid), 4× M3×8 self-tap (ULN2003).
// ═══════════════════════════════════════════════════════════════

// box with rounded vertical edges (same idiom as motor_mount.scad)
module mc_rbox(x0, x1, y0, y1, za, zb, r = 3) {
    hull()
        for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r])
            translate([x, y, za])
                cylinder(h = zb - za, r = r);
}

module mega_case_in_place() {
    z_win = -(mcase_floor_t + mega_standoff_h + mega_pcb_t - 0.5);
    difference() {
        union() {
            // shell: floor + walls
            difference() {
                mc_rbox(mce_x0, mce_x1, mce_y0, mce_y1,
                        -mcase_body_d, 0, mcase_rc);
                mc_rbox(mci_x0, mci_x1, mci_y0, mci_y1,
                        -mcase_body_d - 1, -mcase_floor_t, 2.5);
            }
            // 6× Mega standoffs
            for (p = mega_hole_xy)
                translate([p[0], p[1], -(mcase_floor_t + mega_standoff_h)])
                    cylinder(h = mega_standoff_h, d = 8);
            // 4× attachment bosses under the floor (screws arrive from
            // the LED tray; kept short so Mega solder tails clear them)
            for (p = mcase_attach_pts)
                translate([p[0], p[1], -(mcase_floor_t + 5.5)])
                    cylinder(h = 5.5, d = 9);
        }

        // standoff insert holes (M3 heat-set)
        for (p = mega_hole_xy)
            translate([p[0], p[1], -(mcase_floor_t + mega_standoff_h)])
                cylinder(h = 5.5, d = m3_insert);

        // attachment insert holes, entered from the mate face
        for (p = mcase_attach_pts)
            translate([p[0], p[1], -6.5])
                cylinder(h = 6.7, d = m3_insert);

        // LED-lead hole through the floor (lines up with led_body's)
        translate([mcase_wire_xy[0], mcase_wire_xy[1], -mcase_floor_t - 1])
            cylinder(h = mcase_floor_t + 2, d = mcase_wire_d);

        // barrel-jack + USB-B windows in the −X wall
        for (w = [[mega_y_top - 16, mega_y_top - 1],     // barrel jack
                  [mega_y_top - 47, mega_y_top - 27]])   // USB-B
            translate([mce_x0 - 1, w[0], z_win - 15])
                cube([mcase_wall + 1.5, w[1] - w[0], 15]);

        // blind M3 self-tap pilots for the lid screws, in the corner meat
        for (p = mcase_lid_pts)
            translate([p[0], p[1], -mcase_body_d - 0.1])
                cylinder(h = 12.1, d = uln_pilot);
    }
}

module mega_case_lid_in_place() {
    mcx = (mci_x0 + mci_x1) / 2;
    mcy = (mci_y0 + mci_y1) / 2;
    uln_pts = [for (s = [[1,1], [1,-1], [-1,1], [-1,-1]])
                  [mcx + s[0]*uln_hole_dx/2, mcy + s[1]*uln_hole_dy/2]];
    difference() {
        union() {
            mc_rbox(mce_x0, mce_x1, mce_y0, mce_y1,
                    -mcase_ext_d, -mcase_body_d, mcase_rc);
            // ULN2003 posts — board sits on the post tops, components
            // facing the Mega
            for (p = uln_pts)
                translate([p[0], p[1], -mcase_body_d])
                    cylinder(h = uln_post_h, d = 7);
        }
        // ULN board pilots, blind (stop 0.5 above the outer face)
        for (p = uln_pts)
            translate([p[0], p[1], -mcase_body_d + uln_post_h - 8])
                cylinder(h = 8.1, d = uln_pilot);
        // lid screws: M3 clearance + head counterbore
        for (p = mcase_lid_pts) {
            translate([p[0], p[1], -mcase_ext_d - 1])
                cylinder(h = mcase_lid_t + 2, d = 3.4);
            translate([p[0], p[1], -mcase_ext_d - 0.01])
                cylinder(h = 1.2, d = m3_head_d + 0.3);
        }
    }
}

// exact bounding box of case + lid in led_body's frame — used by
// motor_mount.scad's preview to check the swept clearance
module mega_case_envelope() {
    translate([mce_x0, mce_y0, -mcase_ext_d])
        cube([mce_x1 - mce_x0, mce_y1 - mce_y0, mcase_ext_d]);
}

// print-ready: mate face on the bed, cavity opening up
module mega_case_print() {
    rotate([180, 0, 0]) mega_case_in_place();
}

// print-ready: outer face on the bed, ULN posts up
module mega_case_lid_print() {
    translate([0, 0, mcase_ext_d]) mega_case_lid_in_place();
}

// Drill template for an already-printed led_body: print, then FLIP it
// onto the back face with the skirt hooking the rim on the cable-hole
// side (the Ø6.5 notch lines up with the radial cable hole).  The cut
// label reads correctly when it is placed the right way round.
module mega_drill_template_print() {
    R = dew_shield_r + extra_diameter + wall_t;
    difference() {
        union() {
            cylinder(h = 1.2, r = R);
            // rim skirt, −X side: hangs 0.4 clear of the rim, tied to the
            // plate by a flat tab reaching over the edge
            intersection() {
                union() {
                    linear_extrude(14)
                        difference() {
                            circle(r = R + 2.9);
                            circle(r = R + 0.4);
                        }
                    linear_extrude(1.2)
                        difference() {
                            circle(r = R + 2.9);
                            circle(r = R - 1);
                        }
                }
                translate([-(R + 5), -14, -1]) cube([R + 5, 28, 16]);
            }
        }
        // notch onto the radial cable hole (led_body z ≈ 10.5)
        translate([-(R + 5), 0, 11.7])
            rotate([0, 90, 0]) cylinder(h = 10, d = 6.5);
        // hole pattern + label, y-mirrored: using the template means
        // flipping it over, which mirrors it back onto led_body's layout
        mirror([0, 1, 0]) {
            for (p = mcase_attach_pts)
                translate([p[0], p[1], -1])
                    cylinder(h = 4, d = mcase_attach_d);
            translate([mcase_wire_xy[0], mcase_wire_xy[1], -1])
                cylinder(h = 4, d = mcase_wire_d);
            // engraved 0.6 into the bed face (through-cut would detach
            // the letter counters); reads correctly on the exposed face
            // once the template is flipped into place
            translate([0, 25, -1])
                linear_extrude(1.6)
                    text("OK WHEN READABLE", size = 5, halign = "center");
        }
    }
}

if (mega_case_mount)
    echo(str("Mega case: ", mce_x1 - mce_x0, " × ", mce_y1 - mce_y0,
             " mm footprint, ", mcase_ext_d,
             " mm deep behind the panel (incl. lid)"));

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

module diffuser(h, flange_h, diffuser_thickness) {
    difference() {
        union() {
            difference() {
                difference() {
                    cylinder(h=h, r=dew_shield_r + extra_diameter + wall_t, center = true);     
                    translate([0, 0, diffuser_thickness])
                    cylinder(h=h, r=dew_shield_r + extra_diameter, center = true);
                }
                //cylinder(h=h + 2, r=dew_shield_r + extra_diameter - diffuser_ailette_w, center = true);
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

// LED body
if (show_base)
    translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
        rotate([0, -90, 0])
            translate([0, -(dew_shield_r - 10), arm_holder_thickness/2]) {
                led_body();
                if (show_mega_case) mega_case_in_place();
                if (show_mega_lid)  mega_case_lid_in_place();
            }
            
// Diffuser 1
if (false)
    translate([-led_h - diffuser_h, 0, 0])
        translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
            rotate([0, 90, 0])
                translate([0, -(dew_shield_r - 10), -arm_holder_thickness/2]) {
                    diffuser(4, 4, 0.4);
                    if (show_diffuser_gabarit)            
                        gabarit_diffuser();
                    }
// Gap
if (show_spacers)
    translate([-led_h - diffuser_h - (air_gap_h/2), 0, 0])
        translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
            rotate([0, -90, 0])
                translate([0, -(dew_shield_r - 10), arm_holder_thickness/2])
                    gap(air_gap_h, air_gap_h);
                
// Diffuser 2
if (show_diffusers)
    translate([-led_h - diffuser_h * 2 - (air_gap_h/2), 0, 0])
        translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
            rotate([0, 90, 0])
                translate([0, -(dew_shield_r - 10), -arm_holder_thickness/2]) {
                    diffuser(4, 4, 0.4);
                    if (show_diffuser_gabarit)
                        gabarit_diffuser();
                    }
// Pad holder
if (show_pad_holder)
    translate([-led_h - diffuser_h * 2 - (air_gap_h/2) - pad_holder_h, 0, 0])
        translate([arm_horiz_len - (arm_holder_thickness - arm_w)/2, -arm_vert_offset -arm_slot_margin - (arm_slot_start + arm_slot_len/2) - flat_panel_arm_offset, 0])
            rotate([0, 90, 0])
                translate([0, -(dew_shield_r - 10), -arm_holder_thickness/2])
                    pad_holder(pad_holder_h);
                
// Arms
if (show_arms)
    linkage_arms();
            
}


module gabarit_diffuser(){
 difference(){
    cylinder(h=2, r=dew_shield_r + extra_diameter - 1);
    diffuser(5, 3);
    flanges(h = 6);
    }
}



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

//diffuser(5, 2);

//pad_holder(pad_holder_h);

OPEN_ANGLE = $t * 270;

rotate([0, 0, OPEN_ANGLE])
    assembly();

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

// ── Arduino Mega case prints ──
//mega_case_print();           // case body, mate face on the bed
//mega_case_lid_print();       // lid, outer face on the bed, ULN posts up
//mega_drill_template_print(); // for drilling an already-printed led_body

// in-place preview behind led_body:
//led_body(); mega_case_in_place(); mega_case_lid_in_place();

