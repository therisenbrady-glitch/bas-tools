# Job workflow

How the three tools fit together on a job, from install to closeout.

| Stage | Tool | You end up with |
|---|---|---|
| Install | Device Scanner | Master device list: names, device IDs, models, serials, MACs |
| Programming | (EBO WorkStation) | Controllers set up with those names and IDs |
| Commissioning | Point Checkout Tracker | Every point checked PASS / FAIL / N/A |
| Closeout | Point Checkout Tracker | Checkout CSV, punch list, job file |

The VAV Field Calculator is for any time you're balancing or troubleshooting a box.

## 1. Install: build the device list
1. Open the **Device Scanner** and enter the project name.
2. Set **Start ID** (for example `12001`) and **Step** (usually `1`).
3. At each controller, tap **Scan code** and point at the Data Matrix on the label. Serial, model, Bluetooth MAC, and network MAC fill in automatically.
4. Name the device **the same way it will be named in EBO** (`VAV-7`, `Room 113`, `AHU-C`) and add the location. Tap **Save & scan next**.
5. When you're done, or at the end of each day:
   - **Export for checkout** saves the CSV the checkout tool reads.
   - **Export job** saves a backup you can reopen on any device.

> If the camera won't start (for example on the claude.ai link), use **Photo / image**. It reads the code from a picture of the label.

## 2. Programming
Use the scanner's CSV (it opens in Excel) for the device ID, name, and MAC of each controller while you set up the database in EBO.

## 3. Commissioning: load the job into the tracker
1. Export the network: in EBO WorkStation as **XML**, or in Niagara Workbench as a **.bog** (right-click the BACnet device folder → Export).
2. Open the **Point Checkout Tracker**, enter the project name, and tap **Import file**. Pick the XML or .bog.
3. In **Review import**, check the point list for each controller model (**Points from file** is usually right), then tap **Add units**.
4. Tap **Import file** again and pick the scanner's `devices-….csv`.
5. The **Scanned devices** panel shows:
   - how many scanned devices matched a unit (by name, ignoring spaces, dashes, and capitalization)
   - **Scanned but not on the list**: usually a name that's different in the scanner. Fix it there and import again.
   - **On the list but not scanned**: controllers nobody scanned at install

Matched units show their device ID in the header and a **Device** line (model, serial, MACs) when opened.

> Imported the scan list first? That's fine. Import the XML afterwards and the scanned units take on the real points.

## 4. Doing the checkout
- Use the type tabs (AHU, VAV, UV, FCU…) and **Show** (All / Open / Fails / Done) to work through the job.
- Mark each point **PASS**, **FAIL** (add a note), or **N/A**.
- **Pass all points** passes every open point on a unit. **Undo pass all** reverses only those.

## 5. Closeout
- **Save checkout CSV**: one row per controller, grouped by type, with device ID, serial, % complete, fail notes, and every point's status.
- **Copy punch list**: every FAIL with its note, ready to paste into an email or text.
- **Export job**: the full job file for the record or the next tech.

## Working as a team
- Jobs are saved in the browser on each device. They aren't shared automatically.
- To hand a job over, tap **Export job** and send the file. The other tech uses **Import file** (tracker) or **Import job** (scanner).
- Split the work by unit (for example floor 2 vs floor 3). When the same unit is imported twice, the last import wins.

## Phone setup
- Open the tools from the Field Tools page: in **Safari** on iPhone, in **Chrome** on Android. Don't open them from an email attachment or file preview.
- Add each tool you use to your home screen: **Share → Add to Home Screen** on iPhone, **⋮ → Add to home screen** on Android.
- Export your jobs regularly as a backup.
- Step-by-step help with the camera, downloads, and importing files is in the [Phone setup](phones.md) manual.

## Starting a new job
In the tracker and the scanner, **Clear job** / **Clear list** (next to the project name) erases everything on that device so you can start fresh. It takes three taps so it can't happen by accident. Export the old job first.
