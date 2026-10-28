# EBO Program Generator

Builds a canned EBO 7.1 program set for one controller. You give it the controller's export and say what's on the unit. It gives back one **`<unit> Complete - import.xml`** with the programs, points on their terminals, setpoint values, alarms and trends, all bound. It also writes a **README.txt** for the job folder. It's one HTML file (`index.html`), and nothing leaves the browser. Your choices are remembered on that device.

It covers five unit types:

| Type | Controller |
|---|---|
| **CV AHU**: single zone, space temperature | MP-C |
| **VAV AHU**: discharge air temperature and duct static | MP-C |
| **VAV box**: settings and points for the stock MP-V VAV application, plus optional perimeter radiation | MP-V |
| **Unit Vent**: classroom unit ventilator, discharge air reset from room temp | RP-C or MP-C |
| **Boiler**: hot water plant on an AS-P with SmartX IO modules | AS-P |

RTU and FCU are greyed out until there's a finished, field-proven program set for each. New jobs add options to these types rather than new types, and the types share the same point names and loops: a chilled water valve is `ClgVlvPos` on a cooling loop, DX stages are `Dx1Cmd`, `Dx2Cmd` and so on, and a hot water valve is `HwVlvPos`, whichever unit they're on.

## 1. Controller
In WorkStation, right-click the MP-C and **Export**, then open that XML here (button or drag and drop). The page reads:
- name, model, server and its terminals (DO, Ub, Uc)
- the SpaceLogic sensor on the Sensor Bus, if there is one
- anything already in `Application`

For the Boiler there's no export to open: type the AS-P server name and list the SmartX IO modules by slot (it starts with a typical boiler panel). Any other type given a file with no MP controller gets a clear error. A unit type on the wrong controller (a VAV box on an MP-C, say) shows in red. **Look around with a sample controller** loads a sample that fits the unit type you picked, but saving is off with the sample.

Start from an empty controller when you can. If an object with the same name is already in `Application`, the generator **reuses** it instead of making a new one. The README lists any binding you then have to make by hand. A program with the same name as one already there is flagged as a clash, because importing over a built program drops renamed inputs.

## 2. Unit
Pick the unit type and type the unit name (it defaults to the controller name). The name goes in program headers, alarm text and the file name. Each unit type remembers its own options, terminals and setpoints.

## 3. What's on the unit
Some choices only appear when they make sense (a return fan VFD that tracks supply speed needs a supply fan VFD, for example). Every change rebuilds the points, programs, alarms and trends right away.

**CV AHU**
| Option | Choices |
|---|---|
| Heating | None · Hot water valve · Hot water valve + face & bypass damper · Gas-fired modulating · Gas-fired 1 stage · Gas-fired 2 stages (see Gas heat below) |
| Cooling | None · DX 1 stage · DX 2 stages · Chilled water valve (cooling loop on space temp, occupied cooling mode and night setup) |
| Outside air | Economizer (OA/RA dampers, mixed air sensor) · Minimum position damper · Two-position damper · None |
| Outside air temp | Sensor wired to this controller · From the network |
| Room sensor | SpaceLogic sensor on the Sensor Bus · Wired sensor |
| Checkboxes | Return fan · Freezestat · Dirty filter switch · Return air temp sensor · Control on return air if the room sensor fails · Setpoint adjust and override button (SpaceLogic sensor only) |

**VAV AHU**
| Option | Choices |
|---|---|
| Supply fan | VFD on duct static · Vortex damper on duct static · Constant volume |
| Return / relief | Return fan VFD tracking supply speed · Return fan start/stop · Relief fan · Relief damper · None |
| Heating | None · Hot water valve · Hot water valve + face & bypass damper · Gas-fired modulating · Gas-fired 1 stage · Gas-fired 2 stages (see Gas heat below) |
| Cooling | None · DX 1 to 4 stages (staged on discharge temp) · Chilled water valve (cooling loop on discharge temp) · Packaged cooling enable |
| Discharge air setpoint | Reset from outside air temp · Reset from room temp · Fixed |
| Room temp | None · Wired sensor · From the network |
| Outside air temp | Sensor wired to this controller · From the network |
| Checkboxes | Return air CO2 raises the minimum OA · Night heat on room temp · OA isolation damper · Freezestat · Smoke detectors · Dirty filter switch · Condensate switch locks out cooling · Return air temp sensor · Control on return air if the room sensor fails (when a room temp feeds the reset or night heat) |

**Gas heat** (CV AHU and VAV AHU): the AHU program writes a heating request, `HtgReq` 0-100 %, where a hot water unit would position its valve. `Prog_GasHeat` turns it into `Htg1Cmd` (enable or stage 1), `Htg2Cmd` (stage 2) or `HtgFireRate` (0-10 V), and keeps the supply fan running for `HtgFanDof` after the burner stops. The burner only runs with fan status proven and the discharge air below `HtgTmpHlmt`. A modulating burner lights at 10 % request, holds low fire for `HtgLowFireDly`, then follows the request. A staged burner adds stage 2 at 60 % after `HtgStgDly` and drops it at 40 %. Minimum on and off times apply, and an optional alarm contact (burner lockout) drops the enable. The burner's own flame safeguard and limits stay in charge of combustion safety. This sequence was built from published gas furnace and rooftop sequences, not from a team program, so check it against the job's sequence of operations.

**VAV box**: the MP-V already runs Schneider's stock VAV application. The file doesn't copy or change its programs. It merges into the stock objects by name: it sets the reheat and fan selections (`RhtSelect`, `FanSelect`), puts the stock field points on the terminals you pick, switches the optional room sensor readings on, and can set the airflow limits. Perimeter radiation, if the box has it, comes in as one new component, `Components/PerimRad`, with its own program on the stock room temp (`RmTmp99`) and heating setpoint.
| Option | Choices |
|---|---|
| Reheat (RhtSelect) | Proportional HW valve · Floating HW valve · Two-position HW valve · Electric 1 stage · Electric 2 stages · Electric proportional · No reheat |
| Perimeter radiation | Reheat only · Reheat + rad valve (0-10 V) · Reheat + rad valve (on/off) |
| Radiation enabled | Below an outside air temp (written from the AS-P) · Always |
| Fan (FanSelect) | No fan · Parallel fan · Series fan |
| Checkboxes | Discharge air temp sensor · Fan status · Room CO2, room humidity and occupancy sensor enables · Set the airflow limits (from the box schedule) |

The reheat choice picks the stock points: `RhtPos` for proportional types, `Rht1Cmd` (and `Rht2Cmd`) for staged and two-position, both for floating. The fan choice adds `FanCmd` (and `FanSts`). Stock points you don't use keep their terminals. The stock application on an MP-V-9A uses all three DOs, so on/off radiation may need a terminal freed up first.

**Unit Vent**
| Option | Choices |
|---|---|
| Heating | Hot water valve + face & bypass damper · Hot water valve · None |
| Cooling | Chilled water valve · DX 1 stage · DX 2 stages (staged on supply air temp, as the VAV AHU) · None |
| Outside air | Economizer damper · OA damper at minimum position · None |
| Outside air temp | From the network (written from the AS-P) · Sensor wired to this controller |
| Room sensor | SmartX sensor on the Sensor Bus · Wired thermistor |
| Checkboxes | Setpoint adjust and override button (Sensor Bus only) · Fan status · Low limit switch · Night heat · Morning warm-up / cool-down · Dehumidify mode from the AS-P (chilled water only) |

The terminals default to a typical RP-C-12A wiring (SaTmp Ub 1, fan status Ub 2, low limit Ub 3, OA damper Ub 4, HW valve Ub 5 at 10-2 V, CHW valve Ub 6, face & bypass Ub 7, fan DO 1). HtgEna, ClgEna, DehumMode, TimeToStart and the outside air temp are written from the AS-P; HtgEna and ClgEna default to On until something writes them.

**Boiler**: an AS-P with SmartX IO modules. The default panel has DOFC8H relays in slot 3, AO8H in slot 4, UI16 in slot 5, DI16 in slot 6, pilot lights on the second DOFC8H in slot 7; change the modules in step 1 and any terminal in step 4.
| Option | Choices |
|---|---|
| Boilers | 2, lead/lag · 1 |
| Burner control | Enable + firing rate (0-10 V) · Enable only |
| System pumps | 2, lead/standby · 1 |
| Building supply | 3-way diverting valve with its own reset · Straight from the boilers |
| Occupied / unoccupied reset | Schedule HWSOcc · Occupied curve only |
| System enable | Below an outside air temp · Schedule HWSOcc + OAT, always on below 40 F |
| Lead/lag swap (2 boilers or 2 pumps) | Every N days · On run hours, with run-hour counters (Func_Runtime) |
| Lag boiler (2 boilers, firing rate) | Stages on load and loop temp · Split: lead fires over the first half of the loop signal, lag over the second |
| Outside air temp | Sensor wired to the AS-P · From the network (bind by hand) |
| Checkboxes | Boiler pressure transmitters and high pressure cutout · Boiler alarm contacts · Each boiler's supply temp and HW return temp (monitor only) · OA humidity · Emergency generator status and alarm · Panel pilot lights · Low return water protection (adds Prog_BoilerLowReturn) · 3-way valve holds bypass until the return is warm and cools down after shutdown |

The schedule enable, run-hour swap, split firing, low return ramp and valve cool-down come from the team's newer boiler program set (2026-10-15).

**Return air fallback** (CV AHU and VAV AHU; RTUs build with these types): Prog_RoomTemp checks the room reading. When it stays outside `RmTmpLlmt`..`RmTmpHlmt` (40 to 100 F) for 30 seconds, it raises the Room Sensor Failure alarm and the unit controls on return air temp until the reading is back in range; the alarm then clears on its own. Return air is used as-is, also at night with the fan off. Untick it and the unit holds the last good reading instead. Needs the return air temp sensor.

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

DO, AO, analog and binary values take a **relinquish default**. Units include °F, Δ°F, %, %RH, in. w.c., psi, ppm, cfm, seconds, minutes and hours. Added points are trended, marked "added" in the table, and listed with a **Remove** link. Each unit type keeps its own list on that device.

## 5. Setpoint defaults
These become the relinquish defaults of the value objects in `Parameters`, and the operator can still change them in WorkStation. The starting values are the team's usual numbers; check them against the job's sequence.

## 6. Trends
Tick what to trend. The key points start ticked; **Key points**, **All** and **None** reset the list. Points and calculated values are listed, and setpoints are under a fold. Each unit type remembers its own picks on that device. **Analog trend interval** defaults to 5 minutes; digital trends log on change. Every trend log carries its point's unit, so temperature trends chart in °F (a trend log with no unit charts in °C). If a ticked temperature has no unit, or one is set to °C, the readout flags it before you export. The VAV box has no list: Schneider's stock application already trends its own points.

## 7. Graphic
**Include a starter graphic** (on by default) adds one plain graphic to the file: every point and value in the export as a bound value box, in **Inputs**, **Outputs**, **Status** and **Setpoints** panels, with the unit name at the top. The boxes are the team's standard value box, so they show units, alarm and forced state, and clicking one commands it: outputs and values at priority 8, inputs out of service. It is a starting point, not a finished graphic. Open it in Graphics Editor, draw the unit around the boxes and delete the ones you don't need. With **Points only** it holds just the points. The VAV box has no starter graphic, because the stock MP-V application brings its own.

## Saving
The dark readout counts points, programs, setpoints, alarms and trends, and says whether the file is ready. Fix anything it lists first.
- **Programs + points** or **Points only** picks what goes in the file. Points only exports just the field points with their alarms and trends: no programs, values or setpoints. The trend list in step 6 then shows only points.
- **Save import file** saves `<unit> Complete - import.xml` (or `<unit> Points - import.xml`). The Boiler saves two files: `<unit> IO - import.xml` for the IO Bus and `<unit> Complete - import.xml` for `Application`.
- **Save README** saves the plain-text README: options, import steps, IO map, programs, setpoints, mode text, alarms, trends, program-to-program bindings, assumptions to confirm, and the full program listings.

**Read the programs** at the bottom shows each generated program as it will import.

**Start over** (top right) clears everything after three taps.

## Importing into EBO
The README.txt has the exact steps for the options you picked. In short:
1. Right-click `<controller>/Application` and choose **Import**, then pick the Complete file. For a VAV box, right-click `Application/Components` instead. For the Boiler, import the IO file into the AS-P's IO Bus first, then the Complete file into `Application`. Folders, points, programs, alarms, trends and the starter graphic come in together, with program inputs and graphic boxes already bound.
2. **Programs arrive uncompiled.** Open each function (`Func_PID`, `Func_Ratio`, `Func_Staging`, `Func_TwoPosition`, whichever are included) and Check and Save it, then do the same for each program. Until then the download to the controller fails with ProgramHasCompilationError.
3. Bind `OccCmdTs` (Occupancy folder) to the unit's schedule. Write the network values the README lists (outside air temp, AHU status) from the AS-P.
4. CV AHU with a SpaceLogic sensor and the override button: bind the sensor's Display > Occupancy Override to `Prog_Occupancy.RmOccOvrRst` so the button unlatches.
5. Check every terminal and its scaling against the drawings before putting the unit in auto. 0-10 V inputs (duct static, CO2) come in scaled from the README's ranges.

Test a new option mix on a spare or offline controller first. For the VAV box, import onto one box and check the settings before doing the rest, since it changes the stock objects. The generator has not been run against every combination in EBO.

## What's in the file
| Folder | Contents |
|---|---|
| Inputs / Outputs | Hardware points on their terminals. Room sensor values are bound from the Sensor Bus device. |
| Components | VAV box only: settings and terminals merged into the stock objects, plus `PerimRad` (Points, Values, Parameters, Programs, Functions, Trends) when the box has radiation |
| IO Bus | Boiler only, in the separate IO file: the SmartX modules and their points; outputs are written by the programs in `Application/<unit>` |
| Parameters | Setpoints as value objects with relinquish defaults |
| Numerics | Values the programs calculate (loads, mode, mode text) |
| Programs | Only the ones the options need (none with Points only). CV AHU: Prog_Occupancy, Prog_RoomTemp, Prog_RoomSetpoint, Prog_AhuControl, Prog_ControlLoops, Prog_CoolingControl, fan alarms. VAV AHU adds Prog_DischargeSetpoint and Prog_ReliefFan, and uses Prog_RoomTemp only with the return air fallback. Unit Vent: Prog_Occupancy, Prog_RoomTemp, Prog_RoomSetpoint, Prog_UvControl, Prog_UvHeatCool, Prog_OaDamper, Prog_SaFanAlarm, and Prog_CoolingControl with DX. Boiler: Prog_HwSysEnable, Prog_HwPumps, Prog_HwReset, Prog_HwLoops, Prog_BoilerStaging, Prog_BoilerLowReturn (low return option), Prog_Boiler1/2, Prog_PanelLights. VAV box: Prog_RadControl, only with radiation. |
| Functions | Func_PID (team standard), Func_Ratio (linear reset, VAV AHU and Unit Vent), Func_Staging (DX stages) and Func_TwoPosition (night heat), as the unit needs. Skipped if the controller already has them. |
| Alarms | Fan failure, freezestat, smoke, dirty filter, discharge temp, room sensor failure, as the options need; they auto-clear |
| Trends | The points ticked in step 6, `<Point>Tlog` |
| Occupancy | OccCmdTs, for binding to the schedule |
| Graphics | The starter graphic from step 7, named after the unit. On the Boiler it is `Application/<unit>/Graphics`. |

Programs follow the team's conventions: EBO Script, EBO 3 SEBA names, program inputs named exactly like the objects that feed them, Goto state machines on `TS` timers, Func_PID called with 9 arguments, and mode text of 32 characters or less.
