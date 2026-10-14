# EBO Program Generator

Builds a canned EBO 7.1 program set for one controller. You give it the controller's export and say what's on the unit. It gives back one **`<unit> Complete - import.xml`** with the programs, points on their terminals, setpoint values, alarms and trends, all bound. It also writes a **README.txt** for the job folder. It's one HTML file (`index.html`), and nothing leaves the browser. Your choices are remembered on that device.

**Version 1 covers single-zone AHUs on an MP-C.** It was built and tested against an MP-C-18B export. RTU, VAV, FCU, Unit Vent and Boiler are greyed out until there's a finished, field-proven program set for each.

## 1. Controller
In WorkStation, right-click the MP-C and **Export**, then open that XML here (button or drag and drop). The page reads:
- name, model, server and its terminals (DO, Ub, Uc)
- the SpaceLogic sensor on the Sensor Bus, if there is one
- anything already in `Application`

An AS-P SmartX IO export or a file with no MP controller gets a clear error. **Look around with a sample MP-C-18B** lets you try the page, but saving is off with the sample.

Start from an empty controller when you can. If an object with the same name is already in `Application`, the generator **reuses** it instead of making a new one. The README lists any binding you then have to make by hand. A program with the same name as one already there is flagged as a clash, because importing over a built program drops renamed inputs.

## 2. Unit
Pick the unit type and type the unit name (it defaults to the controller name). The name goes in program headers, alarm text and the file name.

## 3. What's on the unit
| Option | Choices |
|---|---|
| Heating | None · Hot water valve · Hot water valve + face & bypass damper |
| Cooling | None · DX 1 stage · DX 2 stages |
| Outside air | Economizer (OA/RA dampers, mixed air sensor) · Minimum position damper · Two-position damper · None |
| Outside air temp | Sensor wired to this controller · From the network |
| Room sensor | SpaceLogic sensor on the Sensor Bus · Wired sensor |
| Checkboxes | Return fan · Freezestat · Dirty filter switch · Return air temp sensor · Setpoint adjust and override button (SpaceLogic sensor only) |

Every change rebuilds the points, programs, alarms and trends right away.

## 4. Points and terminals
Terminals are assigned automatically:
- inputs get the lowest free Ub;
- analog outputs get a Uc (or AO) first, otherwise the highest free Ub;
- relays get the DO terminals.

You can change any terminal from its menu. Analog outputs also have a signal menu: 0-10, 2-10, 10-0 or 10-2 V. A red row means that point has no terminal, or two points share one. For example, face & bypass plus a return fan needs 11 universal points, and an MP-C-18B has only 10 Ub. **Reassign terminals automatically** starts the assignment over.

## 5. Setpoint defaults
These become the relinquish defaults of the value objects in `Parameters`, and the operator can still change them in WorkStation. The starting values are the team's Bower Hill numbers. **Analog trend interval** defaults to 5 minutes; digital trends log on change.

## Saving
The dark readout counts points, programs, setpoints, alarms and trends, and says whether the file is ready. Fix anything it lists first.
- **Save import file** saves `<unit> Complete - import.xml`.
- **Save README** saves the plain-text README: options, import steps, IO map, programs, setpoints, mode text, alarms, trends, program-to-program bindings, assumptions to confirm, and the full program listings.

**Read the programs** at the bottom shows each generated program as it will import.

**Start over** (top right) clears everything after three taps.

## Importing into EBO
1. Right-click `<controller>/Application` and choose **Import**, then pick the Complete file. Folders, points, programs, alarms and trends come in together, with program inputs already bound.
2. Programs arrive uncompiled. Open and save **Func_PID** first, then each program.
3. Bind `OccCmdTs` (Occupancy folder) to the unit's schedule.
4. With a SpaceLogic sensor and the override button: bind the sensor's Display > Occupancy Override to `Prog_Occupancy.RmOccOvrRst` so the button unlatches.
5. Check every terminal and its scaling against the drawings before putting the unit in auto.

Test a new option mix on a spare or offline controller first. The generator has not been run against every combination in EBO.

## What's in the file
| Folder | Contents |
|---|---|
| Inputs / Outputs | Hardware points on their terminals. Room sensor values are bound from the Sensor Bus device. |
| Parameters | Setpoints as value objects with relinquish defaults |
| Numerics | Values the programs calculate (loads, mode, mode text) |
| Programs | Prog_Occupancy, Prog_RoomTemp, Prog_RoomSetpoint, Prog_AhuControl, Prog_ControlLoops, Prog_CoolingControl, Prog_SaFanAlarm, Prog_RaFanAlarm (only the ones the options need) |
| Functions | Func_PID (team standard; skipped if the controller already has it) |
| Alarms | Supply and return fan failure, freezestat, dirty filter, room sensor failure; they auto-clear |
| Trends | Key points, `<Point>Tlog` |
| Occupancy | OccCmdTs, for binding to the schedule |

Programs follow the team's conventions: EBO Script, EBO 3 SEBA names, program inputs named exactly like the objects that feed them, Goto state machines on `TS` timers, Func_PID called with 9 arguments, and mode text of 32 characters or less.
