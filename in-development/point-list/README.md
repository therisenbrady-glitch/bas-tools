# Point List Generator

Turns a picture of a controller wiring diagram, or an EBO controller export, into a clean I/O diagram and point list: what lands on each terminal, its type, the field device, and the point name.

Open it at **Field tools → Point List Generator**, or `point-list/` on the site.

## 1. Load the picture (or skip to the EBO export below)
- **Take photo** (phone camera), **Choose picture**, drag a picture onto the box, or paste one.
- Best results: a screenshot from the submittal PDF, or a photo taken straight on with the controller and all its wire labels in the frame and no glare.

## 2. Read it with Claude
- Tap **Read diagram with Claude**. It takes a minute or two.
- **Claude version (no key):** open the tool from the link on the page (*Claude version of this tool*). It reads with your own Claude account and counts toward your plan's usage, like sending Claude a message with a picture. The first time, Claude asks you to allow it. It can't print; use **Save picture** or the CSV.
- **On the tools site:** reading needs your own **Claude API key** (from console.anthropic.com → API keys, billed separately from a Claude subscription, roughly 10 to 20 cents a read). Open **Claude API key**, paste it, and tap **Save key**. It's stored only in that browser on that device; **Forget key** removes it.
- Either way only the picture goes to Claude. Nothing goes to the tools site.
- No Claude at all? Skip this step and type the points into the table.

## Or start from an EBO export
- In WorkStation, right-click an MP or RP controller (or a whole AS-P / server) and **Export**. Open the .xml with **Open EBO XML**.
- The table fills with every hardware point on its terminal (name, description, AI/AO/DI/DO from the point type, sensor kind, output range like 2-10 V and reverse acting), the SmartX room sensor on its COM port with what it senses, and every unused terminal as a spare.
- A file with several controllers shows **Controller in this file** to switch between them, and **Save every controller (CSV)** saves one point list for all of them.
- Points with no terminal set are left out (the message names them). SmartX IO modules on an AS-P aren't read yet.
- Exports don't carry device tags or wire numbers; type those in if you want them on the diagram.

## 3. Check the table
- One row per terminal: **Terminal** (as printed on the controller: Ub 1, UI 3, DO 1, COM A), **Wire #** (the screw terminal numbers, signal/return like 19/20), **Type** (AI, AO, DI, DO, Sensor bus, Network, Power), **Device** (field tag like TS1, VA1), **Point name**, **Description**, **Signal / notes**.
- Rows Claude wasn't sure about are amber with a **Check** button. Look at the picture (tap it to enlarge), fix the row, then tap **Check** to clear it.
- A row with no point name is a **spare**.
- Typing a point name like `SaTmp` or `HwVlvPos` fills an empty Type and Description for you.
- **Add a terminal** adds a row; **✕** then **Delete?** removes one; **Sort by terminal** puts them in order.
- If a read replaced a table you'd already filled, **Undo, put my old table back** restores it.

## 4. The diagram
- Drawn from the table as you edit. Terminals are grouped by block (universal I/O, digital outputs, communication, power) on the controller, each wired to a card for its device.
- Arrows show signal direction: inputs point into the controller, outputs point out. Spares are dashed.
- Colors: AI blue, DI purple, AO green, DO amber, sensor bus and network slate, power red.
- On a phone the diagram switches to one column.

## 5. Save
- **Print or save PDF** (tools site only): the diagram plus the point list table on one sheet (choose "Save as PDF" in the print dialog).
- **Save picture**: a PNG of the diagram.
- **Save point list (CSV)**: `UNIT, CONTROLLER, TERMINAL, WIRE #, TYPE, DEVICE, NAME, DESCR, SIGNAL / NOTES`.
- **Save job file** / **Open job file**: a JSON with the picture and the table, to finish on another device.
- Clear (top right, three taps) erases the picture and table.

## Notes
- Terminal and point names follow the Program Generator's conventions (Ub 1, DO 1; SaTmp, SaFanCmd), so a point list can be checked against what the generator expects.
- Always check the result against the field wiring before landing wires. Claude reads most diagrams well, but bent and parallel wires on a photo can be misread.
- The page saves your work in the browser (localStorage `plg-local-v1`; the key in `plg-key-v1`).
