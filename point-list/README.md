# Point List Generator

Turns a picture of a controller wiring diagram into a clean I/O diagram and point list: what lands on each terminal, its type, the field device, and the point name.

Open it at **Field tools → Point List Generator**, or `point-list/` on the site.

## 1. Load the picture
- **Take photo** (phone camera), **Choose picture**, drag a picture onto the box, or paste one.
- Best results: a screenshot from the submittal PDF, or a photo taken straight on with the controller and all its wire labels in the frame and no glare.

## 2. Read it with Claude
- Tap **Read diagram with Claude**. It takes about a minute.
- This needs your own **Claude API key** (from console.anthropic.com → API keys). Open **Claude API key**, paste it, and tap **Save key**. The key is stored only in that browser on that device. **Forget key** removes it.
- Each read costs roughly 10 to 20 cents on the key's account.
- Only the picture is sent, straight from your browser to Anthropic's API. Nothing goes to the tools site.
- No key? Skip this step and type the points into the table.

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
- **Print or save PDF**: the diagram plus the point list table on one sheet (choose "Save as PDF" in the print dialog).
- **Save picture**: a PNG of the diagram.
- **Save point list (CSV)**: `UNIT, CONTROLLER, TERMINAL, WIRE #, TYPE, DEVICE, NAME, DESCR, SIGNAL / NOTES`.
- **Save job file** / **Open job file**: a JSON with the picture and the table, to finish on another device.
- Clear (top right, three taps) erases the picture and table.

## Notes
- Terminal and point names follow the Program Generator's conventions (Ub 1, DO 1; SaTmp, SaFanCmd), so a point list can be checked against what the generator expects.
- Always check the result against the field wiring before landing wires. Claude reads most diagrams well, but bent and parallel wires on a photo can be misread.
- The page saves your work in the browser (localStorage `plg-local-v1`; the key in `plg-key-v1`).
