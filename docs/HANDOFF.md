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
- Ideas mentioned but not built: MS/TP trunk planner, sensor/signal converter (4–20 mA, 0–10 V, thermistor curves), psychrometric quick-calc, fan/pump affinity calc.
