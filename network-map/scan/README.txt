EBO-NetScan - controller network discovery
==========================================

What it does (read-only, nothing is written to any controller):
  1. Finds every BACnet/IP controller on the subnet you're plugged into
     (Who-Is broadcast + a ReadProperty to each address .1-.254).
  2. Reads each one's BACnet device ID, name, model, vendor, firmware and
     location, and gets its MAC from the laptop's ARP table. Devices behind a
     BACnet router (MS/TP under an AS-P) are read through the router.
  3. If Wireshark is installed, listens 6 seconds for RSTP frames and records
     which controller you're plugged into and how many hops it is from the
     RSTP root. Each run adds a line to "RSTP readings.csv".

Then load the CSVs into the Network Map page on the field tools site
(https://therisenbrady-glitch.github.io/bas-tools/network-map/) to draw the
map: every controller, its address, and the cable order.

Needs:
  - Windows PowerShell 5.1 or newer (built into Windows 10/11). Nothing to install.
  - Wireshark with Npcap, for the RSTP part only (https://www.wireshark.org).
    Run as administrator if the RSTP capture comes back empty and Npcap was
    installed "admin only".
  - The laptop on the controller network (e.g. a spare controller Ethernet
    port). A fixed IP on that subnet is fine, or let DHCP give you one.
  - EBO WorkStation closed, since it holds UDP port 47808. The scan still
    runs if it's open, but may miss some Who-Is replies.

How to use:
  1. Unzip the kit somewhere on the laptop (not inside the zip).
  2. Double-click "Run EBO-NetScan.bat". If you have Wi-Fi and Ethernet
     both connected it asks which one to use.
  3. Type where you're plugged in when asked (e.g. "AHU-A port 2").
  4. Results go to the Results folder next to the script:
       Devices_<date>_<time>.csv  - one row per controller, one file per scan
       RSTP readings.csv          - one row per RSTP neighbor heard, every run
  5. To work out the chain order, move the laptop to other controllers and run
     with only the RSTP part (faster). From a command prompt in this folder:
       "Run EBO-NetScan.bat" -SkipScan -Label "Room 113 port 2"
     or
       powershell -ExecutionPolicy Bypass -File .\EBO-NetScan.ps1 -SkipScan -Label "Room 113 port 2"

Where to take readings:
  - RSTP only tells you about the controller you're plugged into.
  - At the end of a chain, plug into the controller's free port.
  - In the middle of a chain, put a small unmanaged switch inline between two
    controllers and plug the laptop into the switch.
  - A reading at every second or third controller is usually enough; the map
    shows the hops nobody has read yet as dashed boxes.

Reading the RSTP results:
  - NeighborName / NeighborMAC: the controller the laptop is plugged into.
  - stp.root.cost: cost from that controller to the RSTP root. On 100 Mb links
    each hop usually adds 200000, so HopsFromRoot = cost / 200000. If the
    numbers come out tiny (19, 38, 57...), the controllers use the old cost
    of 19 per hop; the script and the map divide by 19 then.
  - PortRole "Alternate/Backup" on a port means the loop is blocked there,
    i.e. the chain is wired as a ring and that's where it closes.
  - Controllers with the same root ID are on the same RSTP domain.

Notes:
  - Only the /24 the laptop is on is scanned (x.x.x.1 to 254) unless you pass
    -Subnet, -From and -To.
  - Controllers on DHCP get addresses in no particular order, so the IP order
    doesn't follow the wiring. The RSTP readings do.
  - A controller that never answers may have BACnet/IP turned off or be on a
    different UDP port.
  - Not tested on site yet. If something errors, send the red text.

Options: -Label "text"  -Subnet 10.110.210  -From 1 -To 254  -SkipScan  -SkipStp  -StpSeconds 6  -OutDir <folder>
