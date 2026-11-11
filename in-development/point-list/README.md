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

## Or start from a TAC I/NET board
For I/NET sites (7716 and 7756 PCUs). The layout follows Joe's I/NET primer and the TCON096 (7716) and TCON127 (7756) pinouts.
- Under **Or start from a TAC I/NET board**, pick the **Board** and, on a 7716, the **Expansion card** on port P3 (none, UI/DO 8+8, 4+4, 8 UI or 8 DO, UI/AO, or RTD). Tap **Fill the terminals**.
- Every terminal gets a row with its point address and screw terminals: base inputs UI-1 to 8 (0000-0007, TB1/TB2), relays 1 to 8 (0000-0007, TB6/TB7), card inputs 0100-0107, card relays 0100-0107 (TBX2/TBX3), UI/AO card AOs 3100-3103 (TBX3). On a 7756: upper inputs and relays as on the 7716, lower inputs UI-1 to 24 (0100-0307 on TB1A to TB3B), triacs 1 to 8 (0100-0107, TB6), AOs 1 to 8 (3100-3107, TB7).
- Type the **I/NET link** and **Station** in step 02. The table shows the full address LL SS CC PP; type CC PP for any point you add by hand.
- The table has **I/NET type** (AI, DI, DA, PI, AO, DO, DC, DM) and **I/NET name** columns. An AO on a relay or triac is noted as **PWM** (on a 7716, an AO at 01xx is a UI/DO relay running PWM, not an analog card).
- Changing the board or card later keeps the names you typed on the same addresses.
- **Not I/NET** (step 02) turns the addresses off again.
- **EBO export of an I/NET site:** **Open EBO XML** also reads I/NET DCUs (`inet.dcu.Dcu7716`, `Dcu7756`, `Dcu7798`). It lists **Ext points only** (Int and Ind are counted and left out), places each on its terminal from PointNumber (= controller CC) and BitOffset (= point PP), uses PointAddr as the I/NET name, and reads link and station from the DCU. A **7798** has no I/O of its own: it's a sub-LAN controller with MR controllers under it, so its Ext points are listed by MR (the CC of the address is the MR's sub-LAN address) without terminals for now. The 7716 card is guessed from the addresses (31xx = UI/AO card, outputs at 01xx = UI/DO card). HOA switch feedback (bit offsets 08/09) and points with no terminal go in **Other Ext points**. A DM point is marked **Check**, since it isn't settled yet whether DM sits on an input or an output. *The XML reader hasn't been tried on a real I/NET export yet (the backup reader has).*
- **I/NET controller saves (DCUnnnn.SAV):** **Open EBO XML, backup or SAV** also takes SAV files, one or several at once (each becomes a controller in the picker). The page reads every point's address, type, class and I/NET name from the file and lists the Ext points on their terminals. The board (7716 or 7756) is read from the file; a 7716's expansion card is worked out from the addresses. SAV files don't store the link number, so it's taken from the file name (DCU0307 = link 03, station 07); type it in step 02 if the name doesn't carry it. Checked against EBO: two DCUs matched their backup point for point, and three more matched the 91 Ext points Joe verified. A file that isn't a real controller save (some on the share are pictures or fragments) is refused by name. Ind point names come from the SAV, so they can differ from a name changed later in EBO.
- **Wiring picture of an I/NET board:** Claude also reads printed I/NET point addresses and types. When the controller is a 7716 or 7756 (or an I/NET board is already picked), what it reads is placed onto the board's terminal map, so every address and spare is listed.
- I/NET saves: the **point list CSV** is in Joe's order: ADDRESS, I/NET NAME, TYPE, then unit, board, IN/OUT, terminal, wire #, device, description and notes, sorted by board, then inputs, then outputs. Addresses are written so Excel keeps the leading zeros. Print shows the same columns.
- **EBO backup (.xbk) of an I/NET site:** **Open EBO XML, backup or SAV** also takes the AS backup file. The page unpacks it and reads the I/NET DCUs straight from its database (nothing is uploaded), with a **Controller in this file** picker and **Save every controller (CSV)** like a server export. Checked on a real I/NET site backup: all 50 Ext points on a 7756 and a 7716 with a UI/AO card landed on their terminals. Backups are read for I/NET DCUs only; for MP/RP controllers use a WorkStation export.

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
