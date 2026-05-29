#!/usr/bin/env python3
"""Full refactor of all 6 forms to comply with 4d.forms.instructions.md:
1. Add "method": "method.4dm" at form level
2. Replace project method "_BtnHandler" on buttons with local object methods
3. Create local object method .4dm files for each button group
"""
import json
import pathlib
import os

FORMS_DIR = pathlib.Path("Project/Sources/Forms")

# For each form, define button groups and their handler function names
FORM_BUTTONS = {
    "Home": {
        "btn_events": "btnEventsEventHandler",
        "btn_inbox": "btnInboxEventHandler",
        "btn_simulate": "btnSimulateEventHandler",
    },
    "EventList": {
        "btn_refresh": "btnRefreshEventHandler",
        "btn_filter_all": "btnFilterAllEventHandler",
        "btn_filter_confirmed": "btnFilterConfirmedEventHandler",
        "btn_filter_quote": "btnFilterQuoteEventHandler",
        "btn_filter_weather": "btnFilterWeatherEventHandler",
    },
    "EventDetail": {
        "btn_back": "btnBackEventHandler",
        "btn_ai_analyze": "btnAiAnalyzeEventHandler",
        "btn_ai_action1": "btnAiAction1EventHandler",
        "btn_ai_action2": "btnAiAction2EventHandler",
        "btn_ai_action3": "btnAiAction3EventHandler",
        "btn_ai_action4": "btnAiAction4EventHandler",
    },
    "EmailInbox": {
        "btn_filter_all": "btnFilterAllEventHandler",
        "btn_filter_unread": "btnFilterUnreadEventHandler",
        "btn_filter_quote": "btnFilterQuoteEventHandler",
        "btn_filter_modif": "btnFilterModifEventHandler",
        "btn_filter_info": "btnFilterInfoEventHandler",
    },
    "EmailDetail": {
        "btn_back": "btnBackEventHandler",
        "btn_ai_analyze": "btnAiAnalyzeEventHandler",
        "btn_ai_action1": "btnAiAction1EventHandler",
        "btn_ai_action2": "btnAiAction2EventHandler",
        "btn_ai_action3": "btnAiAction3EventHandler",
        "btn_ai_action4": "btnAiAction4EventHandler",
    },
    "DemoSendEmail": {
        "btn_tpl_quote": "btnTplQuoteEventHandler",
        "btn_tpl_modification": "btnTplModificationEventHandler",
        "btn_tpl_ambiguous": "btnTplAmbiguousEventHandler",
        "btn_send": "btnSendEventHandler",
        "btn_cancel": "btnCancelEventHandler",
    },
}

for form_name, buttons in FORM_BUTTONS.items():
    form_dir = FORMS_DIR / form_name
    fp = form_dir / "form.4DForm"
    data = json.loads(fp.read_text("utf-8"))

    # 1. Add form-level method declaration
    data["method"] = "method.4dm"

    # 2. Process each button: replace global method with local object method
    for page in data.get("pages", []):
        if not isinstance(page, dict):
            continue
        for obj_name, obj in page.get("objects", {}).items():
            if obj.get("type") == "button" and obj_name in buttons:
                handler_name = buttons[obj_name]
                local_method_file = f"obj{obj_name}.4dm"
                obj["method"] = local_method_file

                # 3. Create the local object method file
                method_content = f"Form.{handler_name}(FORM Event.code)\n"
                method_path = form_dir / local_method_file
                method_path.write_text(method_content, "utf-8")
                print(f"  Created {form_name}/{local_method_file} -> Form.{handler_name}()")

    # Save form
    fp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", "utf-8")
    print(f"  Saved {form_name}/form.4DForm\n")

print("Done — all forms refactored.")
