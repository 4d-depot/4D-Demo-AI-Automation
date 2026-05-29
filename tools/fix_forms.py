#!/usr/bin/env python3
"""Fix all 4D form JSON files: correct property names and color formats.

Issues fixed:
- Bare hex colors "0D0D0D" → "#0D0D0D" (CSS format required)
- textColor → stroke (4D uses stroke for font color)
- textSize → fontSize
- bold: true → fontWeight: "bold"
- rounding → borderRadius
- wordWrap → wordwrap (lowercase) with string values
- multiline: true → multiline: "yes"
- visible: false → visibility: "hidden"
- dataSourceType → listboxType
- rowsSource → dataSource
- alternateBackground → alternateFill
- rowHeight: N → rowHeight: "Npx"
- Listbox-level header object → headerHeight + showHeaders
- Column dataSource Form.x[].prop → This.prop
- selectedFill / selectedTextColor removed (non-standard)
- stroke: "none" → stroke: "transparent" or borderStyle: "none"
"""
import json
import glob
import os
import re

FORMS_DIR = '/Users/mathieu/Documents/4D Projects/4D-Demo-AI-Automation/Project/Sources/Forms'


def is_bare_hex(val):
    """Check if a string is a bare hex color (6 hex chars without # prefix)."""
    return isinstance(val, str) and bool(re.match(r'^[0-9A-Fa-f]{6}$', val))


def fix_color(val):
    """Add # prefix to bare hex colors; leave others untouched."""
    if is_bare_hex(val):
        return '#' + val
    return val


def fix_object(obj, is_column=False):
    """Fix a single form object's properties."""
    if not isinstance(obj, dict):
        return obj

    result = {}
    obj_type = obj.get('type', '')
    has_textColor = 'textColor' in obj

    for key, val in obj.items():

        # ── REMOVE non-standard properties ──────────────────────────
        if key in ('selectedFill', 'selectedTextColor'):
            continue

        # ── textColor → stroke ──────────────────────────────────────
        if key == 'textColor':
            # Rectangles don't render text via stroke
            if obj_type != 'rectangle':
                result['stroke'] = fix_color(val)
            continue

        # ── textSize → fontSize ─────────────────────────────────────
        if key == 'textSize':
            result['fontSize'] = val
            continue

        # ── bold → fontWeight ───────────────────────────────────────
        if key == 'bold':
            if val is True:
                result['fontWeight'] = 'bold'
            continue

        # ── rounding → borderRadius ─────────────────────────────────
        if key == 'rounding':
            result['borderRadius'] = val
            continue

        # ── wordWrap → wordwrap (lowercase, string value) ──────────
        if key == 'wordWrap':
            if val is True:
                result['wordwrap'] = 'normal'
            elif val is False:
                result['wordwrap'] = 'none'
            else:
                result['wordwrap'] = val
            continue

        # ── multiline boolean → string ──────────────────────────────
        if key == 'multiline':
            if val is True:
                result['multiline'] = 'yes'
            elif val is False:
                result['multiline'] = 'no'
            else:
                result['multiline'] = val
            continue

        # ── visible → visibility ────────────────────────────────────
        if key == 'visible':
            if val is False:
                result['visibility'] = 'hidden'
            # visible: true is the default – omit
            continue

        # ── dataSourceType → listboxType ────────────────────────────
        if key == 'dataSourceType':
            result['listboxType'] = val
            continue

        # ── rowsSource → dataSource ─────────────────────────────────
        if key == 'rowsSource':
            result['dataSource'] = val
            continue

        # ── alternateBackground → alternateFill ─────────────────────
        if key == 'alternateBackground':
            result['alternateFill'] = fix_color(val)
            continue

        # ── rowHeight number → "Npx" ────────────────────────────────
        if key == 'rowHeight':
            if isinstance(val, (int, float)):
                result['rowHeight'] = f'{int(val)}px'
            else:
                result['rowHeight'] = val
            continue

        # ── Listbox-level "header" object → headerHeight ────────────
        if key == 'header' and isinstance(val, dict) and obj_type == 'listbox':
            if 'height' in val:
                result['headerHeight'] = f"{val['height']}px"
            result['showHeaders'] = True
            continue

        # ── stroke handling ─────────────────────────────────────────
        if key == 'stroke':
            if has_textColor and obj_type not in ('rectangle', 'line'):
                # textColor wins for text color – skip old stroke
                # but infer border intent for buttons
                if not is_column:
                    if is_bare_hex(val) and obj_type == 'button':
                        result['borderStyle'] = 'solid'
                    elif val == 'none' and obj_type == 'button':
                        result['borderStyle'] = 'none'
                continue
            else:
                # Keep stroke, fix format
                if val == 'none':
                    result['stroke'] = 'transparent'
                else:
                    result['stroke'] = fix_color(val)
                continue

        # ── fill (fix color) ────────────────────────────────────────
        if key in ('fill', 'alternateFill'):
            result[key] = fix_color(val)
            continue

        # ── columns array ───────────────────────────────────────────
        if key == 'columns' and isinstance(val, list):
            result['columns'] = [fix_object(col, is_column=True) for col in val]
            continue

        # ── Column dataSource: Form.x[].prop → This.prop ───────────
        if key == 'dataSource' and is_column and isinstance(val, str) and '[].' in val:
            result['dataSource'] = 'This.' + val.split('[].', 1)[1]
            continue

        # ── Recurse into nested dicts (but not column headers) ──────
        if isinstance(val, dict) and key != 'header':
            result[key] = fix_object(val)
            continue

        # ── Default: keep as-is ─────────────────────────────────────
        result[key] = val

    # Ensure buttons have an explicit borderStyle
    if obj_type == 'button' and 'borderStyle' not in result:
        result['borderStyle'] = 'none'

    return result


def fix_form(data):
    """Fix the entire form JSON structure."""
    result = {}
    for key, val in data.items():
        if key == 'pages':
            pages = []
            for page in val:
                if page is None:
                    pages.append(None)
                else:
                    new_page = {}
                    for pk, pv in page.items():
                        if pk == 'objects' and isinstance(pv, dict):
                            new_objects = {}
                            for obj_name, obj_def in pv.items():
                                new_objects[obj_name] = fix_object(obj_def)
                            new_page['objects'] = new_objects
                        else:
                            new_page[pk] = pv
                    pages.append(new_page)
            result['pages'] = pages
        else:
            result[key] = val
    return result


# ── Main ────────────────────────────────────────────────────────────
if __name__ == '__main__':
    form_files = sorted(glob.glob(os.path.join(FORMS_DIR, '*/form.4DForm')))
    print(f'Found {len(form_files)} forms to fix.\n')

    for fpath in form_files:
        with open(fpath) as f:
            data = json.load(f)

        fixed = fix_form(data)

        with open(fpath, 'w') as f:
            json.dump(fixed, f, indent=2, ensure_ascii=False)
            f.write('\n')  # trailing newline

        name = os.path.basename(os.path.dirname(fpath))
        print(f'  ✓ {name}')

    print(f'\nDone – {len(form_files)} forms fixed.')
