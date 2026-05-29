#!/usr/bin/env python3
"""
4D Form Layout Calculator
=========================
Computes actual rendered visual dimensions for 4D form objects,
accounting for 4D-specific rendering offsets confirmed by empirical measurement.

CONFIRMED RENDERING OFFSETS (logical pixels; Retina px = logical × 2):

  borderStyle solid   → +1 px each side (stroke drawn OUTSIDE declared bounds)
  borderRadius r      → +r px each side (arc centers AT the declared corners,
                        so arcs extend OUTWARD — opposite of CSS border-radius)
  macOS focus ring    → +5 px each side, ONLY in live form rendering
                        (space is reserved; blue glow only when focused)
  scrollbarVertical   → +15 px right side only

EDITOR vs LIVE:
  The Form Editor does NOT render the macOS focus ring (+5px each side).
  Pass live=False to get Form Editor coordinates (default is live=True).
  All public functions accept a `live` keyword argument.

FULL RENDERED SIZE FORMULA:
  rendered_w = declared_w + 2*(border + radius + focus_ring) + scrollbar_h
  rendered_h = declared_h + 2*(border + radius + focus_ring)

EMPIRICAL VALIDATION (inputSearch, declared_w=280, border=1, radius=8):
  Form Editor, radius=0 : (280 + 2)          × 2 =  564 retina px  ✓
  Form Editor, radius=8 : (280 + 2 + 16)     × 2 =  596 retina px  ✓
  Live form,   radius=8 : (280 + 2 + 16 + 10)× 2 =  616 retina px  ✓

VISUAL-LEFT ALIGNMENT GUIDE (Form Editor / live=False):

  Control type          | left_offset  | Declare left = desired_visual_left + offset
  ----------------------|--------------|---------------------------------------------
  FILTER_INPUT (input)  | 9  (1+8)     | left = X + 9
  FILTER_INPUT (combo)  | 9  (1+8)     | left = X + 9
  BUTTON (any style)    | 0            | left = X  (no border, no radius; focus ring
                                         is live-only; bevel is drawn INSIDE)

  Example: align inputSearch visual-left to btnEmailResults (declared left=12):
    declared_left_for_visual_left(12, FILTER_INPUT, live=False) → 21

CENTERING IN A STRIP:
  declared_top = center_v_in_strip(strip_top, strip_height, ctrl_height)
  = strip_top + (strip_height - ctrl_height) // 2
  (Offsets are symmetric so visual center == declared center — no props needed)

USAGE (command line):
  python3 tools/form_layout_calc.py                 # validation + form check
  python3 tools/form_layout_calc.py --check         # current form layout report
  python3 tools/form_layout_calc.py --align         # alignment pattern examples
  python3 tools/form_layout_calc.py --solve 280 30 --border --radius 8 --focusable
  python3 tools/form_layout_calc.py --solve 280 30 --border --radius 8 --editor

USAGE (import):
  from tools.form_layout_calc import (
      ControlProps, FILTER_INPUT, BUTTON, LISTBOX_SCROLL,
      visual_bbox, visual_left, visual_right,
      declared_left_for_visual_left, center_v_in_strip, visual_gap
  )

CONTROL PRESETS for this project:
  FILTER_INPUT   = ControlProps(border=True,  radius=8, focusable=True)   # inputs, combos
  DETAIL_TEXT    = ControlProps(border=True,  radius=8, focusable=False)  # read-only text areas
  BUTTON         = ControlProps(border=False, radius=0, focusable=True)   # roundedBevel / toolbar
  LISTBOX        = ControlProps(border=False, radius=0, focusable=False)
  LISTBOX_SCROLL = ControlProps(border=False, radius=0, focusable=False, scrollbar_v=True)
  RECT_PLAIN     = ControlProps(border=False, radius=0, focusable=False)
"""

# ── Constants (empirically measured) ──────────────────────────────────────────
BORDER_PX    = 1   # borderStyle: solid → 1 px outside each side
FOCUS_PX     = 5   # macOS focus ring, live rendering only (not in Form Editor)
SCROLLBAR_PX = 15  # scrollbarVertical: automatic, right side only


# ── Data class ─────────────────────────────────────────────────────────────────

class ControlProps:
    """Properties that affect a control's visual footprint beyond declared bounds."""

    def __init__(self, *, border=False, radius=0, focusable=False, scrollbar_v=False):
        self.border      = border       # borderStyle: solid
        self.radius      = radius       # borderRadius value (integer, no units)
        self.focusable   = focusable    # enterable input / combo / button
        self.scrollbar_v = scrollbar_v  # scrollbarVertical: automatic

    def __repr__(self):
        parts = []
        if self.border:       parts.append("border")
        if self.radius:       parts.append(f"radius={self.radius}")
        if self.focusable:    parts.append("focusable")
        if self.scrollbar_v:  parts.append("scrollbar_v")
        return f"ControlProps({', '.join(parts) or 'none'})"

    def _base(self, live=True) -> int:
        """
        Per-side base offset (excluding scrollbar).
        live=False = Form Editor view (no focus ring).
        """
        b = (BORDER_PX if self.border else 0) + self.radius
        if live and self.focusable:
            b += FOCUS_PX
        return b

    def edge_offset(self, side='left', live=True) -> int:
        """Render offset for a specific edge in logical pixels."""
        b = self._base(live)
        if side == 'right' and self.scrollbar_v:
            b += SCROLLBAR_PX
        return b

    # Legacy per-side properties (live=True) — kept for backward compatibility
    @property
    def left_offset(self):   return self.edge_offset('left',   live=True)
    @property
    def top_offset(self):    return self.edge_offset('top',    live=True)
    @property
    def right_offset(self):  return self.edge_offset('right',  live=True)
    @property
    def bottom_offset(self): return self.edge_offset('bottom', live=True)


# ── Core size / position API ───────────────────────────────────────────────────

def visual_bbox(left, top, width, height, props: ControlProps, *, live=True) -> dict:
    """
    Returns the actual rendered bounding box in logical pixels.
    live=True  → live form rendering (includes focus ring)
    live=False → Form Editor view (no focus ring)
    """
    ol  = props.edge_offset('left',   live)
    ot  = props.edge_offset('top',    live)
    or_ = props.edge_offset('right',  live)
    ob  = props.edge_offset('bottom', live)
    return {
        'left':   left   - ol,
        'top':    top    - ot,
        'right':  left   + width  + or_,
        'bottom': top    + height + ob,
        'width':  width  + ol + or_,
        'height': height + ot + ob,
    }


def declared_for_visual(visual_w, visual_h, props: ControlProps, *, live=True) -> tuple:
    """
    Back-calculate: given a desired visual size, return (declared_width, declared_height).
    """
    dw = visual_w - props.edge_offset('left',  live) - props.edge_offset('right',  live)
    dh = visual_h - props.edge_offset('top',   live) - props.edge_offset('bottom', live)
    return dw, dh


# ── Alignment helpers ──────────────────────────────────────────────────────────

def visual_left(left: int, props: ControlProps, *, live=True) -> int:
    """Visual left edge of a control (may extend left of its declared left)."""
    return left - props.edge_offset('left', live)


def visual_right(left: int, width: int, props: ControlProps, *, live=True) -> int:
    """Visual right edge of a control (may extend right of its declared right)."""
    return left + width + props.edge_offset('right', live)


def declared_left_for_visual_left(target_visual_left: int, props: ControlProps,
                                   *, live=True) -> int:
    """
    Compute the declared left so the control's visual left edge equals target_visual_left.

    Example — align inputSearch (FILTER_INPUT) to btnEmailResults visual left=12:
      declared_left_for_visual_left(12, FILTER_INPUT, live=False) → 21
      (because FILTER_INPUT left_offset in editor = border(1) + radius(8) = 9)
    """
    return target_visual_left + props.edge_offset('left', live)


def declared_right_for_visual_right(target_visual_right: int, declared_width: int,
                                     props: ControlProps, *, live=True) -> int:
    """Compute declared left so the control's visual right edge equals target_visual_right."""
    return target_visual_right - declared_width - props.edge_offset('right', live)


def center_v_in_strip(strip_top: int, strip_height: int, ctrl_height: int) -> int:
    """
    Declared top to visually center a control in a horizontal strip.
    No props needed: offsets are symmetric, so visual center == declared center.

    Examples:
      center_v_in_strip(104, 86, 30) → 132   (filter strip)
      center_v_in_strip(60,  44, 28) → 74    (toolbar)
    """
    return strip_top + (strip_height - ctrl_height) // 2


# ── Gap helpers ────────────────────────────────────────────────────────────────

def visual_gap(left1: int, width1: int, props1: ControlProps,
               left2: int,             props2: ControlProps, *, live=True) -> int:
    """
    Visual clearance between right edge of ctrl1 and left edge of ctrl2.
    Positive = gap (safe), negative = overlap.
    """
    r1 = visual_right(left1, width1, props1, live=live)
    l2 = visual_left(left2,          props2, live=live)
    return l2 - r1


def visual_gap_h(ctrl1_left, ctrl1_width, ctrl1_props: ControlProps,
                 ctrl2_left,              ctrl2_props: ControlProps,
                 *, live=True) -> int:
    """Alias for visual_gap (backward compatibility)."""
    return visual_gap(ctrl1_left, ctrl1_width, ctrl1_props,
                      ctrl2_left, ctrl2_props, live=live)


def min_declared_gap(props1: ControlProps, props2: ControlProps,
                     clearance=0, *, live=True) -> int:
    """
    Minimum declared gap between adjacent controls to achieve `clearance` visual px.
    Default clearance=0 = just touching (no overlap).
    """
    return props1.edge_offset('right', live) + props2.edge_offset('left', live) + clearance


# ── Named presets for this project ─────────────────────────────────────────────

FILTER_INPUT   = ControlProps(border=True,  radius=8, focusable=True)   # inputs, combos
DETAIL_TEXT    = ControlProps(border=True,  radius=8, focusable=False)  # read-only text areas
BUTTON         = ControlProps(border=False, radius=0, focusable=True)   # roundedBevel / toolbar
LISTBOX        = ControlProps(border=False, radius=0, focusable=False)
LISTBOX_SCROLL = ControlProps(border=False, radius=0, focusable=False, scrollbar_v=True)
RECT_PLAIN     = ControlProps(border=False, radius=0, focusable=False)


# ── CLI helpers ────────────────────────────────────────────────────────────────

def _section(title):
    print(f"\n{'─'*64}")
    print(f"  {title}")
    print(f"{'─'*64}")


def _gap_row(n1, l1, w1, p1, n2, l2, p2, live=False):
    decl_gap = l2 - (l1 + w1)
    vgap     = visual_gap(l1, w1, p1, l2, p2, live=live)
    status   = "✓" if vgap >= 0 else f"← {abs(vgap)}px OVERLAP"
    print(f"  {n1} → {n2:<20}  decl:{decl_gap:4d}px   visual:{vgap:4d}px   {status}")


def run_validation():
    """Reproduce empirical measurements to validate constants."""
    _section("EMPIRICAL VALIDATION  (retina px = logical × 2)")
    cases = [
        ("inputSearch radius=0  (Form Editor)", ControlProps(border=True, radius=0,  focusable=False), 280, 26, 564),
        ("inputSearch radius=8  (Form Editor)", ControlProps(border=True, radius=8,  focusable=False), 280, 26, 596),
        ("inputSearch radius=8  (Live form)  ", ControlProps(border=True, radius=8,  focusable=True),  280, 26, 616),
    ]
    for label, props, w, h, expected_retina in cases:
        bbox   = visual_bbox(0, 0, w, h, props)
        retina = bbox['width'] * 2
        ok = "✓" if retina == expected_retina else f"✗ expected {expected_retina}"
        print(f"  {label}: visual={bbox['width']:3d}px  retina={retina}px  {ok}")


def run_form_check():
    """
    Check the current CustomerBacklog form layout (visual footprints + gaps).
    Coordinates reflect the live form.4DForm as of 2026-04.
    """
    # ── Filter strip row ──────────────────────────────────────────────────────
    _section("FILTER STRIP  top=104 h=86  (control row top=132 h=30)  — Form Editor offsets")

    filter_row = [
        ("inputSearch",     21,   271, FILTER_INPUT),
        ("cbTagFilter",    322,   183, FILTER_INPUT),
        ("cbStatusFilter", 535,   183, FILTER_INPUT),
        ("cbVIPFilter",    748,   183, FILTER_INPUT),
        ("cbVoterFilter",  961,   183, FILTER_INPUT),
        ("btnClearFilters",1165,   36, BUTTON),
    ]

    print(f"  {'Control':<18} {'Declared [L  W  R]':>22}   {'Visual [L    R]':>18}   VW")
    for name, left, w, props in filter_row:
        bb = visual_bbox(left, 0, w, 0, props, live=False)
        print(f"  {name:<18}  [{left:4d}  {w:3d}  {left+w:4d}]    [{bb['left']:4d}  {bb['right']:4d}]    {bb['width']:3d}")

    print()
    print(f"  {'Gap between':<40}  decl   visual  status")
    for i in range(len(filter_row) - 1):
        n1, l1, w1, p1 = filter_row[i]
        n2, l2, _,  p2 = filter_row[i + 1]
        _gap_row(n1, l1, w1, p1, n2, l2, p2, live=False)

    # ── Toolbar row ───────────────────────────────────────────────────────────
    _section("TOOLBAR  top=60 h=44  (buttons top=68 h=28)  — Form Editor offsets")

    toolbar_row = [
        ("btnEmailResults",   12, 148, BUTTON),
        ("btnToggleFilters", 174, 108, BUTTON),
        ("btnPrev",         1502,  28, BUTTON),
        ("btnNext",         1562,  28, BUTTON),
    ]

    print(f"  {'Control':<20} {'Declared [L  W  R]':>22}   {'Visual [L    R]':>18}   VW")
    for name, left, w, props in toolbar_row:
        bb = visual_bbox(left, 0, w, 0, props, live=False)
        print(f"  {name:<20}  [{left:4d}  {w:3d}  {left+w:4d}]    [{bb['left']:4d}  {bb['right']:4d}]    {bb['width']:3d}")

    # ── Centering check ───────────────────────────────────────────────────────
    _section("VERTICAL CENTERING CHECK")
    centering_cases = [
        ("filter inputs",   104, 86, 30),
        ("toolbar buttons",  60, 44, 28),
    ]
    for label, strip_top, strip_h, ctrl_h in centering_cases:
        ideal  = center_v_in_strip(strip_top, strip_h, ctrl_h)
        margin = (strip_h - ctrl_h) // 2
        print(f"  {label:<20}  strip=[{strip_top},{strip_top+strip_h})  ctrl_h={ctrl_h}  "
              f"→ declared top={ideal}  margin={margin}px each side")

    # ── Min gap reference ─────────────────────────────────────────────────────
    _section("MINIMUM DECLARED GAP REFERENCE  (Form Editor, live=False)")
    pairs = [
        ("FILTER_INPUT → FILTER_INPUT",  FILTER_INPUT,  FILTER_INPUT),
        ("FILTER_INPUT → BUTTON",        FILTER_INPUT,  BUTTON),
        ("BUTTON       → FILTER_INPUT",  BUTTON,        FILTER_INPUT),
        ("BUTTON       → BUTTON",        BUTTON,        BUTTON),
    ]
    for label, p1, p2 in pairs:
        m0 = min_declared_gap(p1, p2, 0, live=False)
        m2 = min_declared_gap(p1, p2, 2, live=False)
        print(f"  {label:<32}  {m0}px (0-clearance)   {m2}px (2px clearance)")


def run_align_demo():
    """Show how to compute declared positions for common alignment patterns."""
    _section("ALIGNMENT EXAMPLES  (editor mode, live=False)")

    # Align inputSearch visual left = 12
    target = 12
    dl = declared_left_for_visual_left(target, FILTER_INPUT, live=False)
    vl = visual_left(dl, FILTER_INPUT, live=False)
    print(f"  Align FILTER_INPUT visual-left to {target}:  declare left = {dl}  →  visual left = {vl}  ✓")

    # Show gap between inputSearch and first combo
    input_l, input_w = 21, 271
    combo_l = 322
    gap_e = visual_gap(input_l, input_w, FILTER_INPUT, combo_l, FILTER_INPUT, live=False)
    gap_l = visual_gap(input_l, input_w, FILTER_INPUT, combo_l, FILTER_INPUT, live=True)
    print(f"\n  Gap inputSearch → cbTagFilter:  editor={gap_e}px  live={gap_l}px")

    # Center 30px control in filter strip
    top = center_v_in_strip(104, 86, 30)
    print(f"\n  Center 30px control in strip (top=104, h=86):  declare top = {top}")

    # Center 28px button in toolbar
    top2 = center_v_in_strip(60, 44, 28)
    print(f"  Center 28px button  in toolbar (top=60,  h=44):  declare top = {top2}")


def run_solver(visual_w, visual_h, props: ControlProps, live=True):
    """Given desired visual size, compute declared dimensions."""
    mode = "live" if live else "editor"
    _section(f"SOLVER  →  visual {visual_w}×{visual_h}  with {props}  [{mode}]")
    dw, dh = declared_for_visual(visual_w, visual_h, props, live=live)
    bb = visual_bbox(0, 0, dw, dh, props, live=live)
    print(f"  Declare width={dw}, height={dh}")
    print(f"  Roundtrip: visual width={bb['width']} (want {visual_w})  {'✓' if bb['width']==visual_w else '✗'}")


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description="4D Form Layout Calculator")
    parser.add_argument('--check',     action='store_true', help='Report current form layout')
    parser.add_argument('--align',     action='store_true', help='Show alignment pattern examples')
    parser.add_argument('--solve',     metavar=('W', 'H'), nargs=2, type=int,
                        help='Compute declared size for desired visual W×H')
    parser.add_argument('--editor',    action='store_true', help='Use editor mode for --solve (no focus ring)')
    parser.add_argument('--border',    action='store_true')
    parser.add_argument('--radius',    type=int, default=0)
    parser.add_argument('--focusable', action='store_true')
    parser.add_argument('--scroll',    action='store_true')
    args = parser.parse_args()

    run_validation()

    if args.check or (not args.solve and not args.align):
        run_form_check()

    if args.align:
        run_align_demo()

    if args.solve:
        props = ControlProps(
            border=args.border, radius=args.radius,
            focusable=args.focusable, scrollbar_v=args.scroll
        )
        run_solver(args.solve[0], args.solve[1], props, live=not args.editor)
