# bas-tools
Handful of useful tools for our BAS work

**Start here (one link for everything):** https://therisenbrady-glitch.github.io/bas-tools/

Direct links:
- Checkout tracker: https://therisenbrady-glitch.github.io/bas-tools/point-checkout/checkouttool.html
- Device scanner: https://therisenbrady-glitch.github.io/bas-tools/device-scanner/devicescanner.html
- VAV calculator: https://therisenbrady-glitch.github.io/bas-tools/vav-calculator/

On an iPhone, open a link in Safari and tap **Share → Add to Home Screen** to get an app icon. The device scanner's live camera only works from these links.

Each tool is also a single HTML file you can download and open in Chrome, Edge, or Safari. Nothing to install.

| Tool | What it does |
|---|---|
| [Point Checkout Tracker](point-checkout/checkouttool.html) | Point-to-point commissioning checklist. Imports an EBO XML network export or an Excel/CSV controller list, splits units into tabs by type, tracks PASS / FAIL / N/A per point, and copies out a punch list. See its [README](point-checkout/README.md). |
| [Device Scanner](device-scanner/devicescanner.html) | Scan controller label codes (camera or photo), name each device, and auto-number BACnet device IDs into a job's master device list. Exports a CSV the checkout tracker imports. See its [README](device-scanner/README.md). |
| [VAV Field Calculator](vav-calculator/) | Airflow from velocity pressure and K-factor, K-factor balance correction, reheat coil load (hot water GPM or electric kW/amps), and a round inlet reference table. See its [README](vav-calculator/README.md). |

## Tips
- On a phone, open the file in Safari or Chrome. File previews from email or the Files app often show the page with buttons that don't work.
- The tracker saves to the browser on that device. Use **Export job** / **Import file** to hand a job to someone else, and export regularly so clearing browser data doesn't wipe a job.
