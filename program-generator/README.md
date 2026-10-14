# EBO Program Generator

Builds a canned EBO 7.1 program set for one controller. You give it the controller's export and say what's on the unit. It gives back one **`<unit> Complete - import.xml`** with the programs, points on their terminals, setpoint values, alarms and trends, all bound. It also writes a **README.txt** for the job folder. It's one HTML file (`index.html`), and nothing leaves the browser. Your choices are remembered on that device.

It covers four unit types:

| Type | Controller | Built from |
|---|---|---|
| **CV AHU**: single zone, space temperature | MP-C | Bower Hill AHU-B/C/D |
| **VAV AHU**: discharge air temperature and duct static | MP-C | Airport AHU-1 to 4 and PAHU-1 |
| **VAV box**: perimeter radiation added to the stock MP-V VAV application | MP-V | Airport VAV boxes |
| **Unit Vent**: classroom unit ventilator, discharge air reset from room temp | RP-C or MP-C | Bower Hill unit ventilators (Room 113 and the 50 like it) |

RTU, FCU and Boiler are greyed out until there's a finished, field-proven program set for each. New jobs add options to these types rather than new types.

## 1. Controller
In WorkStation, right-click the MP-C and **Export**, then open that XML here (button or drag and drop). The page reads:
- name, model, server and its terminals (DO, Ub, Uc)
- the SpaceLogic sensor on the Sensor Bus, if there is one
- anything already in `Application`

An AS-P SmartX IO export or a file with no MP controller gets a clear error. A unit type on the wrong controller (a VAV box on an MP-C, say) shows in red. **Look around with a sample controller** loads a sample that fits the unit type you picked, but saving is off with the sample.

Start from an empty controller when you can. If an object with the same name is already in `Application`, the generator **reuses** it instead of making a new one. The README lists any binding you then have to make by hand. A program with the same name as one already there is flagged as a clash, because importing over a built program drops renamed inputs.

## 2. Unit
Pick the unit type and type the unit name (it defaults to the controller name). The name goes in program headers, alarm text and the file name. Each unit type remembers its own options, terminals and setpoints.

## 3. What's on the unit
Some choices only appear when they make sense (a return fan VFD that tracks supply speed needs a supply fan VFD, for example). Every change rebuilds the points, programs, alarms and trends right away.

**CV AHU**
| Option | Choices |
|---|---|
| Heating | None · Hot water valve · Hot water valve + face & bypass damper |
| Cooling | None · DX 1 stage · DX 2 stages |
| Outside air | Economizer (OA/RA dampers, mixed air sensor) · Minimum position damper · Two-position damper · None |
| Outside air temp | Sensor wired to this controller · From the network |
| Room sensor | SpaceLogic sensor on the Sensor Bus · Wired sensor |
| Checkboxes | Return fan · Freezestat · Dirty filter switch · Return air temp sensor · Setpoint adjust and override button (SpaceLogic sensor only) |

**VAV AHU**
| Option | Choices |
|---|---|
| Supply fan | VFD on duct static · Vortex damper on duct static · Constant volume |
| Return / relief | Return fan VFD tracking supply speed · Return fan start/stop · Relief fan · Relief damper · None |
| Heating | None · Hot water valve · Hot water valve + face & bypass damper |
| Cooling | None · DX 1 to 4 stages (staged on discharge temp) · Packaged cooling enable |
| Discharge air setpoint | Reset from outside air temp · Reset from room temp · Fixed |
| Room temp | None · Wired sensor · From the network |
| Outside air temp | Sensor wired to this controller · From the network |
| Checkboxes | Return air CO2 raises the minimum OA · Night heat on room temp · OA isolation damper · Freezestat · Smoke detectors · Dirty filter switch · Condensate switch locks out cooling · Return air temp sensor |

**VAV box**: imports into `Application/Components` as one new component, `PerimRad`, laid out like the stock ones (`Points`, `Values`, `Parameters`, `Programs`, `Functions`, `Alarms`, `Trends` subfolders), and leaves the stock VAV application alone. It reads the stock room temp (`RmTmp99`) and heating setpoint (`RmTmpSpt99/RmTmpHspt`).
| Option | Choices |
|---|---|
| Perimeter radiation | Modulating valve (0-10 V) · On/off valve or relay |
| Radiation enabled | Below an outside air temp (written from the AS-P) · Always |

The stock application on an MP-V-9A uses all three DOs, so on/off radiation needs a terminal freed up first.

**Unit Vent**
| Option | Choices |
|---|---|
| Heating | Hot water valve + face & bypass damper · Hot water valve · None |
| Cooling | Chilled water valve · None |
| Outside air | Economizer damper · OA damper at minimum position · None |
| Outside air temp | From the network (written from the AS-P) · Sensor wired to this controller |
| Room sensor | SmartX sensor on the Sensor Bus · Wired thermistor |
| Checkboxes | Setpoint adjust and override button (Sensor Bus only) · Fan status · Low limit switch · Night heat · Morning warm-up / cool-down · Dehumidify mode from the AS-P |

The terminals default to the Bower Hill RP-C-12A wiring (SaTmp Ub 1, fan status Ub 2, low limit Ub 3, OA damper Ub 4, HW valve Ub 5 at 10-2 V, CHW valve Ub 6, face & bypass Ub 7, fan DO 1). HtgEna, ClgEna, DehumMode, TimeToStart and the outside air temp are written from the AS-P; HtgEna and ClgEna default to On until something writes them.

## 4. Points and terminals
Terminals are assigned automatically:
- inputs get the lowest free Ub;
- analog outputs get a Uc (or AO) first, otherwise the highest free Ub;
- relays get the DO terminals.

You can change any terminal from its menu. Analog outputs also have a signal menu: 0-10, 2-10, 10-0 or 10-2 V. A red row means that point has no terminal, or two points share one. For example, face & bypass plus a return fan needs 11 universal points, and an MP-C-18B has only 10 Ub. **Reassign terminals automatically** starts the assignment over.

### Add a point
Below the terminal table, **Add a point** covers anything the options don't: a name (SEBA style, like `HwSTmp`), a description, and the type:
- AI 10k thermistor, AI 0-10 V transmitter (with units and what 0 V and 10 V read), DI, DO or AO 0-10 V. These get a terminal in the table above like any other point.
- Analog value (with units) or binary value. These go in `Parameters`.

DO, AO, analog and binary values take a **relinquish default**. Units include °F, Δ°F, %, %RH, in. w.c., psi, ppm, cfm, seconds and minutes. Added points are trended, marked "added" in the table, and listed with a **Remove** link. Each unit type keeps its own list on that device.

## 5. Setpoint defaults
These become the relinquish defaults of the value objects in `Parameters`, and the operator can still change them in WorkStation. The starting values are the team's numbers from the job each type was built from (Bower Hill or Airport). **Analog trend interval** defaults to 5 minutes; digital trends log on change.

## Saving
The dark readout counts points, programs, setpoints, alarms and trends, and says whether the file is ready. Fix anything it lists first.
- **Programs + points** or **Points only** picks what goes in the file. Points only keeps the points, values (with their relinquish defaults), alarms on hardware inputs and trends, and leaves the `Programs` folder empty, for when you'll write or copy the programs yourself.
- **Save import file** saves `<unit> Complete - import.xml` (or `<unit> Points - import.xml`).
- **Save README** saves the plain-text README: options, import steps, IO map, programs, setpoints, mode text, alarms, trends, program-to-program bindings, assumptions to confirm, and the full program listings.

**Read the programs** at the bottom shows each generated program as it will import.

**Start over** (top right) clears everything after three taps.

## Importing into EBO
The README.txt has the exact steps for the options you picked. In short:
1. Right-click `<controller>/Application` and choose **Import**, then pick the Complete file. For a VAV box, right-click `Application/Components` instead. Folders, points, programs, alarms and trends come in together, with program inputs already bound.
2. Programs arrive uncompiled. Open and save the functions (`Func_PID`, `Func_Ratio`, `Func_Staging`, `Func_TwoPosition`, whichever are included) first, then each program.
3. Bind `OccCmdTs` (Occupancy folder) to the unit's schedule. Write the network values the README lists (outside air temp, AHU status) from the AS-P.
4. CV AHU with a SpaceLogic sensor and the override button: bind the sensor's Display > Occupancy Override to `Prog_Occupancy.RmOccOvrRst` so the button unlatches.
5. Check every terminal and its scaling against the drawings before putting the unit in auto. 0-10 V inputs (duct static, CO2) come in scaled from the README's ranges.

Test a new option mix on a spare or offline controller first. The generator has not been run against every combination in EBO.

## What's in the file
| Folder | Contents |
|---|---|
| Inputs / Outputs | Hardware points on their terminals. Room sensor values are bound from the Sensor Bus device. |
| Components/PerimRad | VAV box only: one component with the stock subfolders (Points, Values, Parameters, Programs, Functions, Trends) |
| Parameters | Setpoints as value objects with relinquish defaults |
| Numerics | Values the programs calculate (loads, mode, mode text) |
| Programs | Only the ones the options need (empty with Points only). CV AHU: Prog_Occupancy, Prog_RoomTemp, Prog_RoomSetpoint, Prog_AhuControl, Prog_ControlLoops, Prog_CoolingControl, fan alarms. VAV AHU adds Prog_DischargeSetpoint and Prog_ReliefFan. Unit Vent: Prog_Occupancy, Prog_RoomTemp, Prog_RoomSetpoint, Prog_UvControl, Prog_UvHeatCool, Prog_OaDamper, Prog_SaFanAlarm. VAV box: Prog_RadControl. |
| Functions | Func_PID (team standard), Func_Ratio (linear reset, VAV AHU and Unit Vent), Func_Staging (DX stages) and Func_TwoPosition (night heat), as the unit needs. Skipped if the controller already has them. |
| Alarms | Fan failure, freezestat, smoke, dirty filter, discharge temp, room sensor failure, as the options need; they auto-clear |
| Trends | Key points, `<Point>Tlog` |
| Occupancy | OccCmdTs, for binding to the schedule |

Programs follow the team's conventions: EBO Script, EBO 3 SEBA names, program inputs named exactly like the objects that feed them, Goto state machines on `TS` timers, Func_PID called with 9 arguments, and mode text of 32 characters or less.
