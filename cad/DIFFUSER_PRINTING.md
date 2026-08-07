# Diffuser Printing Guide

Print settings and design notes for the flat panel diffusers (`flat_panel.scad`, `diffuser()` module).
Goal: scatter light as uniformly as possible, with no visible pattern (lines, banding, pinholes) in flats.

Printer: Bambu Lab A1 mini · Material: white PLA · Slicer: Bambu Studio

---

## 1. Membrane thickness — the main issue

The current membrane is **0.15 mm** (`diffuser(4, 4, 0.15)`). It sits at the bottom of the ring, prints
face-down on the plate, and slices into **exactly one first layer**. A single extruded layer across a
~104 mm disc will have:

- **Pinholes** between adjacent extrusion lines — bright pinpricks with an LED behind, which ironing
  won't reliably close.
- **One dominant line direction** across the whole surface.

**Recommendation: make the membrane 0.4 mm** (0.2 mm first layer + one 0.2 mm layer). Two benefits for free:

- Slicers alternate solid-infill direction ~90° between consecutive layers, so the two layers cross
  and cancel each other's line pattern.
- The second layer covers the first layer's pinholes.

White PLA at 0.4 mm still transmits plenty of light; the PWM dimming (Arduino pin 11) compensates for
the loss. Uniformity matters far more than transmission for flats.

## 2. Slicer settings (plate-wide, no modifier needed)

The diffusers print alone in white PLA, so set everything at the plate/object level:

| Setting | Value | Why |
|---|---|---|
| Top/bottom surface pattern | **Monotonic** | Clean, consistent line direction per layer |
| Surface speed | **40–60 mm/s** | Consistent extrusion prevents banding; A1 mini fast defaults are the enemy |
| Flow calibration | **Run it before this print** | Flow inconsistency = broad light/dark banding, worse than line texture |
| Flow ratio | **~102–105 %** only if a test print shows gaps between lines | Closes micro-gaps |
| Build plate | **Textured PEI (stock)** | Frosted matte bottom face helps diffusion — better than smooth-plate gloss |

If Monotonic still shows directional structure, try **Hilbert Curve** as a non-directional
alternative (slower, slightly rougher). Avoid **Concentric**: it produces regular rings plus a radial
seam line — a more coherent pattern than crossed straight lines.

## 3. Ironing (via the center modifier)

The one genuine use of a center modifier: **confine ironing to the membrane** so the flange ring
doesn't get ironed (irrelevant there, wastes time).

Starting values: **~10–15 % flow · 0.1–0.15 mm line spacing · ~30 mm/s**.

Honest note: ironing fills grooves and evens out thickness, but leaves a glossier, more specular
surface and can add its own faint streaking. Scattering in white PLA happens mostly in the bulk
(the TiO₂ pigment), so surface finish is second-order — treat ironing as an **A/B test**, not a given.

## 4. Assembly tricks (independent of slicer)

- The flanges are 3×120°, so **clock the two diffusers 120° apart** in the stack. Combined with the
  10 mm air gap, this decorrelates any residual pattern regardless of slicer settings.
- The panel is completely defocused at the sensor — fine extrusion texture at ~0.4 mm pitch blurs
  away entirely. What survives into flats is **large-scale structure**: pinholes, banding, gradients.
  That's why the two-layer membrane and flow calibration outrank pattern choice.

## 5. Verification before committing

1. Print a **~40 mm test disc** with the same membrane recipe (takes minutes).
2. Hold it over the LED — look for pinpricks and banding.
3. Shoot an actual flat in NINA through the assembled stack and **stretch it hard** to check for
   structure — before spending the time on two full 104 mm diffusers.

## Troubleshooting: dark spots / dark lines

On a backlit membrane, **dark = locally thicker or denser material** (opposite of pinholes = excess plastic).

| Symptom | Cause | Fix |
|---|---|---|
| Raised dark dots | Start/stop blobs, seams (often wet filament) | Dry filament, slower speed, wipe on retract |
| Short dark dashes near the curved edge | Gap fill in the slivers where straight lines meet the circle | Tweak line width so slivers land differently; check preview |
| Dark ring at the perimeter | Wall/infill overlap too high | Reduce infill/wall overlap % |
| Broad dark streaks/bands | Over-extrusion, or ironing pass overlaps | Flow calibration; re-test with ironing off |

**Fastest diagnostic:** open the sliced file in Bambu Studio preview with line-type coloring and
compare the membrane layers against the print — gap fill, seams, and ironing each render distinctly.
If dark marks line up with a feature in the preview, that's the cause.

**Structural fixes that beat setting-tweaks:**

- **3-layer membrane (0.6 mm)** — each defect lives in one layer, so its contrast drops
  proportionally (1/2 → 1/3 of optical thickness). PWM headroom absorbs the transmission loss.
- **Judge through the real optical train.** With the panel on the dew shield and focus at infinity,
  each sensor pixel integrates a large area of the panel — mm-scale spots average out and vanish
  from the flat. Shoot a flat in NINA and stretch it hard before chasing by-eye defects; only broad
  gradients and large banding survive.

## Artifact sources, ranked by impact

1. **Pinholes** from a single-layer membrane → fix with 2-layer membrane (§1)
2. **Flow inconsistency banding** → fix with flow calibration + slow speed (§2)
3. **Extrusion-line texture** → largely irrelevant (defocused), further reduced by crossed layers,
   clocking, and optional ironing
