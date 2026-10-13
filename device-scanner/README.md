# Device Scanner

Builds the master device list for a job site during install. Scan the code on each controller's label, give it a name, and it gets the next BACnet device ID automatically. Export the list straight into the **Point Checkout Tracker**.

It's one HTML file (`devicescanner.html`). The code reader is built in, so it works offline.

## Setting up a job
1. Enter the project name.
2. Set **Start ID**, the first device ID for this job (for example `12001`), and **Step**, how much each new device adds (usually `1`).
3. **Next device ID** shows what the next device will get.

## Adding devices
| Button | What it does |
|---|---|
| **Scan code** | Opens the camera. Point it at the QR or Data Matrix code on the controller label, and it reads it as soon as it's in focus. |
| **Photo / image** | Take a picture of the label or pick one from your photos. On an iPhone this offers both. |
| **Type in** | Add a device by hand. |

After a code is read, a **New device** form opens with:
- **Device name.** It's suggested from the last device (`VAV-7` → `VAV-8`) and is editable.
- **Device ID.** The next ID, also editable. Later devices count on from whatever you saved last.
- **Location / serves** (optional). It shows as the unit's location in the checkout tool.
- **Model, Serial number, Bluetooth MAC, Network MAC.** These are filled in from the code. On Schneider RP and MP controller labels, all four are read automatically. The full text of the code is under **Scanned code text** if anything needs fixing.

**Save & scan next** saves and goes straight back to the camera (or the photo picker) for the next controller.

### Checks
- A device ID that's already used, or outside 0–4194302, blocks saving.
- If a scanned serial or either MAC matches a device already on the list, you get a warning and a link to open that one instead.
- Devices that share an ID, serial, or MAC are highlighted in the list.

Tap any device in the list to edit or delete it.

**Clear list** (next to the project name) erases every device and resets the start ID to 1001, for starting a new job. It takes three taps: **Clear list → Clear list? → Erase N devices**. Tapping anywhere else, or waiting a few seconds, cancels it. Use **Export job** first if you might need the old list.

## Getting the list out
| Button | Saves |
|---|---|
| **Export for checkout** | A CSV with columns `NAME, TYPE, DESCR, DEVICE ID, SERIAL, BT MAC, NETWORK MAC, SCANNED`. In the checkout tool, tap **Import file** and pick it. If the job is already loaded from the EBO XML, each device is matched to its unit by name, and you get a list of anything that didn't match. If the checkout list is empty, the devices become units. It also opens in Excel. |
| **Export job** | A `.json` file of this device list, to hand off or continue on another device. |
| **Import job** | Loads a job file. Devices with the same serial (or MAC, or name) are updated, and the rest are added. |

In Chrome or Edge on a computer, exports let you choose the folder. Elsewhere they go to Downloads.

## Camera notes
- The live camera needs the tool opened from a web address (`https://`), such as GitHub Pages. Opened from the claude.ai link, or as a file on a computer, use **Photo / image** instead.
- On an iPhone, Safari asks for camera permission the first time.
- For small codes, fill the guide box with the code and hold steady. A little light helps a lot.

## Label formats
**Schneider controller labels** (the small black label with a Data Matrix code, e.g. RP-C-12A-F-24V) store everything run together in one line:

```
S/N: TD253550311RP-C-12A-F-24VMAC: 00:50:06:29:E5:AABT: F0:FD:45:73:E5:9F
```

The scanner splits that into Serial `TD253550311`, Model `RP-C-12A-F-24V`, Network MAC `00:50:06:29:E5:AA`, and Bluetooth MAC `F0:FD:45:73:E5:9F`. The handwritten location on the label isn't in the code, so type it into **Location / serves**.

The reader (zxing-cpp, built in) handles light-on-dark Data Matrix codes like these, as well as QR, Aztec, PDF417, Code 128, and Code 39. For other labels it picks out fields from `key: value` text, URLs with query values, JSON, and GS1 serial fields. Anything it can't sort out stays in the scanned text for you to copy into the right field.

## Naming tip
Name devices the same way they're named in EBO (for example `VAV-7`, or `Room 113` for the unit ventilators). The checkout tool matches scanned devices to units by name, ignoring spaces, dashes, and case.
