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

Tap **Import file** and pick a file. Five kinds are accepted:

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

**Hot water system on the AS-P.** HWS panels usually run on the AS-P with SmartX IO expansion modules, so the AS-P is handled differently from the MP controllers. The AS-P itself can only be backed up, not exported, and the importer can't read a backup. So export two files: select the modules under **IO Bus** and export them, then export the **HWS** folder under Application. Import both and the importer builds one unit called **HWS** (or **Hot Water System**, after the folder's name), model **AS-P**:

- Every point on the AS-P's IO modules is listed with its module slot and channel, for example `Blr1Ena — Boiler 1 Enable (Slot03 DO 1)` or `HwSTmp — HW Supply Temp To Building (Slot05 UI 4)`.
- Software values come from the folder named `HWS` or `Hot Water System`: enables, setpoints, lead selections, fails, alarms, hand status, occupancy and modes, marked **◦**. Run hours, pump and boiler request values, and the Programs, Functions, Trends and Graphics folders are left out.
- An IO-only export gives the unit with just its IO points; an HWS-folder-only export gives just the values. Import both and they merge into the same unit.
- The AS-P itself, script programs, functions and graphics never show up as units of their own.

### 2. Niagara export (`.bog`)
In Workbench, right-click the BACnet device folder (or the whole BacnetNetwork) and choose **Export** to save a `.bog` file, then import it here. Each device that has a **Points** extension becomes a unit:

- **Name** comes from the device's name in the station (`$20` and other escapes are decoded).
- **Model** comes from the device type, such as `RPC12A`. The full model and **serial number** are read from the device object and shown on the unit's **Device** line, along with the device ID when the export has it.
- **Points** are the proxy points under Points:
  - Every **input and output** (AI, AO, BI, BO, MI, MO), listed inputs first, with its BACnet object, for example `SaTmp — AI-11`.
  - **Key values**, marked **◦**: setpoints, alarms, occupancy, mode, room temp, economizer and OA minimum, heating/cooling available.
  - Left out: resets, limits, lockouts, min/max, delays, tuning, and description strings.
- The type tab is guessed from the device name and its template description, so `UV …` goes to the UV tab.

The `.bog` is a zip file. The tracker opens it directly in current Safari, Chrome, and Edge. On an older browser, rename it to `.zip`, unzip it, and import the `file.xml` inside.

### 3. Excel or CSV controller list
For a sheet with one row per controller. The importer looks for these column headers:

| Purpose | Header names it recognizes |
|---|---|
| Unit name (required) | NAME, TAG, UNIT, EQUIPMENT, DEVICE |
| Controller model (optional) | TYPE, MODEL, CONTROLLER |
| Location (optional) | DESCR, DESCRIPTION, LOCATION, SERVES, ROOM |

A spreadsheet has no points in it, so each group gets a standard template (see below).

### 4. Device Scanner list (`devices-….csv` or `.json`)
The file made with **Export for checkout** (or **Export job**) in the Device Scanner. Scanning happens at install and checkout comes later, so this works in either order:

- **Units already on the list** (for example from the EBO XML): each scanned device is matched to a unit by name. The match ignores spaces, dashes, and case, so `vav 12` matches `VAV-12`. Its device ID, model, serial, and both MACs are attached. The ID shows in the unit's header, and the full details show in a **Device** line when the unit is open.
- **Names that don't match:** a device whose name doesn't match any unit gets a second try by number, but only onto units that have no scan yet, and only when exactly one device and one unit pair up:
  1. Same name once leading zeros are ignored: `VAV 0101` matches `VAV-101`.
  2. Same letters and trailing number: `VAV-14` matches `VAV-2-14`.
  3. Same room or number: `FCU 405` matches `FCU-5` whose location is `Room 405`, and `Box 301` matches `VAV-301`.

  These are guesses, so the unit gets a **Check scan** tag, and the open unit says how it was matched with **Looks right** and **Not this unit** buttons. **Not this unit** takes the scan off and moves the device back to **Scanned but not on the list**. Importing the same scan list again keeps the tag until someone confirms it.
- **Empty list:** the scanned devices become units through the normal review step, grouped by model, with template points.
- **EBO XML imported after a scan list:** units that came from the scan, with nothing checked yet, take the real points from the export and keep their scanned details.

A **Scanned devices** panel then shows what matched, plus lists to check before closeout:
- **Matched by number, check these**: each fallback match as `scanned name → unit`, with why it matched and the same **Looks right** / **Not this unit** buttons.
- **Scanned but not on the list**: usually a name typed differently in the scanner. Fix it there and import again, or tap **Add as new units**.
- **On the list but not scanned**: controllers nobody scanned yet.

The checkout CSV includes **Device ID** and **Serial** columns.

### 5. Job file (`.json`)
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

- **Type tabs** across the top (All, AHU, VAV, UV, FCU, HWS, Other…) split the job by unit type. Each tab shows its count, % complete, and fails. The progress panel below reflects the selected tab.
- **Show** (All / Open / Fails / Done), just above the unit list, filters within the current tab.
- Tap a unit to open its point list, then mark each point:
  - **PASS**: verified
  - **FAIL**: opens a note field. Describe the problem; it goes on the punch list.
    Next to the note is a **Non-critical / Critical** toggle. Every fail starts as non-critical; tap it to mark the fail **Critical** (it turns solid red). A unit with critical fails shows a red **N critical** tag in its header. Changing the point off FAIL clears the rating.
  - **N/A**: not used on this unit (for example Rht2Cmd on a single-stage box)
  - Tap the same button again to clear it.
- **Pass all points** (top of an open unit) marks every *open* point on that unit PASS in one tap. Points already marked FAIL or N/A are left alone.
  - The button turns solid and changes to **Undo pass all**. Tapping it sets only the bulk-passed points back to open.
  - Any point you change by hand after a pass all is yours, and Undo won't touch it.
- **Add point** at the bottom of a unit adds a custom point. **Delete unit** asks for a second tap to confirm.
- **Add unit** adds a single unit by hand using a standard template.
- **Clear job** (next to the project name) erases every unit and point to start a new job. It takes three taps: **Clear job → Clear job? → Erase N units**. Tapping anywhere else, or waiting a few seconds, cancels it. Use **Export job** first if you might need the old job.

### Standard templates
Used for spreadsheet imports, hand-added units, or when you override "Points from file":
VAV reheat, VAV cooling only, AHU, RTU, FCU, Unit ventilator, Exhaust fan, Hot water system, Blank.

---

## Getting results out

- **Save checkout CSV** saves a spreadsheet with **one row per controller**, ready for Excel or a closeout package:
  - At the top: project name, save time, and job totals (units, % complete, pass / fail / N/A / open).
  - Then a section per unit type (AHU, VAV, UV, FCU, …), each with its own header row.
  - Each row: Unit, Location, Model, % complete, Pass, Fail, N/A, Open, Fail notes (every failed point with its note, critical ones first and marked CRITICAL), Last checked (time and who), then one column per point showing PASS, FAIL, or N/A.
  - A blank point cell means not checked yet; **—** means that point isn't on that unit. The example unit is left out.
- **Copy punch list** copies every FAIL across the whole job (not just the current tab) as a numbered list with unit, location, point, and your note, ready to paste into an email or text. Critical fails come first under a **CRITICAL** heading, then the rest under **NON-CRITICAL**; numbering runs straight through both.
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
