# BAS Field Tools: project handoff

Context for picking this project up in a new chat. Paste this file, or point Claude at the repo and this file.

## Who / what
- **Owner:** Buddy, BAS technician at **Combustion Service & Equipment Co. (CS&E)**. Works on Schneider EBO (MP/RP controllers), Niagara, Trane, and KMC.
- **What:** browser-based field tools for the BAS team. Each tool is a single self-contained HTML file. Nothing to install; data stays on the user's device.
- **Repo:** `therisenbrady-glitch/bas-tools` (public, branch `main`)
- **Live site (GitHub Pages):** https://therisenbrady-glitch.github.io/bas-tools/, the landing page and the one link shared with coworkers.

## Working agreements
- **Push straight to `main`.** No branches or PRs.
- **Show a preview (screenshots) before committing visual redesigns.** Functional changes and fixes can go straight in.
- Keep each tool's README current. The landing page's **Manuals** tab renders the READMEs live.
- The session's GitHub access can push but **cannot delete branches**. Buddy does that in the GitHub UI.
- Commit trailer: `Co-Authored-By: Claude …` plus the session line.

## Repo layout
```
index.html                      Landing page: Tools tab + Manuals tab (renders the .md files below with marked 12.0.2)
manifest.webmanifest, assets/   Home-screen icons (BAS stripes), favicon
.nojekyll                       Pages serves .md files raw (needed for the Manuals tab)
point-checkout/checkouttool.html + README.md
device-scanner/devicescanner.html + README.md
vav-calculator/index.html + README.md
program-generator/index.html + README.md
network-map/index.html + README.md, network-map/scan/ (EBO-NetScan.ps1, Run EBO-NetScan.bat, README.txt, EBO-NetScan.zip of those three)
docs/workflow.md                Job workflow manual (install → programming → commissioning → closeout)
docs/phones.md                  Phone setup manual (Android/Chrome, Samsung Internet, iPhone/Safari, laptop)
docs/HANDOFF.md                 This file
```

### How the tool files are built
Each tool HTML in the repo = **page body** wrapped in:
- `<!doctype html>`, charset/viewport metas, a small reset (`[hidden]{display:none!important}` matters)
- `<link rel="apple-touch-icon" href="../assets/apple-touch-icon.png">` and favicon
- an `← All field tools` link (`href="../"`) as the first thing in `<body>`

The **claude.ai artifact** versions are the same body without that wrapper. To update an artifact from the repo file, strip everything up to and including the back-link line, and drop the closing `</body></html>`.

## Shared look
- Fonts: Barlow Condensed (display), IBM Plex Sans (body), IBM Plex Mono (data)
- Tokens: steel `#2f4a5e`, amber accent `#d98a10` (dark `#f0a22e`), readout panel `#17232d`, light bg `#eef1f3`; full dark-mode set via `prefers-color-scheme` and `[data-theme]`
- Header: amber left rule, mono eyebrow, CS&E logo top-right (transparent PNG, light and dark variants embedded as data URIs, swapped by `--logo-l` / `--logo-d` tokens)
- Toasts fixed at the bottom; save-and-share "tray" of 3 icon buttons
- Clear button (`.clr`) next to the project name: **three taps** (arm → confirm → erase), cancels on an outside tap or after 6 s

## Tools

### Point Checkout Tracker (`point-checkout/checkouttool.html`)
Point-to-point commissioning checklist.
- **Imports** (one **Import file** button, detects the type):
  1. **EBO XML** (`ObjectSet`): controllers = objects with an `*ApplicationProxy` child. Points: hardware I/O (`.point.*Input/Output`), VAV data (`.vav.BoxFlow` etc.), SmartX sensor channels, plus key software values (◦). Role from the custom-type child's DESCR (e.g. "Unit Ventilator").
  2. **Niagara `.bog`**: a zip of `file.xml` (`bajaObjectGraph`), unzipped in the browser with `DecompressionStream('deflate-raw')`. Device = any `p` with a `points` child whose type ends `PointDeviceExt`. Points = `c:*Point|*Writable` with `proxyExt/objectId`: all AI/AO/BI/BO/MI/MO, plus values matching NG_KEEP and not NG_SKIP. Labels look like `SaTmp — AI-11`. Model, serial, and ID come from `config/deviceObject`. Names decode `$xx` escapes.
  3. **Excel/CSV controller list** (SheetJS 0.18.5 from cdnjs): NAME / TYPE / DESCR headers.
  4. **Device Scanner export** (CSV with DEVICE ID + SERIAL columns, or JSON `format:'device-list'`): matches units by serial, then `normTag` (uppercase alphanumerics only), then a fallback by number (leading zeros, letters + trailing number, room number) onto unscanned units when the pairing is unique; fallback matches carry `dev.fuzzy` (the reason) until **Looks right** clears it or **Not this unit** removes the scan. Attaches `u.dev = {did, serial, model, mac, netmac}` and shows the **Scanned devices** panel (unmatched both ways). On an empty list it creates units instead.
  5. **Job JSON** (`format:'point-checkout'`)
- **Review import** panel: groups by controller model with per-group point list (**Points from file** or a template), and **Show all units** for per-unit checkboxes. Re-import skips existing tags. A unit created from a scan list with nothing checked takes real points from a later XML/.bog import.
- **Checkout:** type tabs (AHU/RTU/VAV/UV/FCU/EF/Other) with % and fail counts, a **Show** filter, PASS/FAIL/N/A per point (FAIL opens a note), **Pass all points** with **Undo** (`p.bulk` flag; manual edits clear it), add point, delete unit, **Device** line.
- **Outputs:** **Copy punch list**; **Save checkout CSV** (one row per controller, a section per type, with Device ID, Serial, %, counts, fail notes, last checked, and a column per point); **Export job** (JSON). Saves use `showSaveFilePicker` in Chrome/Edge top-level, the `downloads` capability on claude.ai, and an `<a download>` fallback.
- **Storage:** localStorage `pct-local-v1`; on claude.ai the `db` capability (collection `units`, doc `meta/project`).
- Templates: VAV, VAVC, AHU, RTU, FCU, UV, EF, BLANK.

### Device Scanner (`device-scanner/devicescanner.html`, ~1.7 MB)
Install-time master device list.
- **Reader:** zxing-cpp WebAssembly (`zxing-wasm` 3.1.4 reader, IIFE plus the base64 wasm inlined), with `@zxing/library` 0.21.3 as a JS fallback. Live camera uses its own getUserMedia loop (frame grab every 150 ms, full frame and center crop). Photo decode tries several scales and crops.
- **Schneider label format** (Data Matrix, light-on-dark, no separators):
  `S/N: TD253550311RP-C-12A-F-24VMAC: 00:50:06:29:E5:AABT: F0:FD:45:73:E5:9F` → serial, model, network MAC, BT MAC. Parsed by `MODEL_RE` plus key splitting.
- **Flow:** Start ID and Step, then each save gets the next ID (editable; numbering continues from the last saved). Name auto-increments (VAV-7 → VAV-8). Duplicate ID blocks saving; a duplicate serial or MAC warns.
- **Outputs:** **Export for checkout** CSV (`NAME, TYPE, DESCR, DEVICE ID, SERIAL, BT MAC, NETWORK MAC, SCANNED`), **Export job** / **Import job** JSON.
- **Storage:** localStorage `dsc-local-v1`; on claude.ai `db` (collection `devices`, doc `meta/job`).
- Live camera needs https (Pages). On the claude.ai link, use Photo / image. It's untested whether WebAssembly runs there; if not, the JS fallback can't read these labels.

### VAV Field Calculator (`vav-calculator/index.html`)
Tabs: Airflow (CFM = K√ΔP, ideal K = 4005 × area), K-Factor correction, Reheat (BTU/h, GPM, kW/amps), Inlets table. Flags for ΔP < 0.03″, FPM out of range, error ±5/±10 %, LAT > 95 °F. Inputs in localStorage `vav-calc-v1`; the **Reset** button uses the three-tap pattern.

### EBO Program Generator (`program-generator/index.html`, ~345 KB)
Canned EBO 7.1 program set for one controller. Unit types: CV AHU (MP-C, from Bower Hill), VAV AHU (MP-C, from the Airport AHUs), VAV box (MP-V: settings and points merged into Schneider's stock VAV application, plus an optional `Components/PerimRad` radiation component; Buddy decided 2026-10-14 that Schneider's stock VAV programs are NOT copied into the generator or the public site), Unit Vent (RP-C/MP-C, from the 51 identical Bower Hill RP-C-12A UVs; default terminals are their wiring), Boiler (AS-P with SmartX IO, from the Bower Hill HWS; saves an IO file for the IO Bus and a Complete file for `Application/<unit>`). Exhaust fan was built from the Airport job and then removed at Buddy's request (2026-10-14); its template is kept in the shared-folder source as ef.js, not built into the page. RTU and FCU are disabled until Buddy supplies a finished program set. Buddy's direction: keep the types few, add options to an existing type when a new job brings a variation, and share point names and loops across types (CHW valve `ClgVlvPos` + cooling loop on CV AHU, VAV AHU and Unit Vent; DX `Dx1Cmd..` with Func_Staging on VAV AHU and Unit Vent, the CV AHU keeps its Bower Hill 2-stage DX program).
- **Input:** a WorkStation export of one MP controller (`bacnet.mpx.udt.MPC18B` etc.); for the Boiler, the AS-P server name and a module list (SmartX terminals are named like `S05 UI 3`). Reads terminals from IO Resources/Onboard IO, the SpaceLogic sensor on the Sensor Bus, and what's already in `Application`. VAV box stock points (`stock` in vav.js) are matched to their current terminals (`pointTerm`) and written as minimal merge objects; stock enums (RhtSelect, FanSelect, sensor enables) come from stockenums.json. A built-in sample MP-C-18B is for looking around only (saving blocked).
- **Options:** per type, listed in program-generator/README.md. **Add a point** (page step 4) adds hand-entered hardware points or Parameters values (`opts.custom`: name, descr, kind ai/vi/di/do/ao/av/bv, unit, def, lo/hi) with relinquish defaults; **Points only** (`opts.pointsOnly`, Buddy 2026-10-15) exports only the field points with their alarms and trends: plan() drops every non-point from `reg`, returns `values: []`, and keeps only alarms whose source is a point; no Programs folder. **Return air fallback** (`opts.rafb`, flag `RAFB`, Buddy 2026-10-20): shared `ROOM_FB.check` in ahu.js; `AHU.src.roomtemp` is reused by VAHU (and later RTU). Out of range 30 s -> RmTmpAlm (auto-clear) and RmTmpCtl = RaTmp, no offset, fan on or off. VAHU programs read `{RM}` (RmTmpCtl or RmTmp). A select choice can carry a predicate (third array element) that hides it unless other options allow it; `fixOpts` falls back to the default. **Starter graphic** (`opts.graphic`, default on, Buddy 2026-10-20): gfx.js builds one TGML graphic (`Graphics/<unit>`, AS-P `<unit>/Graphics`) with every `reg` object as the team's standard value box (template `GFX_BOX` in gfxbox.js, copied from the team's Setpoints graphic; `</` escaped so it can sit inside the page's script). Force binds: `.OutOfService` for MP inputs, `.Priority8` for MP outputs and values, none on the AS-P. Skipped for the VAV box (stock app has its own graphic). Not import-tested in EBO yet.
- **EBO Script labels:** `Open`, `Closed`, `Run` and `Idle` are reserved (Buddy hit or flagged each, 2026-10-21 to 10-23), and other state words (`Off`, `Enabled`, `Disabled`, `Alarm`, `Running`, `Fail`) are treated the same; Check stops on them. The scratch checker tres.js (drafts src) tests every label, variable, function and Arg name in every generated program against a reserved list; add new words there. Labels use a prefix instead (`DprClosed`, `StOff`, `RadOn`). Generated output also arrives uncompiled: functions, then programs, must be opened, checked and saved before an MP download works.
- **Engine:** program templates with `#if/#elif/#else/#endif` blocks on option flags and `@MODE` lines that expand to numbered modes and text. `{KEY}` vars in program source for per-instance programs (exhaust fan N). Team functions Func_PID, Func_Ratio, Func_Staging, Func_TwoPosition, plus Func_Runtime, Func_Ramp and Func_Range from Buddy's newer boiler set (funcs.js; a function is emitted only when a program declares it, so Func_Ramp and Func_Range sit unused for now). Trends: `opts.trendSel` maps a name to true/false; names not in it fall back to the template's trend list (`trendDef`); candidates (`trendCands`) are every own point/value except stock, ext and csv ones. The page keeps picks per type in `trendBy`. Trend log units (Buddy 2026-10-28): an MP `bacnet.mpx.TrendLog` with no unit charts in deg C, so `LogDeviceObjectProperty` carries `Unit=` from the logged object (AS-P `trend.TLog` already set it on LogPoint/LogArray); plan() flags any trended `*Tmp*` object with no unit, and any deg C unit (`trendUnitMiss`). Selects can carry `needs(opts)`; fixOpts resets them to the default and the page hides them when it fails. Gas heat (Buddy asked 2026-10-15; no team program, built from published gas furnace/RTU sequences): `GAS` and `GAS_SRC` at the top of ahu.js are shared by AHU and VAHU (heat choices gasmod/gas1/gas2, flags GAS/GASMOD/GAS2/GALM). The AHU program writes `HtgReq` where HW writes HwVlvPos (0 on freezestat/smoke/fan-off), and ORs `HtgFanReq` into SaFanCmd for the post-purge; Prog_GasHeat mode numbers come from `GAS.vars(F)`. Boiler run hours use Func_Runtime with counters set to 1 in Init so stored hours survive a restart while off. Templates can set `root` (one component folder with stock-style subfolders) and `ext` values (bind to the stock application, never created); a template's `model` regex flags the wrong controller. Objects already on the controller are reused, not re-created; existing program names are flagged as clashes.
- **IO:** inputs lowest Ub, analog outputs Uc/AO then highest Ub, relays DO; editable per point, with 0-10/2-10/10-0/10-2 V signal.
- **Output:** `<unit> Complete - import.xml`, copying the AHU-A Complete export structure (EBO 7.1.2.171): folders Alarms, Functions, Inputs, Numerics, Occupancy, Outputs, Parameters, Programs, Trends; program CodeFile = base64(gzip(PEObject XML with base64 CRLF code)); type names `udt.<26>.<32>` from SHA-256 of the object path. Plus a plain-text README.txt. Not yet test-imported in EBO.
- **Storage:** localStorage `ebo-gen-v1`, options/terminals/signals/setpoint edits and hand-added points kept per type (`optsBy`, `ioBy`, `sigBy`, `editsBy`, `customBy`), plus the global `pointsOnly` export choice; version 1 storage migrates into CV AHU. Saves the same way as the checkout tracker.
- Not yet import-tested in EBO: any type. The VAV box merge-by-name behavior and the Boiler two-file import especially need a first test. Low limit switch: On = tripped (confirmed by Buddy 2026-10-14).
- The page source (engine, AHU template, UI) was built in a session scratchpad; the repo file is the built output and is the master now.

### Network Map (`network-map/index.html` + `network-map/scan/`)
Maps a controller network: which controllers exist, their addresses, and the cable order. Built 2026-10-28 from Buddy's EBO-NetScan draft. Neither part has been run on a job yet.
- **Scan kit** (`scan/`, served for download; the zip must be rebuilt whenever the .ps1, .bat, README.txt or network-map/index.html change, and the download links carry `?v=<hash of the scan files>` so Pages' 10-minute cache can't serve an old kit; files are stored with CRLF, see `.gitattributes`): PowerShell 5.1, read-only. Who-Is (listens on 47808 if free), then ReadProperty(device 4194303, object-identifier) to .1-.254, then batched ReadProperty of name/model/vendor/firmware/app version/location (routed MS/TP devices through their router with DNET/DADR; replies matched on sender + invoke ID), MACs from Get-NetNeighbor. Outputs `Results/Devices_<stamp>.csv` (IP, DeviceID, RoutedNet, RoutedMac, MAC, Name, Model, Vendor, Firmware, AppVer, Location). With Wireshark: tshark `-f stp` for 6 s on `\Device\NPF_{guid}`, appends `RSTP readings.csv` (Time, Label, NeighborMAC, LaptopIP, stp.bridge.hw/prio, stp.root.hw/prio, stp.root.cost, stp.port, stp.flags.port_role, HopsFromRoot, PortRole, NeighborName, NeighborIP). Cost per hop 200000, or 19 when the cost is under 1000.
- **One double-click (Buddy 2026-10-28):** a browser can't send BACnet or capture RSTP, so the kit carries `Network Map.html` (the page with its back link pointed at the site; added to the zip by the build, not stored in scan/). At the end of every run the script injects `{made, files:[{name,text}]}` (newest Devices CSV + RSTP readings.csv) into `<script id="netscanData">null</script>`, writes `Results/Network map.html` and opens it (`-NoMap` skips). The page loads embedded data on start, hides the kit card, and keeps `edits`/`ring` from localStorage across reopenings.
- **Page:** loads any mix of Devices CSVs, RSTP readings and a Device Scanner export (adds serials by network MAC/device ID), detected by header. Readings match devices by exact MAC (eth.src, then bridge MAC), then a MAC within 2 when only one device is that close (flagged ≈MAC). Unmatched RSTP neighbors become "Unknown controller" nodes. Newest reading per controller sets its hop; the newest root MAC is the root. Two at a hop go on sides A/B (guessed, tagged SIDE?; a hand-set side pushes the other across). Ring/Open toggle (defaults to Open chain; Ring only when a reading's port role is Alternate, Buddy asked about open chains 2026-10-28). Hand edits (hop, side) per node key in `edits`. Inline SVG map, firmware outliers per model, routed MS/TP list, readings list; saves CSV and PNG. Storage localStorage `netmap-v1`. Sample data is generic (no job names).

## claude.ai artifacts (private to Buddy)
- Point Checkout Tracker: https://claude.ai/artifact/NoNDzjxJUspFrsHFmKt2nS (db, user `profile`, downloads)
- Device Scanner: https://claude.ai/artifact/XpZxtAW31REAoKXhESVBaG (db, user, downloads)
- VAV Field Calculator: https://claude.ai/artifact/5NBKAPPdc9fNVqHKaWMtRF

GitHub Pages is the primary way coworkers use the tools.

## Test data used during development
- EBO network export: Bower Hill Elementary, 81 controllers (63 RPC12A UVs/FCUs, 12 MPV7A + 3 MPV9A VAVs, 2 MPC18B AHUs, MPC36A KitchenPanel)
- Niagara `UVs.bog`: 53 RPC12A UVs (station "Jeff_Tech_V2")
- Real controller label photo (RP-C-12A-F-24V, S/N TD253550311)

## Open items / ideas
- Confirm the scanner's WebAssembly reader works on the claude.ai link (or just use Pages).
- Name matching between the scanner and EBO/Niagara relies on consistent naming. Fuzzier matching (e.g. room number) could help.
- MS/TP trunk planner: drafted, then shelved by Buddy (2026-10-14). Do not ship unless he asks.
- More unit types for the Program Generator, once Buddy supplies finished program sets.
- Ideas mentioned but not built: sensor/signal converter (4–20 mA, 0–10 V, thermistor curves), psychrometric quick-calc, fan/pump affinity calc.
