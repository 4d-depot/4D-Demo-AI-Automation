#!/usr/bin/env python3
"""Add "method": "_BtnHandler" to every button in all 6 form.4DForm files."""

import json
import pathlib

FORMS_DIR = pathlib.Path(__file__).resolve().parent.parent / "Project" / "Sources" / "Forms"

count = 0
for form_dir in sorted(FORMS_DIR.iterdir()):
    fp = form_dir / "form.4DForm"
    if not fp.exists():
        continue
    data = json.loads(fp.read_text("utf-8"))
    modified = False
    for page in data.get("pages", []):
        if not isinstance(page, dict):
            continue
        for obj_name, obj in page.get("objects", {}).items():
            if obj.get("type") == "button" and "method" not in obj:
                obj["method"] = "_BtnHandler"
                modified = True
                count += 1
                print(f"  {form_dir.name}/{obj_name}")
    if modified:
        fp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", "utf-8")
        print(f"  -> saved {form_dir.name}/form.4DForm")

print(f"\nDone — {count} buttons updated.")
