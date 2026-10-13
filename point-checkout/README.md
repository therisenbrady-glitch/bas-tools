# Point Checkout Tracker

A point-to-point commissioning checklist for BAS jobs. Load a controller list (or a full EBO network export), work through each unit marking points **PASS / FAIL / N/A**, and send the fails out as a punch list.

---

## Two ways to use it

| | Live link (claude.ai) | Standalone file (`checkouttool.html`) |
|---|---|---|
| Where it saves | Shared online store | The browser on that device only |
| Multiple techs | Everyone sees the same list live, with who checked each point and when | Each person has their own copy. Hand jobs off with Export / Import |
| Who can open it | People it's shared with from the page's Share menu | Anyone you send the file to |
| Internet | Required | Only needed the first time you import an Excel/CSV file |

**Standalone tips**
- Open it in Chrome, Edge, or Safari. Phone file previews (Files app, email attachments) often show the page but the buttons won't work.
- Clearing browser data or using a private window erases the saved job. Export regularly.

---

## Starting a job

The buttons at the top are in two rows: **Import file** and **Add unit** start work, and the row below (**Copy punch list**, **Save checkout CSV**, **Export job**) gets results out.

Tap **Import file** and pick a file. Three kinds are accepted:

### 1. EBO XML export (recommended)
Export the network or controller folders from WorkStation as `.xml`.

- Every controller under the network becomes a unit (detected by its Application folder).
- The model comes from the device type (MPV7A, MPV9A, RPC12A, MPC18B…).
- The unit's role comes from the controller description, or from the description on the custom application object inside it (for example "Unit Ventilator", "Fan Coil Unit").
- Names like `Conference B146 (VAV-7)` become tag **VAV-7** at location **Conference B146**.

Points are pulled from the controller's actual database:

| Included | Examples |
|---|---|
| Hardware I/O from Inputs, Outputs, and component Points folders | `SaFanCmd — Supply Fan Command`, `RhtPos — Reheat Position` |
| VAV box data | Box Flow, Velocity Pressure, Damper Command, Flow Setpoint, Discharge Air Temp, Effective Reheat Command |
| Room sensor channels (SmartX / SpaceLogic) | Temperature, CO2, Humidity, Occupancy |
| Key software values, marked **◦** | Room temp, airflow min/max/reheat setpoints, occupancy, enables, alarms, setpoints |

Left out: trends, programs, functions, graphics, alarm objects, ports/Modbus/room bus, consumer values, PID tuning, limits, differentials, delays, and calculated values.

### 2. Excel or CSV controller list
For a sheet with one row per controller. The importer looks for these column headers:

| Purpose | Header names it recognizes |
|---|---|
| Unit name (required) | NAME, TAG, UNIT, EQUIPMENT, DEVICE |
| Controller model (optional) | TYPE, MODEL, CONTROLLER |
| Location (optional) | DESCR, DESCRIPTION, LOCATION, SERVES, ROOM |

A spreadsheet has no points in it, so each group gets a standard template (see below).

### 3. Job file (`.json`)
A file made with **Export job**. It restores everything, including statuses and notes.

### The review step
Before anything is added, the **Review import** panel shows controllers **grouped by model**. Each row is a model, not a single unit; the count shows how many units are in it. For each group you can:
- Keep **Points from file** (XML only), or switch to a standard template.
- Untick the group to leave it out.
- Tap **Show all units** to list every unit in the group (scrolls inside the panel) and untick individual units to skip them.

Then tap **Add N units**. A counter at the bottom of the screen shows progress.

**Re-importing is safe:** tags already on the list are skipped, so you can import an updated export, or a second network, without wiping existing checkoffs.

---

## Doing the checkout

- **Type tabs** across the top (All, AHU, VAV, UV, FCU, Other…) split the job by unit type. Each tab shows its count, % complete, and fails. The progress panel below reflects the selected tab.
- **Show** (All / Open / Fails / Done), just above the unit list, filters within the current tab.
- Tap a unit to open its point list, then mark each point:
  - **PASS**: verified
  - **FAIL**: opens a note field. Describe the problem; it goes on the punch list.
  - **N/A**: not used on this unit (for example Rht2Cmd on a single-stage box)
  - Tap the same button again to clear it.
- **Add point** at the bottom of a unit adds a custom point. **Delete unit** asks for a second tap to confirm.
- **Add unit** adds a single unit by hand using a standard template.

### Standard templates
Used for spreadsheet imports, hand-added units, or when you override "Points from file":
VAV reheat, VAV cooling only, AHU, RTU, FCU, Unit ventilator, Exhaust fan, Blank.

---

## Getting results out

- **Save checkout CSV** saves every point on the job as a spreadsheet, one row per point, ready for Excel or a closeout package. Columns: Project, Unit, Type, Model, Location, Point, Description, Point kind (hardware / software value / room sensor), Status (PASS, FAIL, N/A, Open), Note, Checked by, Checked at. Rows are sorted by unit type, then tag. The example unit is left out.
- **Copy punch list** copies every FAIL across the whole job (not just the current tab) as a numbered list with unit, location, point, and your note, ready to paste into an email or text.
- **Export job** saves the entire job (project name, units, every status and note) as a dated `.json` file.

**Choosing where files save:** in Chrome or Edge on a computer, **Export job** and **Save checkout CSV** open a save window so you can pick the folder and file name. Other browsers (Safari, Firefox, phones) and the claude.ai link save to the normal Downloads location. To be asked every time in those, turn on the browser's "Ask where to save each file" setting.

### Handing off between techs (standalone file)
1. Tech A taps **Export job** and sends the `.json` file.
2. Tech B taps **Import file** and picks it.
   - Units with a matching tag are **replaced** by the imported version.
   - New tags are added.

Split work by unit (for example floor 2 vs floor 3). If two people edit the same unit separately, whichever copy is imported last wins.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| "No controllers found in that XML" | The export layout isn't recognized. Send the file over so the importer can be tuned. |
| Units came in under the wrong tab | The type is read from descriptions. Delete those units and re-import, or add them by hand with the right type. |
| A spreadsheet won't load in the standalone file | The Excel reader needs internet the first time. Connect and try again. |
| "Saved X of Y" after an import | Some units didn't save. Run Import again with the same file; only the missing ones are added. |
| "This link is view-only" | You have view access to the live link. Ask the owner for edit access. |
| Buttons don't respond on a phone | You're likely in a file preview. Open the file in Safari or Chrome instead. |

---

## Files

- `checkouttool.html`: the full tracker. No install needed.
- `checkout-<project>-<date>.json`: job files made with Export job.
- `checkout-<project>-<date>.csv`: checkout spreadsheets made with Save checkout CSV.
