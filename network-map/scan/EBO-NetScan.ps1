<#
EBO-NetScan.ps1  -  find every BACnet/IP controller on the local subnet and,
if Wireshark is installed, read the RSTP neighbor where the laptop is plugged in.

Read-only: it only sends Who-Is and ReadProperty requests. Nothing is written
to any controller.

Run (from the folder this file is in):
    Run EBO-NetScan.bat                      (double-click; asks for a label)
or
    powershell -ExecutionPolicy Bypass -File .\EBO-NetScan.ps1 -Label "AHU-A port 2"

Options:
    -Label     Where the laptop is plugged in (saved with the RSTP reading).
    -Subnet    First three octets to scan, e.g. 10.110.210. Default: the laptop's own.
    -From/-To  Host range to scan. Default 1..254.
    -SkipScan  Only take the RSTP reading (for moving between controllers).
    -SkipStp   Only do the BACnet scan.
    -OutDir    Where results go. Default: a "Results" folder next to this script.
    -NoMap     Don't open the map when it's done.

When it finishes it writes "Network map.html" in the Results folder (a copy of
the kit's "Network Map.html" with the results inside) and opens it in the
browser. No internet needed.
#>
param(
    [string]$Label   = "",
    [string]$Subnet  = "",
    [int]   $From    = 1,
    [int]   $To      = 254,
    [switch]$SkipScan,
    [switch]$SkipStp,
    [int]   $StpSeconds = 6,
    [string]$OutDir  = "",
    [switch]$NoMap
)

$ErrorActionPreference = "Stop"
if (-not $OutDir) { $OutDir = Join-Path $PSScriptRoot "Results" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

# ---------------------------------------------------------------- network adapter
$upIdx = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object { $_.InterfaceIndex })
$ipInfo = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" -and $_.PrefixOrigin -ne "WellKnown" -and $upIdx -contains $_.InterfaceIndex }
if ($Subnet) {
    $ipInfo = $ipInfo | Where-Object { $_.IPAddress -like "$Subnet.*" }
}
$ipInfo = @($ipInfo)
if ($ipInfo.Count -gt 1) {
    Write-Host "More than one network connection:"
    for ($k = 0; $k -lt $ipInfo.Count; $k++) {
        Write-Host ("  {0}) {1}  ({2})" -f ($k + 1), $ipInfo[$k].IPAddress, $ipInfo[$k].InterfaceAlias)
    }
    $pick = Read-Host "Which one is plugged into the controllers? (number)"
    $ipInfo = $ipInfo[[int]$pick - 1]
} else { $ipInfo = $ipInfo | Select-Object -First 1 }
if (-not $ipInfo) { throw "No usable IPv4 address found. Plug into the controller network (or pass -Subnet)." }
$localIp = $ipInfo.IPAddress
$adapter = Get-NetAdapter -InterfaceIndex $ipInfo.InterfaceIndex
if (-not $Subnet) { $Subnet = ($localIp -split "\.")[0..2] -join "." }
if ($ipInfo.PrefixLength -lt 24) {
    Write-Host "Note: subnet is /$($ipInfo.PrefixLength); only $Subnet.$From-$To is scanned." -ForegroundColor Yellow
}
Write-Host "Laptop: $localIp on '$($adapter.Name)' ($($adapter.MacAddress))"

# ---------------------------------------------------------------- BACnet helpers
$PropIds = [ordered]@{
    "Name"     = 77    # object-name
    "Model"    = 70    # model-name
    "Vendor"   = 121   # vendor-name
    "Firmware" = 44    # firmware-revision
    "AppVer"   = 12    # application-software-version
    "Location" = 58    # location
}

# ReadProperty of a device object. $dnet/$dadr route it through a BACnet router
# (e.g. an AS-P) to an MS/TP device; $dadr is hex bytes like "0a".
function New-ReadProperty([int]$invokeId, [int]$instance, [int]$propId, $dnet = $null, [string]$dadr = "") {
    $oid = (8 -shl 22) -bor ($instance -band 0x3FFFFF)
    $apdu = [byte[]](0x00, 0x05, ($invokeId -band 0xFF), 0x0C,
        0x0C, (($oid -shr 24) -band 0xFF), (($oid -shr 16) -band 0xFF), (($oid -shr 8) -band 0xFF), ($oid -band 0xFF),
        0x19, $propId)
    if ($dnet) {
        $mac = @($dadr -split ":" | Where-Object { $_ } | ForEach-Object { [Convert]::ToByte($_, 16) })
        $npdu = [byte[]](@(0x01, 0x24, (($dnet -shr 8) -band 0xFF), ($dnet -band 0xFF), $mac.Count) + $mac + @(0xFF))
    } else {
        $npdu = [byte[]](0x01, 0x04)
    }
    $len = 4 + $npdu.Length + $apdu.Length
    return [byte[]](@(0x81, 0x0A, (($len -shr 8) -band 0xFF), ($len -band 0xFF)) + $npdu + $apdu)
}

$WhoIs = [byte[]](0x81, 0x0B, 0x00, 0x08, 0x01, 0x00, 0x10, 0x08)

# Returns @{ Ip; Snet; Sadr; Apdu } or $null. Ip is set only for a Forwarded-NPDU
# (the original sender behind a BBMD).
function Split-Bvlc([byte[]]$p) {
    if ($p.Length -lt 6 -or $p[0] -ne 0x81) { return $null }
    $i = 4; $orig = $null
    if ($p[1] -eq 0x04) {                        # Forwarded-NPDU carries the original address
        $i = 10; $orig = "{0}.{1}.{2}.{3}" -f $p[4], $p[5], $p[6], $p[7]
    }
    elseif ($p[1] -ne 0x0A -and $p[1] -ne 0x0B) { return $null }
    if ($p[$i] -ne 0x01) { return $null }
    $ctl = $p[$i + 1]; $i += 2
    if ($ctl -band 0x80) { return $null }        # network-layer message
    $snet = $null; $sadr = $null
    if ($ctl -band 0x20) { $dlen = $p[$i + 2]; $i += 3 + $dlen }
    if ($ctl -band 0x08) {
        $snet = ($p[$i] -shl 8) + $p[$i + 1]; $slen = $p[$i + 2]
        $sadr = ($p[($i + 3)..($i + 2 + $slen)] | ForEach-Object { $_.ToString("x2") }) -join ":"
        $i += 3 + $slen
    }
    if ($ctl -band 0x20) { $i += 1 }             # hop count
    if ($i -ge $p.Length) { return $null }
    return @{ Ip = $orig; Snet = $snet; Sadr = $sadr; Apdu = [byte[]]$p[$i..($p.Length - 1)] }
}

# Decode one application-tagged value at $a[$i]; returns the value as text
function Read-AppValue([byte[]]$a, [int]$i) {
    $tag = $a[$i] -shr 4; $len = $a[$i] -band 0x07; $i++
    if ($len -eq 5) {
        $len = $a[$i]; $i++
        if ($len -eq 254) { $len = ($a[$i] -shl 8) + $a[$i + 1]; $i += 2 }
    }
    switch ($tag) {
        7 {   # character string
            $enc = $a[$i]
            # copy into a real byte[]: an empty or one-byte slice from an if-expression
            # unrolls to $null or a single byte in PowerShell
            $bytes = [byte[]]::new([Math]::Max(0, $len - 1))
            if ($len -gt 1) { [Array]::Copy($a, $i + 1, $bytes, 0, $len - 1) }
            if ($enc -eq 0) { return [Text.Encoding]::UTF8.GetString($bytes) }
            if ($enc -eq 4) { return [Text.Encoding]::BigEndianUnicode.GetString($bytes) }
            return [Text.Encoding]::GetEncoding("ISO-8859-1").GetString($bytes)
        }
        12 {  # object identifier
            $v = ([uint32]$a[$i] -shl 24) + ([uint32]$a[$i + 1] -shl 16) + ([uint32]$a[$i + 2] -shl 8) + [uint32]$a[$i + 3]
            return "{0},{1}" -f ($v -shr 22), ($v -band 0x3FFFFF)
        }
        2 {   # unsigned
            $v = 0; for ($k = 0; $k -lt $len; $k++) { $v = $v * 256 + $a[$i + $k] }; return "$v"
        }
        default { return "" }
    }
}

# ComplexACK for ReadProperty -> value text; Error/Reject/Abort -> $null
function Read-RpAck([byte[]]$apdu) {
    if ($apdu.Length -lt 8 -or $apdu[0] -ne 0x30 -or $apdu[2] -ne 0x0C) { return $null }
    $i = 3
    $i += 1 + ($apdu[$i] -band 0x07)             # context 0: object id
    $i += 1 + ($apdu[$i] -band 0x07)             # context 1: property id
    if (($apdu[$i] -band 0xF8) -eq 0x28) { $i += 1 + ($apdu[$i] -band 0x07) }   # context 2: array index
    if ($apdu[$i] -ne 0x3E) { return $null }
    try { return Read-AppValue $apdu ($i + 1) } catch { return $null }   # an odd reply never stops the scan
}

# Send a batch of requests and collect replies for $waitMs. Returns list of @{Ip; Port; Data}
function Invoke-Udp($sock, $requests, [int]$waitMs) {
    $c = 0
    foreach ($r in $requests) {
        try { [void]$sock.Send($r.Data, $r.Data.Length, $r.Ep) } catch { }
        if ((++$c % 10) -eq 0) { Start-Sleep -Milliseconds 15 }
    }
    $replies = New-Object System.Collections.ArrayList
    $deadline = (Get-Date).AddMilliseconds($waitMs)
    while ((Get-Date) -lt $deadline) {
        if ($sock.Available -gt 0) {
            $ep = [Net.IPEndPoint]::new([Net.IPAddress]::Any, 0)
            try {
                $d = $sock.Receive([ref]$ep)
                [void]$replies.Add(@{ Ip = $ep.Address.ToString(); Port = $ep.Port; Data = $d })
            } catch { }
        } else { Start-Sleep -Milliseconds 20 }
    }
    return $replies
}

# ---------------------------------------------------------------- BACnet scan
$devices = @{}   # key "ip|snet|sadr"

function Add-Device($ip, $snet, $sadr, $inst) {
    $key = "$ip|$snet|$sadr"
    if (-not $devices.ContainsKey($key)) {
        $devices[$key] = [ordered]@{ IP = $ip; DeviceID = $inst; RoutedNet = $snet; RoutedMac = $sadr;
            MAC = ""; Name = ""; Model = ""; Vendor = ""; Firmware = ""; AppVer = ""; Location = "" }
    } elseif (-not $devices[$key].DeviceID -and $inst) { $devices[$key].DeviceID = $inst }
}

if (-not $SkipScan) {
    $sock = [Net.Sockets.UdpClient]::new([Net.IPEndPoint]::new([Net.IPAddress]::Parse($localIp), 0))
    $sock.EnableBroadcast = $true
    $sock.Client.ReceiveBufferSize = 1048576

    # I-Am replies are usually broadcast to port 47808; listen there too if the port is free.
    $listen = $null
    try {
        $listen = [Net.Sockets.UdpClient]::new()
        $listen.ExclusiveAddressUse = $false
        $listen.Client.SetSocketOption([Net.Sockets.SocketOptionLevel]::Socket, [Net.Sockets.SocketOptionName]::ReuseAddress, $true)
        $listen.Client.Bind([Net.IPEndPoint]::new([Net.IPAddress]::Any, 47808))
        $listen.EnableBroadcast = $true
    } catch {
        Write-Host "Port 47808 is in use (EBO WorkStation open?). Skipping the Who-Is listen; the address scan still runs." -ForegroundColor Yellow
        $listen = $null
    }

    # 1. Who-Is broadcast
    Write-Host "Sending Who-Is..."
    foreach ($b in @("$Subnet.255", "255.255.255.255")) {
        $bep = [Net.IPEndPoint]::new([Net.IPAddress]::Parse($b), 47808)
        try { [void]$sock.Send($WhoIs, $WhoIs.Length, $bep) } catch { }
        if ($listen) { try { [void]$listen.Send($WhoIs, $WhoIs.Length, $bep) } catch { } }
    }
    $iam = @(Invoke-Udp $sock @() 3000)
    if ($listen) { $iam += @(Invoke-Udp $listen @() 500) }
    foreach ($r in $iam) {
        $n = Split-Bvlc $r.Data
        if ($n -and $n.Apdu.Length -gt 6 -and $n.Apdu[0] -eq 0x10 -and $n.Apdu[1] -eq 0x00) {
            $ip = if ($n.Ip) { $n.Ip } else { $r.Ip }
            $id = try { Read-AppValue $n.Apdu 2 } catch { "" }
            if ($id -like "8,*") { Add-Device $ip $n.Snet $n.Sadr ([int]($id -split ",")[1]) }
        }
    }
    Write-Host ("  {0} I-Am replies" -f $devices.Count)

    # 2. Address scan: ReadProperty(device 4194303, object-identifier) to every host
    Write-Host "Scanning $Subnet.$From-$To..."
    $reqs = @()
    $inv = 1
    for ($h = $From; $h -le $To; $h++) {
        $ip = "$Subnet.$h"
        if ($ip -eq $localIp) { continue }
        $reqs += @{ Data = (New-ReadProperty $inv 4194303 75); Ep = [Net.IPEndPoint]::new([Net.IPAddress]::Parse($ip), 47808) }
        $inv = ($inv % 250) + 1
    }
    foreach ($r in (Invoke-Udp $sock $reqs 3000)) {
        $n = Split-Bvlc $r.Data
        if (-not $n) { continue }
        $v = Read-RpAck $n.Apdu
        if ($v -like "8,*") { Add-Device $r.Ip $n.Snet $n.Sadr ([int]($v -split ",")[1]) }
        elseif (-not $n.Snet) { Add-Device $r.Ip $null $null $null }   # answered, but no wildcard support
    }
    Write-Host ("  {0} devices found" -f $devices.Count)

    # 3. Read name/model/etc. from each device, all at once, then retry the gaps.
    #    Routed (MS/TP) devices are read through their router. A reply is matched
    #    on its sender plus invoke ID (property number + 10 per try).
    $targets = @($devices.Values | Where-Object { $_.DeviceID })
    $routed = @($targets | Where-Object { $_.RoutedNet }).Count
    if ($targets.Count) { Write-Host "Reading names, models and firmware..." }
    for ($try = 0; $try -lt 3; $try++) {
        $reqs = @(); $want = @{}
        foreach ($d in $targets) {
            $ep = [Net.IPEndPoint]::new([Net.IPAddress]::Parse($d.IP), 47808)
            $k = 0
            foreach ($p in $PropIds.Keys) {
                $k++
                if ($d[$p]) { continue }
                $id = $k + 10 * $try
                $reqs += @{ Data = (New-ReadProperty $id $d.DeviceID $PropIds[$p] $d.RoutedNet "$($d.RoutedMac)"); Ep = $ep }
                $want["$($d.IP)|$($d.RoutedNet)|$($d.RoutedMac)|$id"] = @($d, $p)
            }
        }
        if (-not $reqs) { break }
        foreach ($r in (Invoke-Udp $sock $reqs (2000 + 30 * $routed))) {
            $n = Split-Bvlc $r.Data
            if (-not $n -or $n.Apdu.Length -lt 3) { continue }
            $hit = $want["$($r.Ip)|$($n.Snet)|$($n.Sadr)|$($n.Apdu[1])"]
            if ($hit) { $v = Read-RpAck $n.Apdu; if ($v) { $hit[0][$hit[1]] = $v } }
        }
    }
    foreach ($d in ($targets | Sort-Object { [version]($_.IP) }, { $_.RoutedNet }, { $_.DeviceID })) {
        $where = if ($d.RoutedNet) { "$($d.IP) net $($d.RoutedNet) mac $($d.RoutedMac)" } else { $d.IP }
        Write-Host ("  {0,-30} {1,-8} {2}" -f $where, $d.DeviceID, $d.Name)
    }

    # 4. MAC addresses from the ARP table (only for devices on this subnet)
    $arp = @{}
    try {
        Get-NetNeighbor -AddressFamily IPv4 -InterfaceIndex $ipInfo.InterfaceIndex -ErrorAction Stop |
            ForEach-Object { $arp[$_.IPAddress] = $_.LinkLayerAddress }
    } catch { }
    foreach ($d in $devices.Values) {
        if ($d.RoutedNet) { continue }
        if ($arp[$d.IP] -and $arp[$d.IP] -ne "00-00-00-00-00-00") { $d.MAC = ($arp[$d.IP] -replace "-", ":").ToLower() }
    }

    $sock.Close(); if ($listen) { $listen.Close() }

    $devCsv = Join-Path $OutDir "Devices_$stamp.csv"
    $devices.Values | ForEach-Object { [pscustomobject]$_ } |
        Sort-Object { [version]($_.IP) }, RoutedNet, DeviceID |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $devCsv
    Write-Host "Device list: $devCsv" -ForegroundColor Green
}

# ---------------------------------------------------------------- RSTP reading
if (-not $SkipStp) {
    $tshark = @("$env:ProgramFiles\Wireshark\tshark.exe", "${env:ProgramFiles(x86)}\Wireshark\tshark.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $tshark) {
        Write-Host "Wireshark (tshark.exe) not found, so no RSTP reading. Install Wireshark with Npcap to get one." -ForegroundColor Yellow
    } else {
        if (-not $Label) { $Label = Read-Host "Where is the laptop plugged in? (e.g. AHU-A port 2)" }
        $iface = "\Device\NPF_$($adapter.InterfaceGuid)"
        Write-Host "Listening for RSTP for $StpSeconds s on '$($adapter.Name)'..."
        $fields = @("eth.src", "stp.bridge.hw", "stp.bridge.prio", "stp.root.hw", "stp.root.prio", "stp.root.cost", "stp.port", "stp.flags.port_role")
        $targs = @("-i", $iface, "-f", "stp", "-a", "duration:$StpSeconds", "-T", "fields", "-E", "separator=|") + ($fields | ForEach-Object { "-e", $_ })
        $raw = & $tshark @targs 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $raw) {
            # older Wireshark field names differ; fall back to the basics
            $fields = @("eth.src", "stp.root.hw", "stp.root.cost")
            $targs = @("-i", $iface, "-f", "stp", "-a", "duration:$StpSeconds", "-T", "fields", "-E", "separator=|") + ($fields | ForEach-Object { "-e", $_ })
            $raw = & $tshark @targs 2>$null
        }
        $bpdus = @($raw | Where-Object { $_ } | Sort-Object -Unique)
        if (-not $bpdus) {
            Write-Host "No RSTP frames heard. Check the cable, and that you're on a controller port (not a building switch that blocks BPDUs)." -ForegroundColor Yellow
        }
        $roles = @{ "0" = "Unknown"; "1" = "Alternate/Backup"; "2" = "Root"; "3" = "Designated" }
        $known = @(Get-ChildItem $OutDir -Filter "Devices_*.csv" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | ForEach-Object { Import-Csv $_.FullName })
        $stpCsv = Join-Path $OutDir "RSTP readings.csv"
        foreach ($line in $bpdus) {
            $v = $line -split "\|"
            $row = [ordered]@{ Time = (Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Label = $Label; NeighborMAC = $v[0]; LaptopIP = $localIp }
            # same columns every time, so readings from either field set append cleanly
            foreach ($f in @("stp.bridge.hw", "stp.bridge.prio", "stp.root.hw", "stp.root.prio", "stp.root.cost", "stp.port", "stp.flags.port_role")) { $row[$f] = "" }
            for ($k = 1; $k -lt $fields.Count; $k++) { $row[$fields[$k]] = $v[$k] }
            # 802.1w long path cost is 200000 per 100 Mb hop; old short costs are 19 per hop
            $cost = $row["stp.root.cost"]
            if ($cost -ne $null -and "$cost" -ne "") {
                $per = if ([double]$cost -gt 0 -and [double]$cost -lt 1000) { 19 } else { 200000 }
                $row["HopsFromRoot"] = [math]::Round([double]$cost / $per, 1)
            } else { $row["HopsFromRoot"] = "" }
            $row["PortRole"] = if ($row["stp.flags.port_role"] -ne "") { $roles["$($row['stp.flags.port_role'])"] } else { "" }
            # match neighbor MAC (port or bridge) to a device found in this or an earlier scan
            $macs = @($v[0], $row["stp.bridge.hw"]) | Where-Object { $_ } | ForEach-Object { "$_".ToLower() }
            $match = $known | Where-Object { $_.MAC -and $macs -contains $_.MAC } | Select-Object -First 1
            $row["NeighborName"] = if ($match) { $match.Name } else { "" }
            $row["NeighborIP"]   = if ($match) { $match.IP } else { "" }
            [pscustomobject]$row | Export-Csv -NoTypeInformation -Encoding UTF8 -Append -Force -Path $stpCsv
            Write-Host ("  Neighbor {0} {1}  root cost {2}" -f $v[0], $row["NeighborName"], $cost)
        }
        Write-Host "RSTP readings appended to: $stpCsv" -ForegroundColor Green
    }
}
# ---------------------------------------------------------------- open the map
# Puts the newest device list and all RSTP readings into a copy of the map page.
if (-not $NoMap) {
    $tpl = Join-Path $PSScriptRoot "Network Map.html"
    $newest = Get-ChildItem $OutDir -Filter "Devices_*.csv" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
    $stpFile = Get-Item (Join-Path $OutDir "RSTP readings.csv") -ErrorAction SilentlyContinue
    $files = @(@($newest, $stpFile) | Where-Object { $_ })
    if (-not (Test-Path $tpl)) {
        Write-Host "Network Map.html isn't next to the script, so no map. Load the CSVs on the field tools site instead." -ForegroundColor Yellow
    } elseif ($files.Count) {
        $data = @{ made = (Get-Date -Format "yyyy-MM-dd HH:mm");
            files = @($files | ForEach-Object { @{ name = $_.Name; text = [IO.File]::ReadAllText($_.FullName) } }) }
        $json = ($data | ConvertTo-Json -Depth 4 -Compress).Replace("</", "<\/")
        $html = [IO.File]::ReadAllText($tpl, [Text.Encoding]::UTF8)
        $marker = 'id="netscanData">null</script>'
        if ($html.Contains($marker)) {
            $mapFile = Join-Path $OutDir "Network map.html"
            [IO.File]::WriteAllText($mapFile, $html.Replace($marker, 'id="netscanData">' + $json + '</script>'), (New-Object Text.UTF8Encoding $false))
            Write-Host "Map: $mapFile" -ForegroundColor Green
            Start-Process $mapFile
        }
    }
}
Write-Host "Done."
