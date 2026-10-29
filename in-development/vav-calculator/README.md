# VAV Field Calculator

Quick airflow, balancing, and reheat math for VAV boxes in the field. It's one HTML file (`index.html`) that works offline once opened. Your last inputs are remembered on that device. **Reset** (top right) puts every input back to its starting value after three taps: **Reset → Reset inputs? → Tap to reset all**.

The page has four tabs:

## Airflow
Calculates CFM from the flow sensor's velocity pressure and the box K-factor.

| Input | Notes |
|---|---|
| Inlet size | Round inlet diameter, 4″–24″ |
| Flow sensor ΔP | Velocity pressure in in. w.c., as read by the controller or a manometer |
| K-factor | The manufacturer's flow coefficient (CFM at 1″ ΔP). **Use ideal K** fills in the theoretical value for the inlet. |

**Formula:** `CFM = K × √ΔP`

**Shows:** CFM, inlet velocity (FPM), inlet area (ft²), and ideal K (`4005 × area`).

**Flags**
| Flag | Meaning |
|---|---|
| 🔴 ΔP below ~0.03″ | Most VAV transducers aren't accurate down there. Expect drifting minimums. |
| 🟠 Over 3,000 FPM | Likely noise issues |
| 🟠 Under 400 FPM | Low inlet velocity. Check the minimum setpoint. |
| 🟢 Normal range | Between those limits |

The ideal K ignores pickup amplification, so the manufacturer's K from the box label or submittal is almost always the right one to use.

## K-Factor
Corrects the K-factor after comparing the controller reading to a hood or traverse.

| Input | Notes |
|---|---|
| Controller reads | CFM shown by the BAS |
| Hood / traverse | Measured CFM |
| Current K-factor | K in the controller now |

**Formula:** `K_new = K_old × (measured ÷ displayed)`

**Shows:** new K-factor, reading error %, correction multiplier, and the ΔP the controller is currently seeing (`(displayed ÷ K_old)²`).

**Flags**
| Flag | Meaning |
|---|---|
| 🟢 Within ±5% | No change needed |
| 🟠 Within ±10% | Correct it if the spec is tighter |
| 🔴 Over ±10% | Correct it, then recheck at minimum |

Check at both max and min. If the error is very different between the two, fix the sensor zero or offset before touching the K-factor.

## Reheat
Calculates the coil load needed to heat the airflow from entering to leaving air temperature.

| Input | Notes |
|---|---|
| Coil type | Hot water or electric |
| Heating airflow | CFM through the coil in heating |
| Entering / leaving air | °F |
| Water ΔT (hot water) | Design supply − return, °F |
| Heater voltage (electric) | 120/208/277 V single phase, 208/480 V three phase |

**Formulas**
- `BTU/h = 1.08 × CFM × ΔT_air`
- `kW = BTU/h ÷ 3412`
- Hot water: `GPM = BTU/h ÷ (500 × ΔT_water)`
- Electric, 1 ph: `Amps = W ÷ V`. 3 ph: `Amps = W ÷ (V × √3)`

**Flags:** leaving air over 95 °F (stratification risk), or air ΔT over 40 °F (check the coil rating).

## Inlets
A reference table for round inlets 4″–24″ at a design velocity you enter (default 2,000 FPM): area, ideal K, CFM at that velocity, and the true velocity pressure (`(FPM ÷ 4005)²`). The inlet picked on the Airflow tab is highlighted.

## Assumptions
- Standard air (0.075 lb/ft³) at sea level.
- Above about 2,000 ft elevation, the 1.08 sensible heat factor and the 4005 velocity constant need to be derated.
- Results are field estimates. Use the box manufacturer's data and the project spec for final balancing values.
