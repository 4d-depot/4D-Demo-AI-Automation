---
name: 4d-form-layout
description: "Use when: sizing, positioning, aligning, or spacing controls in a 4D .4DForm file. Covers the rendered offset formula (border/radius/focus-ring), the tools/form_layout_calc.py calculator, gap analysis, visual-edge alignment, strip centering, CSS-vs-JSON property split, and a step-by-step workflow. Load this skill whenever changing left/top/width/height of any form object, checking for overlap, or aligning edges."
---

# 4D Form Layout Skill

## When to Load This Skill

Load whenever you are:
- Setting or changing `left`, `top`, `width`, `height` of any form control
- Aligning two controls to the same visual edge
- Centering controls inside a strip or toolbar
- Checking for visual overlap / gap between adjacent controls
- Sizing a control to match a desired visual footprint
- Debugging why something looks off between Form Editor and live rendering

---

## Step-by-Step Workflow

### 1. Identify control types

Map each control to a preset from `form_layout_calc.py`:

| Control | Preset | border | radius | focusable |
|---------|--------|--------|--------|-----------|
| `input` (enterable) | `FILTER_INPUT` | ✓ | 8 | ✓ |
| `combo` | `FILTER_INPUT` | ✓ | 8 | ✓ |
| `input` (read-only, `enterable: false`) | `DETAIL_TEXT` | ✓ | 8 | ✗ |
| `button` (any style) | `BUTTON` | ✗ | 0 | ✓ |
| `listbox` (no scroll) | `LISTBOX` | ✗ | 0 | ✗ |
| `listbox` (auto scroll) | `LISTBOX_SCROLL` | ✗ | 0 | ✗ |
| `rectangle`, `line`, `text` | `RECT_PLAIN` | ✗ | 0 | ✗ |

### 2. Compute visual extents

Use **editor mode** (`live=False`) when working in the Form Editor and positioning
controls relative to each other:

```python
from tools.form_layout_calc import *

# Where does inputSearch visually appear in the editor?
left = 21
vl = visual_left(left, FILTER_INPUT, live=False)    # → 12  (21 - 9)
vr = visual_right(left, 271, FILTER_INPUT, live=False) # → 301 (21+271+9)
```

Use `live=True` (or omit) for runtime/screenshot comparisons.

### 3. Align edges

```python
# Declare left so visual left matches a reference pixel (12 here):
new_left = declared_left_for_visual_left(12, FILTER_INPUT, live=False)  # → 21

# Declare left so visual right matches a reference pixel:
new_left = declared_right_for_visual_right(400, width, FILTER_INPUT, live=False)
```

### 4. Center vertically in a strip

```python
# No props needed — offsets are symmetric, visual center == declared center
top = center_v_in_strip(strip_top=104, strip_height=86, ctrl_height=30)  # → 132
```

### 5. Check gaps between adjacent controls

```python
gap = visual_gap(left1, width1, FILTER_INPUT, left2, FILTER_INPUT, live=False)
# positive = clearance (safe), negative = overlap
```

Minimum declared gap for zero visual overlap:
```python
min_gap = min_declared_gap(FILTER_INPUT, FILTER_INPUT, clearance=2, live=False)
# → 20px (9+9+2)
```

### 6. Back-calculate declared size from visual target

```python
dw, dh = declared_for_visual(300, 30, FILTER_INPUT, live=False)
# → (282, 12) — declare width=282 to appear 300px wide in editor
```

### 7. Run the calculator

```bash
# Validate constants + report current form layout
python3 tools/form_layout_calc.py

# Show alignment pattern examples
python3 tools/form_layout_calc.py --align

# Back-solve: what to declare for a 300×30 visual slot (editor mode)
python3 tools/form_layout_calc.py --solve 300 30 --border --radius 8 --editor
```

---

## Rendering Offset Reference

All values are **logical pixels** (divide by 2 for Retina/screenshot pixels).

| Effect | Value | Sides affected | When |
|--------|-------|----------------|------|
| `borderStyle: solid` | +1 px | all 4 sides | always |
| `borderRadius: r` | +r px | all 4 sides | arc extends **outward** from declared corners |
| macOS focus ring | +5 px | all 4 sides | **live only** (not in Form Editor) |
| `scrollbarVertical: automatic` | +15 px | right side only | always |

**Full formula:**
```
rendered_w = declared_w + 2 × (border + radius + focus_ring) + scrollbar_h
rendered_h = declared_h + 2 × (border + radius + focus_ring)
```

**Per-control quick reference** (Form Editor, live=False):

| Preset | Per-side offset | Total width overhead |
|--------|----------------|---------------------|
| `FILTER_INPUT` | 9 (1+8) | +18 |
| `DETAIL_TEXT` | 9 (1+8) | +18 |
| `BUTTON` | 0 (no border, no radius, focus ring is live-only) | +0 |
| `LISTBOX` | 0 | +0 |
| `LISTBOX_SCROLL` | 0 left/top/bottom; +15 right | +15 |

**Important:** `roundedBevel` button bevel is drawn ~4 px **inside** declared bounds.
The declared left edge IS the visual left edge (offset=0 in editor).
Inputs extend **outside** declared bounds (offset=9 in editor).

---

## Empirical Validation

```
inputSearch, declared_w=280, border=1, radius=8:
  Form Editor (radius=0): (280 + 2)         × 2 = 564 retina px  ✓
  Form Editor (radius=8): (280 + 2 + 16)    × 2 = 596 retina px  ✓
  Live form   (radius=8): (280 + 2 + 16 +10)× 2 = 616 retina px  ✓
```

---

## CSS vs JSON Property Split

**Rule:** If removing the property from JSON would change *which native widget* is drawn
(not just how it looks), keep it in JSON.

### Must stay in JSON (structural)

| Property | Why |
|----------|-----|
| `style` | Selects the native widget (roundedBevel, toolbar, regular…) |
| `textPlacement` | Positions icon relative to text |
| `sizingX`, `sizingY` | Layout anchoring (fixed, move, grow) |
| `splitterMode` | Resize vs collapse behaviour |
| `multiline`, `wordwrap` | Text wrapping mode |
| `enterable` | Whether field accepts input |
| `scrollbarVertical`, `scrollbarHorizontal` | Scroll behaviour |
| `hideFocusRing` | Suppresses focus ring rendering |
| `rowHeight`, `headerHeight` | Listbox row sizing |

### Safe to put in CSS only (visual)

`fill`, `stroke`, `alternateFill`, `fontSize`, `fontWeight`, `fontStyle`,
`borderStyle`, `borderRadius`, `textAlign`, `verticalAlign`, `color`

### CSS syntax reminders

- **No units on numeric properties:** `borderRadius: 8` not `borderRadius: 8px` (causes parse error 555)
- **`roundedBevel` button:** always include `textAlign: center` and explicit `fontSize` in the CSS class — omitting `fontSize` shows "0" in the property list and a runtime error
- **CSS preview:** Supported since 4D v18 R5 (toggle in Form Editor toolbar) but structural properties from CSS alone may not be simulated — always set structural props in JSON

---

## Alignment Patterns

### Pattern 1 — Align input visual-left to button left edge

```
Button   declared left=12, no border, no radius → visual left=12
Input    want visual left=12 → declare left = 12 + 9 = 21

declared_left_for_visual_left(12, FILTER_INPUT, live=False) → 21
```

### Pattern 2 — Maintain right edge while changing left

```
# inputSearch: left=21, width=271
# visual right = 21 + 271 + 9 = 301
# Change left to 30, keep visual right at 301:
# new_width = visual_right - new_left - offset = 301 - 30 - 9 = 262
new_left, new_width = 30, 262
```

### Pattern 3 — Space a row of identical controls evenly

```python
SLOT = 196   # declared width per input (183 declared + 13 declared gap)
# visual gap = SLOT - (183 + 9 + 9) = SLOT - 201
# For 2px visual gap: SLOT = 203, gap = 20 declared
starts = [322, 322+203, 322+406, 322+609]  # cbTag, cbStatus, cbVIP, cbVoter
```

### Pattern 4 — Center-align a control in a strip

```python
top = center_v_in_strip(104, 86, 30)  # → 132
# Works for any control regardless of border/radius (offsets are symmetric)
```

---

## Pitfalls Checklist

- [ ] **Editor vs live**: Measure overlap in editor? Use `live=False`. Measure in screenshot? Use `live=True`.
- [ ] **borderRadius units**: `borderRadius: 8` in CSS, never `8px`.
- [ ] **roundedBevel fontSize**: CSS class for `.actionButton` must include explicit `fontSize` — never strip it.
- [ ] **Focus ring in editor**: The 5px focus ring does NOT appear in the Form Editor. `BUTTON.edge_offset(live=False)` = 0, not 5.
- [ ] **Overlap check**: Always call `visual_gap(..., live=False)` for every adjacent pair after moving controls.
- [ ] **Structural in JSON**: After moving styling to CSS, re-check that `style`, `sizingX/Y`, `textPlacement` are still in JSON.
- [ ] **borderRadius direction**: 4D radius extends **outward** from declared corners. A wider declared width → wider visual rendering. Place controls accordingly.
