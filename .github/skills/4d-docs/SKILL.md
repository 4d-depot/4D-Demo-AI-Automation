---
name: 4d-docs
description: "URL index for 4D form object documentation. Load to get the fetch URL for any form object type, property group, or event. USE FOR: finding the right doc page before writing or editing a .4DForm file."
---

# 4D Documentation Lookup

Fetch: `https://developer.4d.com/docs/FormObjects/<slug>`  
Read the **Supported Properties** section. Do NOT guess — always fetch if uncertain.

## Form Objects

| Object | JSON `type` | Slug |
|--------|------------|------|
| Button | `button` | `buttonOverview` |
| Check box | `checkbox` | `checkboxOverview` |
| Combo box | `combo` | `comboBoxOverview` |
| Drop-down list | `dropdown` | `dropdownListOverview` |
| Group box | `groupBox` | `groupBox` |
| Hierarchical list | `hierarchicalList` | `listOverview` |
| Input | `input` | `inputOverview` |
| List box | `listbox` | `listboxOverview` |
| Picture button | `pictureButton` | `pictureButtonOverview` |
| Picture pop-up | `picturePopupMenu` | `picturePopupMenu` |
| Plug-in area | `pluginArea` | `pluginAreaOverview` |
| Progress indicator | `progressIndicator` | `progressIndicator` |
| Radio button | `radio` | `radioButtonOverview` |
| Rectangle | `rectangle` | `rectangleOverview` |
| Spinner | `spinner` | `spinner` |
| Splitter | `splitter` | `splitterOverview` |
| Static text | `text` | `staticPicture` |
| Subform | `subform` | `subformOverview` |
| Tab control | `tab` | `tabControl` |
| Web area | `webArea` | `webArea` |
| 4D Write Pro | `writeProArea` | `writeProAreaOverview` |

## Properties Reference

| Topic | Slug |
|-------|------|
| All properties | `propertiesReference` |
| Action | `propertiesAction` |
| Coordinates & Sizing | `propertiesCoordinatesAndSizing` |
| Data Source | `propertiesDataSource` |
| Display | `propertiesDisplay` |
| Entry | `propertiesEntry` |
| Object (name, type, class…) | `propertiesObject` |
| Resize | `propertiesResizingOptions` |
| Text | `propertiesText` |
| Text & Picture | `propertiesTextAndPicture` |

## Events

| JSON key | 4D constant |
|----------|------------|
| `onLoad` | `On Load` |
| `onUnload` | `On Unload` |
| `onDataChange` | `On Data Change` |
| `onClick` | `On Clicked` |
| `onSelectionChange` | `On Selection Change` |
| `onAfterSort` | `On After Sort` |
| `onResize` | `On Resize` |
| `onActivate` / `onDeactivate` | `On Activate` / `On Deactivate` |

Full list: `https://developer.4d.com/docs/Events/onActivate`

## Search 4D documentation

Exploring 4D documentation with https://developer.4d.com/docs/search?q=searched_terms

## Search 4D forum

To be used when troubleshooting a difficult case, for past experiences.
Exploring 4D forum with https://discuss.4d.com/search?q=searched_terms
Search results provide urls like https://discuss.4d.com/t/topic-slug/topic_id where the most important info is the topic id. The following URL is equivalent https://discuss.4d.com/t/topic_id
