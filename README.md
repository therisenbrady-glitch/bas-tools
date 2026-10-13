# bas-tools
Handful of useful tools for our BAS work

Each tool is a single HTML file. Download it and open it in Chrome, Edge, or Safari. Nothing to install.

| Tool | What it does |
|---|---|
| [Point Checkout Tracker](point-checkout/checkouttool.html) | Point-to-point commissioning checklist. Imports an EBO XML network export or an Excel/CSV controller list, splits units into tabs by type, tracks PASS / FAIL / N/A per point, and copies out a punch list. See its [README](point-checkout/README.md). |
| [VAV Field Calculator](vav-calculator/) | Airflow from velocity pressure and K-factor, K-factor balance correction, reheat coil load (hot water GPM or electric kW/amps), and a round inlet reference table. See its [README](vav-calculator/README.md). |

## Tips
- On a phone, open the file in Safari or Chrome. File previews from email or the Files app often show the page with buttons that don't work.
- The tracker saves to the browser on that device. Use **Export job** / **Import file** to hand a job to someone else, and export regularly so clearing browser data doesn't wipe a job.
