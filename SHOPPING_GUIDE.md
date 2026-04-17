# RedCat 51 DIY Flat Panel — Project Summary & Montreal Shopping Guide

## What This Project Does

A computer-controlled flat panel for astrophotography calibration frames, designed for the William Optics RedCat 51. It connects to NINA via ASCOM Alpaca (auto-discovered over LAN) and acts as a standard CoverCalibrator device.

**Features:**
- Variable LED brightness (0–640) with **25 kHz PWM** on Timer1 (16-bit, pin 11) — 640 hardware steps vs. 80 on a standard 8-bit timer; eliminates the horizontal banding that kills flat frames with standard Arduino PWM (490 Hz)
- Motorized dust cover (stepper motor, 270° swing) that opens parallel to the tube to minimize wind resistance
- Fully automated flat frame sequences: NINA opens the cover, sets brightness, takes flats, closes cover

**Architecture:**
```
NINA  ──Alpaca HTTP──▶  Python server (PC)  ──USB Serial──▶  Arduino Mega  ──▶  LEDs + Stepper
```

---

## Bill of Materials & Where to Buy in Montreal

### Already Owned
| Item | Notes |
|---|---|
| Arduino Mega 2560 | Already in hand |
| A1 mini 3D printer | For enclosure parts |

---

### Electronics Components (~$15–25 CAD)

| Component | Qty | Est. Cost | Where to Buy |
|---|---|---|---|
| **IRLZ44N MOSFET** (logic-level N-channel) | 1–2 | ~$2–4 | **Addison Electronics** (6450 Côte-de-Liesse, Lachine) · DigiKey.ca · Mouser.ca |
| **220Ω resistor** (gate resistor) | 1 | <$0.50 | Addison Electronics · DigiKey.ca |
| **10kΩ resistor** (gate pull-down) | 1 | <$0.50 | Same as above |
| **Current-limiting resistor** for LED strip | 1 | ~$1 | Addison Electronics (calculate value from strip specs) |
| **28BYJ-48 stepper motor + ULN2003 driver board** | 1 | ~$3–6 | **RobotShop.com** (Mirabel, QC — fast shipping) · Amazon.ca |
| **Small proto/perf board** | 1 | ~$2–3 | Addison Electronics · RobotShop.com · Amazon.ca |
| **Dupont jumper wires** (M-M and M-F) | 1 pack | ~$3–5 | RobotShop.com · Amazon.ca |
| **M3 × 30 mm socket head cap screws** | 3 | ~$1–2 | Amazon.ca · Addison Electronics |
| **M3 nuts** | 3 | ~$0.50 | Amazon.ca · Addison Electronics |
| **M2 × 8 mm screws** | 2 | ~$0.50 | Amazon.ca |
| **M3 × 8 mm nylon-tipped set screws** (grub screws) | 2 | ~$2–3 | Amazon.ca (search "M3 nylon tip set screw") · DigiKey.ca |
| **M3 × 6 mm nylon-tipped set screw** | 1 | (same pack) | Same as above |
| **2–3 mm black EVA foam sheet** | 1 small | ~$2 | Dollarama · Amazon.ca |

> **Addison Electronics** is your best bet for resistors and the MOSFET — they stock a wide range of through-hole components and you can buy single units. Address: 6450 Côte-de-Liesse Rd, Lachine (near Dorval).

> **Why 28BYJ-48 instead of SG90 servo?** The 28BYJ-48 has a 64:1 internal gear reduction that is **self-locking** — wind cannot back-drive it even when unpowered. It also rotates a full 360°, making the 270° open position easy to reach. An SG90 only does 180° and has no holding torque when detached.

---

### LED Strip (~$10–15 CAD)

| Item | Spec | Reference | Where to Buy |
|---|---|---|---|
| **COB USB LED strip, cool white** | 5V USB · 6500K · COB · 320 LED/m · 8W/m · CRI90 · 2m · IP20 · on/off switch | *Clearhill — "Bande lumineuse LED COB USB 5V, blanc froid 6500K, 320 LED/m, 8W/m, CRI90, 2m, panneau double face galvanisé"* | **Amazon.ca** (search: "COB LED strip 5V USB 6500K CRI90") |

> You only need ~30 cm for the LED tray — the 2 m strip gives plenty of length to cut from. Leave the inline switch permanently **ON**; the Arduino MOSFET controls all dimming.

> **Why this strip?** COB (Chip-on-Board) produces a continuous glow with no individual LED hot spots, which dramatically reduces the diffusion work needed. 6500K cool white gives a good signal across all filters including LRGB and narrowband. CRI90 ensures broad spectral coverage.

---

### Diffusers (~$2–15 CAD)

**Try free/cheap materials first** before buying acrylic — they work well and let you validate your LED layout before committing to the final build.

| Option | Cost | Notes | Where to Buy |
|---|---|---|---|
| **White HDPE cutting board** | ~$2 | Semi-translucent, diffuses well, cuts cleanly | Dollarama |
| **White shower curtain liner** | ~$2 | Excellent diffusion, scissors-cut, good for testing | Dollarama |
| **Frosted acrylic 3mm — 8"×11.75" sheet** | ~$11 CAD | One sheet gives both 56×56mm squares with lots left over | **Canadian Laser Supply** (lasersupply.ca) — ships from Canada |
| **Frosted acrylic 3mm — small packs** | ~$8–15 CAD | 150×150mm packs, search "frosted acrylic sheet 3mm" | Amazon.ca |
| **Free offcuts** | Free | Call and ask for 3mm white/frosted acrylic offcuts — industrial suppliers often give small scrap away | **Plexi Design MTL** (plexidesignmtl.com) · **Piedmont Plastics** (plastiquespiedmont.com) · **Polymershapes Montreal** |

> **Recommended approach:** Start with a Dollarama white cutting board to test uniformity. Order from Canadian Laser Supply (~$11) for the final build.

#### Cutting the acrylic

You need two **56×56 mm square pieces**, 3 mm thick. This is the simplest possible cut — just two straight lines.

| Method | Tool | Cost | Notes |
|---|---|---|---|
| **Score-and-snap** (best for squares) | Metal ruler + utility knife / acrylic scoring tool | ~$0–5 | Score a straight line 5–6 times with firm pressure, then snap over a table edge. Clean break every time on 3mm acrylic. |
| **Table saw / circular saw** | Woodworking saw with fine-tooth blade | ~$0 (if available) | Fast and accurate. Low speed, masking tape on both faces to prevent chipping. |

> **No circular tools needed.** The 56×56mm square design was chosen specifically so that score-and-snap works perfectly — two straight cuts per piece. Do not use scissors — they will crack 3mm acrylic.

---

### 3D Printing Filament (~$2–5 CAD)

You'll use ~40–60 g total for the enclosure (adapter ring, LED tray, diffuser holders, hinged cover, stepper bracket).

| Material | Notes | Where to Buy |
|---|---|---|
| **PLA** | Easiest to print, fine for indoor use | **3DFilaments.ca** (ships from Quebec) · Amazon.ca · **Filaments.ca** |
| **PETG** | Slightly more durable if the panel sees dew | Same sources above |

> Use black filament for the enclosure body (opaque = no light leaks), and optionally white/natural for the LED tray interior to reflect more light forward.

---

### Optional but Recommended (~$3–8 CAD)

| Item | Purpose | Where to Buy |
|---|---|---|
| **Ferrite clip-on (snap-on core)**, fits USB cable | Suppresses EMI from PWM driver coupling into camera | **Addison Electronics** · Amazon.ca (search "ferrite clip USB") · DigiKey.ca |
| **Digital caliper** (150 mm) | Measure RedCat dew shield OD precisely for 3D print fit | **Canadian Tire** (~$15–20) · Amazon.ca (~$12) |

---

## Summary: Fastest vs. Cheapest Sourcing

| Strategy | Where | ETA | Notes |
|---|---|---|---|
| **Fastest** (same day) | Addison Electronics + Canadian Tire | Same day | MOSFET, resistors, proto board, caliper. Order LED strip + stepper online. |
| **Best balance** | Addison Electronics (passives) + RobotShop.com (stepper, proto board) + Amazon.ca (LED strip, filament) | 2–5 days | RobotShop ships from QC, usually 2–3 business days |
| **Cheapest** | AliExpress for everything except filament | 3–6 weeks | ~40–60% cheaper but long wait; fine for non-urgent parts |

---

## Recommended Shopping Trip (One-Stop)

**Addison Electronics** (Lachine) covers: MOSFET, resistors, proto board, possibly ferrite cores.

Then order online:
- **RobotShop.com** — 28BYJ-48 stepper + ULN2003 driver board + jumper wires
- **Amazon.ca** — COB LED strip (Clearhill 5V 6500K) + frosted acrylic sheet + PLA filament

Total estimated cost (excluding already-owned Arduino + printer): **~$35–55 CAD**

---

## 3D Printing — CAD Files

All parts are in `cad/flat_panel_v2.scad` (OpenSCAD, parametric). Open the file and uncomment one part at a time to export STL.

| Part | Qty | Colour | Notes |
|---|---|---|---|
| `adapter_ring()` | 1 | Black | Friction-fits over dew shield (63mm bore); stepper bracket on side; recess on top face receives pivot arm |
| `diffuser_ring(with_arm=true)` | 1 | White/Natural | **Bottom ring** — pivot arm on underside with D-shaft hole + M3 set screw; entire stack hinges here |
| `diffuser_ring()` | 1 | White/Natural | **Top ring** — no arm; holds second 56×56mm acrylic square |
| `air_gap_ring()` | 1 | Black | 5mm hollow spacer between the two diffuser layers |
| `main_body()` | 1 | Black | LED tray; solid top seals the assembly — no separate cover needed |
| `stepper_plate()` | 1 | Black | Retains 28BYJ-48 in side pocket of adapter ring |

> **Before printing:** measure the dew shield OD precisely with a caliper and update `dew_shield_od` at the top of `flat_panel.scad` (currently set to **63.0 mm** — verify with your caliper before printing the adapter ring). Adjust `fit_gap` (default 0.4 mm) for tighter/looser fit.
>
> **Housing dimensions:** 88mm OD × 80mm inner diameter, 4mm walls. The 56×56mm acrylic squares fit inside the 80mm inner circle (corners reach 39.6mm radius — just under the 40mm inner radius ✓).

### Circuit diagram

`cad/circuit.svg` — open in any browser. Shows all wiring: MOSFET dimmer circuit (pin 11 → 470Ω → IRLZ44N), ULN2003 stepper driver (pins 22/24/26/28), LED strip splice, and power rails.

---

## Quick-Start Checklist

- [ ] Measure RedCat 51 dew shield OD with caliper; update `dew_shield_od` in `flat_panel.scad`
- [ ] Print all 6 parts from `cad/flat_panel.scad`
- [ ] Buy components (see above)
- [ ] Wire circuit per `cad/circuit.svg`
- [ ] Flash `firmware/firmware.ino` to Arduino Mega via Arduino IDE
- [ ] Test serial protocol: open Serial Monitor (57600 baud), type `COMMAND:PING` → should reply `RESULT:PING:OK:...`
- [ ] Verify 25 kHz PWM: hold a small speaker near pin 11 — should be **silent** (25 kHz is above hearing range)
- [ ] Test stepper: send `COMMAND:COVER:OPEN` — cover should swing 270° and hold against gentle pressure
- [ ] Calibrate `STEPS_OPEN` in firmware if the open angle needs adjustment (default: 1536 steps = 270°)
- [ ] Install Python deps: `pip install -r requirements.txt`
- [ ] Run server: `python -m server.main --serial COM3 --auto-connect`
- [ ] In NINA: *Equipment → Flat Device → ASCOM Alpaca → Refresh* → select **RedCat51 Flat Panel**
- [ ] Take test flats, check for banding in PixInsight/AstroPixelProcessor
- [ ] Verify uniformity: target <3% center-to-edge variation; add diffuser layer if needed
