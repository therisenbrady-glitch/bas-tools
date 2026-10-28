# Network Map

Maps an EBO controller network when you don't know the comm layout: which controllers are on it, their addresses, and the order they're cabled in. It has two parts:

1. **The scan kit**, a PowerShell script you run on a Windows laptop plugged into the controller network. It saves the results as CSV files. It has to run on the laptop, because only a computer on that network can reach the controllers.
2. **The Network Map page**, which draws the map. The kit carries its own copy, so when a scan finishes the map opens in the laptop's browser already loaded, with no internet needed. The page on this site (`network-map/index.html`) does the same from the saved CSVs, for later or on another computer. Your files stay on your device.

The scan is read-only. It only asks controllers who they are (BACnet Who-Is and ReadProperty) and never writes to one.

> Not tested on a job yet. If the script shows red error text, send it in.

## Why a scan is needed
- An EBO export has no IP, MAC or BACnet device ID, only the folder tree, ports and bindings.
- MP and RP controllers have a built-in 2-port switch, so EBO can't see the cable order.
- With DHCP on, IP order doesn't follow the wiring either.
- RSTP does know the order. Each controller's RSTP frames say how far it is from the root bridge, so readings at a few spots along the chain put the controllers in order.

## 1. Get the scan kit
On the Network Map page, tap **Download scan kit (.zip)** and unzip it on the laptop. It holds:

| File | What it is |
|---|---|
| `Run EBO-NetScan.bat` | Double-click this. It runs the script without changing the PC's execution policy. |
| `EBO-NetScan.ps1` | The scan. PowerShell 5.1, built into Windows 10 and 11, nothing to install. |
| `Network Map.html` | The kit's copy of the map page. The script fills it with the results and opens it. Keep it next to the script. |
| `README.txt` | The same instructions as this section, for the laptop. |

For the cable order you also need **Wireshark with Npcap** ([wireshark.org](https://www.wireshark.org)). The device list works without it.

## 2. Run the scan
1. Plug the laptop into the controller network (a spare controller port is fine). A fixed IP on that subnet works, or let DHCP give you one.
2. Close EBO WorkStation. It holds UDP port 47808; the scan still runs if it's open but may miss some replies.
3. Double-click **Run EBO-NetScan.bat**. If Wi-Fi and Ethernet are both connected it asks which one to use.
4. When asked, type where you're plugged in, for example `AHU-A port 2`.

It sends a Who-Is, then asks every address from .1 to .254 for its device ID, then reads each controller's name, model, vendor, firmware and location. Controllers behind a BACnet router (MS/TP under an AS-P) are read through the router. MACs come from the laptop's ARP table.

When it's done, the map opens in the browser. Results go in a **Results** folder next to the script:
- `Network map.html`: the map with the results inside, rebuilt and reopened on every run (the newest device scan plus every RSTP reading)
- `Devices_<date>_<time>.csv`: one row per controller, one file per scan
- `RSTP readings.csv`: one row per RSTP reading, added to on every run

Use a fresh copy of the kit (or `-OutDir`) for each job, so one job's readings don't land on another's map.

## 3. Take RSTP readings for the cable order
RSTP only tells you about the controller you're plugged into, so take readings at a few spots:
- **End of a chain:** plug into the controller's free port.
- **Middle of a chain:** put a small unmanaged switch inline between two controllers and plug the laptop into the switch.
- To move around without re-scanning, run only the RSTP part from a command prompt in the kit folder:
  `"Run EBO-NetScan.bat" -SkipScan -Label "Room 113 port 2"`

Each reading reopens the map with that controller placed, and your side and hop edits carry over. A reading every second or third controller is usually enough. The map shows the hops nobody has read yet as dashed boxes.

If the RSTP capture comes back empty and Npcap was installed "admin only", run the .bat as administrator.

### Script options
| Option | Use |
|---|---|
| `-Label "text"` | Where the laptop is plugged in |
| `-Subnet 10.110.210` | Scan this subnet instead of the laptop's own (first three octets) |
| `-From 1 -To 254` | Host range to scan |
| `-SkipScan` | Only take the RSTP reading |
| `-SkipStp` | Only do the BACnet scan |
| `-StpSeconds 6` | How long to listen for RSTP frames |
| `-OutDir "path"` | Save results somewhere else |
| `-NoMap` | Don't open the map at the end |

## 4. Load saved results on the site
The kit opens the map by itself. To look at a job later or on another computer, open the Network Map page on this site, tap **Choose files** (or drop the files on the box) and pick the newest `Devices_…csv` and `RSTP readings.csv`. You can add files any time:
- A later Devices file updates the list (matched by device ID, then MAC).
- New readings place more controllers.
- A Device Scanner **Export for checkout** CSV adds serial numbers, matched by network MAC or device ID.

**Try sample data** shows a made-up network so you can look around. **Clear** (top right) removes the loaded files and your edits after three taps. The map is kept in the browser on that device until you clear it.

## Reading the map
- The **RSTP root** is at the top. Each row below it is one cable hop from the root, worked out from the root path cost (200000 per 100 Mb hop, or 19 per hop on controllers that use the old short costs).
- A ring or a root in the middle of a chain has **two sides**, A and B, one for each direction out of the root. Two controllers at the same hop go on opposite sides. The readings can't say which side is which, so those get a **SIDE?** tag: tap one and pick its side, and the other at that hop moves across.
- **Ring / Open chain** sets whether the two ends join. It starts on Ring when a reading saw an Alternate port (the blocked backup link where a ring closes) or when there are two sides.
- A **dashed box** is a hop with no reading yet. At least one controller sits there.
- **Unknown controller** is an RSTP neighbor whose MAC isn't in the device list. Load a newer scan, or it may have BACnet/IP turned off.
- **≈MAC** means the reading matched a MAC one or two off the controller's own (its bridge MAC can differ slightly from its IP MAC).
- Box colors: server (AS-P/AS-B), MP-C, MP-V, RP-C, other.

Tap any controller (on the map, in **Not placed yet**, or in the list) to see its details. There you can type a **Hop** to place it by hand, for example from a cable you can see, and set its **Side**. **Back to the reading** undoes your edits for that controller.

The page also warns when readings don't add up: more than two controllers at one hop, a controller reading 0 hops that isn't the root, or readings that name different root bridges.

## Device list and saving
The **Device list** is in cable order (root, side A out, side B back), then the controllers not placed yet. An amber dot next to a firmware version means it differs from most controllers of that model on this network. Devices behind BACnet routers are listed by MS/TP network underneath, and every RSTP reading is listed at the bottom.

- **Save device list (CSV):** order, name, IP, device ID, model, vendor, firmware, MAC, hop, side, last reading label, and serial (if a scan list was loaded), plus the routed MS/TP devices.
- **Save map picture (PNG):** the map as an image, for the job folder or a punch list.
