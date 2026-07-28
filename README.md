# XGPON_Simulator

A discrete event-driven simulator, written in MATLAB, of the upstream channel
of an ITU-T G.987 XG-PON1 network.

It was built for the diploma thesis **["Design of a Market Mechanism for
Dynamic Bandwidth Allocation in XG-PON"](https://dspace.uowm.gr/xmlui/bitstream/handle/123456789/835/cdalamagkas_diploma_thesis.pdf?sequence=1&isAllowed=y)**
(Christos Dalamagkas, Dept. of Electrical and Computer Engineering, University
of Western Macedonia, 2017), whose results were later published as
*"PAS: A Fair Game-Driven DBA Scheme for XG-PON Systems"*
(IEEE ICC 2018 — C. Dalamagkas, P. Sarigiannidis, I. Moscholios, T. Lagkas,
M. S. Obaidat). See [Citation](#citation) below.

The thesis itself is the best source for the full theory (game formulation,
proofs, related work); this README explains what the simulator does, the
practical shape of the algorithm it implements, and how to run it.

## Background

XG-PON offers 10 Gbit/s downstream and 2.5 Gbit/s upstream, shared by many
Optical Network Units (ONUs) over a single fiber tree. A **Dynamic Bandwidth
Allocation (DBA)** scheme at the OLT decides, every 125 µs, how much of the
upstream capacity each ONU may use. Most DBA schemes are heuristics that work
well under normal load but have no fairness guarantee once aggregate demand
*exceeds* the available bandwidth (network saturation) — exactly the
situation Garrett Hardin's "tragedy of the commons" describes.

This thesis models upstream bandwidth as a common resource contended for by
`N` ONUs (players) and designs a resource-allocation game whose unique Nash
equilibrium is used as the allocation rule — the **Proportional Allocation
Scheme (PAS)**. Concretely:

- The network operator would ideally want to maximize *social welfare*: the
  sum of every ONU's utility `Uᵢ` from the bandwidth `aᵢ` it receives, subject
  to the capacity limit `C` available every 125 µs (the *"System"* problem,
  thesis eq. 6.1):

  ```
  maximize   Σᵢ Uᵢ(aᵢ)
  subject to Σᵢ aᵢ ≤ C ,  aᵢ ≥ 0
  ```

- ONUs only report *bids* `sᵢ` (their buffer occupancy/demand), not their
  true utility, and act to maximize their own payoff under the resulting
  price. The thesis proves this game has a unique Nash equilibrium, and that
  the corresponding allocation is simply **proportional to each contender's
  share of total demand** (thesis eq. 6.5) — this is exactly what
  `DBA.m`/`Guaranteed_BA.m` compute for the leftover (non-guaranteed)
  bandwidth when `PAS_Flag` is enabled:

  ```
  aᵢ = ( sᵢ / Σⱼ sⱼ ) · C
  ```

- Because ONUs act selfishly instead of truthfully, the resulting allocation
  is not always the social-welfare optimum — but the thesis proves the
  worst-case efficiency loss (the *Price of Anarchy*) is bounded by exactly
  25% (thesis Theorem 6.2):

  ```
  Σᵢ Uᵢ(aᵢ_game) ≥ (3/4) · Σᵢ Uᵢ(aᵢ_system)
  ```

  i.e. even in the worst case, letting ONUs behave selfishly under PAS never
  loses more than a quarter of the ideal social welfare, while guaranteeing
  fairness that a heuristic scheme cannot.

For the utility-function assumptions, the full game/market definition, the
Nash-equilibrium derivation, and the Price-of-Anarchy proof, see chapters 5–6
of the thesis.

## How the simulator works

`XGPON.m` runs a classic discrete-event simulation. All quantities are in
**bytes and seconds**. An event queue, `Event_List`, acts as a priority queue:
each column is one pending event, popped in order of (time, priority) and
dispatched to a handler:

| Event | Handler   | Does |
|-------|-----------|------|
| 1     | `Event1.m`| Calls `DBA.m` to build the next `BWmap`, broadcasts it downstream to every ONU, and re-schedules itself 125 µs later |
| 2     | `Event2.m`| An ONU receives its `BWmap`, packs an upstream XGTC burst from its queue up to `GrantSize`, and schedules its arrival at the OLT |
| 3     | `Event3.m`| The XGTC burst arrives at the OLT; updates goodput, per-packet delay and PDV (packet delay variation) accumulators |
| 4     | `Event4.m`| Termination event (fires once, at `Sim_Time`); finalizes all metrics and stops the simulation |
| 5     | `Event5.m`| Reserved for debugging — periodically records mean per-ONU delay; not used in the final statistics |
| 6     | `Event6.m`| CBR packet arrival: enqueues a fixed-size packet and reschedules itself at a fixed interval |
| 7, 8… | `Event7.m`| VBR packet arrival: one event ID per independent VBR stream (`6+k` for the k-th stream); draws packet size and interarrival time from an empirical distribution via `RNG.m` |

`Event_List` row layout (row 1 is the Event ID used to look up the column):

1. Event ID
2. Execution time
3. Priority (tiebreaker when two events share the same time; **lower value =
   higher priority**)
4. ONU/AllocID the event concerns
5. Bytes sent *(only for XGTC-burst-arrival events)*
6. `BufOcc` — the ONU's buffer occupancy at send time
7. Number of packets carried in the burst
8+. Arrival time (into the ONU's queue) of each individual packet carried in
    the burst

`BWmap(:, AllocID)` — one allocation per column, built by `DBA.m`:

* row 1 — AllocID *(kept at 0 in practice; the AllocID is implied by the
  column index instead — a pre-existing quirk in the code, not a bug that
  affects results)*
* row 2 — `StartTime`, the delay to insert before transmission to keep the
  guard time between consecutive ONU bursts at the OLT
* row 3 — `GrantSize`, the granted allocation in bytes

## The DBA algorithm (`DBA.m`)

Runs once per 125 µs frame, in two phases:

1. **Guaranteed allocation** (`Guaranteed_BA.m`) — every AllocID
   unconditionally gets `R_F` (Fixed) bytes regardless of demand; any
   remaining demand up to `R_A` (Assured) bytes is then granted if the ONU
   still needs it. `R_F`/`R_A` are the two elements of the `D` vector
   (`D = [R_F R_A]`, in bytes) passed into `XGPON.m`.
2. **Leftover ("non-guaranteed") bandwidth** — whatever remains of the
   125 µs capacity `C` after guaranteed allocations is distributed among
   ONUs that still have unmet demand, using one of two schemes:
   - **PAS** (`PAS_Flag = true`, and demand still exceeds the residual
     capacity): the proportional Nash-equilibrium split described above —
     `Final_Allocations(i) = floor(sᵢ · Residual_Bandwidth / Σⱼ sⱼ)`.
   - **Default ("blind") scheme** (`PAS_Flag = false`, or PAS's saturation
     condition isn't met): a max-min-fair, water-filling loop that repeatedly
     grants every contending ONU the current smallest unmet demand until
     capacity runs out.

Bandwidth figures are converted from XGTC payload size to actual on-wire PHY
burst size via `PHY_Payload.m`, which models the XG-PON1 **RS(248,232)**
Reed–Solomon FEC code (16 parity bytes per 232-byte codeword) plus 8 bytes of
XGTC framing overhead — this is why allocation sizes in the code are not the
literal requested demand.

`DBA.m` also computes the Jain fairness index (`Jain_Index.m`) of
supply-vs-demand across contending ONUs every frame (`Load_Fairness`), and
`Event4.m` computes the Jain fairness index of per-ONU mean delay at the end
of the run (`Delay_Fairness`).

## Traffic model

Each ONU generates two independent traffic types, combined into one queue by
`Form_Traffic.m`:

- **CBR** — fixed parameters, hardcoded in `Form_Traffic.m`: one 1518-byte
  packet every 124 µs (~97.9 Mbit/s per ONU).
- **VBR** — sampled at runtime from an *empirical* distribution built from a
  real packet capture, not a closed-form model:

  ```
  pcap capture ──▶ Extract_OutputTXT.m ──▶ Output.txt ──▶ Extract_Distribution.m
                                                                │
                                          (packet-size & inter-arrival PMFs)
                                                                ▼
                                        Form_Traffic.m ──▶ RNG.m (sampled in Event7.m)
  ```

  `Traffic/1/` ships one such capture (`720p_H.264_2mbps_mp4.pcapng`, a
  720p H.264 video stream) already processed into `Output.txt`.
  `Traffic/INFO.txt` reserves folders `2, 3, 4, 5, ...` for additional traffic
  profiles, and `Event7.m`'s event-ID scheme (`6+k`) already supports more
  than one concurrent VBR stream — but only `Traffic/1/` is currently wired
  up in `Form_Traffic.m`, so only one VBR profile runs today.

Both traffic types can be toggled independently via the `hasCBR`/`hasVBR`
flags in `XGPON_Simulation.m`.

## Parameters & constants

User-configurable, in `XGPON_Simulation.m`:

| Variable | Meaning | Units | Example |
|----------|---------|-------|---------|
| `hasCBR`, `hasVBR` | Enable/disable each traffic type | boolean | `1`, `1` |
| `Sim_Time` | Duration of each simulated run | seconds | `1` |
| `D` | `[R_F R_A]` — Fixed and Assured guaranteed-bandwidth thresholds | bytes | `[250 500]` |
| `N` | Sweep of ONU counts to test | vector | `4:4:32` |
| `Samples` | Repetitions per data point, averaged (Monte Carlo) | count | `5` |

Fixed protocol/physical constants, in `XGPON.m`:

| Constant | Value | Meaning |
|----------|-------|---------|
| `Upstream_Speed` | 311,040,000 bytes/s | XG-PON1 upstream line rate (~2.49 Gbit/s) |
| `Downstream_Transmission_Delay` | 125 µs | XGTC downstream frame period |
| `Guard_Time` | 2.57201646×10⁻⁸ s | Minimum gap enforced between consecutive ONU bursts at the OLT |
| `C = 38880 - 24·N` | bytes | Upstream capacity available per 125 µs frame (`38880` = `Upstream_Speed × 125 µs`), minus 24 bytes reserved per ONU (see [Known limitations](#known-limitations-and-deviations-from-g9873)) |

`Set_PDT.m` places every ONU uniformly at random between 20 and 60 km from
the OLT and derives its propagation delay using a fiber signal speed of 70%
of `c` (299,792,458 × 0.7 m/s).

For reference, the standard's downstream line rate (not separately modeled —
see limitations below) is 1,244,160,000 bytes/s (~9.95 Gbit/s).

## How to run

Requires MATLAB with the **Parallel Computing Toolbox** (`XGPON_Simulation.m`
uses `parfor` to run the ONU-count sweep in parallel).

```matlab
XGPON_Simulation
```

This runs, for every ONU count in `N`, `Samples` repetitions of the
simulation *twice* — once with the default DBA scheme and once with PAS
(`XGPON-GT`) — and prints a live summary per ONU count:

```
4 ONUs:
	XGPON:    Delay=... msec  Goodput=... Mbps  Load Fairness=...  Delay Fairness=...
	XGPON-GT: Delay=... msec  Goodput=... Mbps  Load Fairness=...  Delay Fairness=...
```

All averaged metrics (`Packet_Delay`, `Goodput`, `Load_Fairness`,
`Delay_Fairness`, `Packet_Loss_Ratio`, `PDV`) are saved to `results.mat`
alongside the run's parameters. No plotting utility ships with the
simulator — load and plot the metrics yourself, e.g.:

```matlab
load results.mat
plot(N, Packet_Delay(1,:), '-o', N, Packet_Delay(2,:), '-s');
legend('XGPON', 'XGPON-GT');
xlabel('Number of ONUs'); ylabel('Mean packet delay (s)');
```

To run a single configuration directly instead of the full sweep, call
`XGPON.m` yourself:

```matlab
Traffic = Form_Traffic(1, 1);
PDT = Set_PDT(8);
[Packet_Delay, Goodput, Load_Fairness, Delay_Fairness, Packet_Loss_Ratio, PDV] = ...
    XGPON(1, [250 500], 8, PDT, Traffic, true); % true = PAS enabled
```

`disable_fprintf.ps1`/`enable_fprintf.ps1` (Windows PowerShell) bulk
comment/uncomment the debug `fprintf` traces scattered through `Event1–6.m`,
`DBA.m` and `Guaranteed_BA.m`, useful for tracing a single run without
flooding output during a batch sweep. Note `Event7.m` is not included in
either script's file list, so its debug prints must be toggled by hand.

## File index

| File | Description |
|------|--------------|
| `XGPON_Simulation.m` | Entry point: sweeps ONU counts, runs each config with and without PAS, saves `results.mat` |
| `XGPON.m` | Main event-driven simulator core |
| `DBA.m` | Dynamic Bandwidth Allocation: guaranteed + non-guaranteed (PAS or blind) phases, builds `BWmap` |
| `Guaranteed_BA.m` | Allocates guaranteed (`R_F`/`R_A`) bandwidth to AllocIDs |
| `PHY_Payload.m` | Converts an XGTC payload size to on-wire PHY size via RS(248,232) FEC |
| `Event1.m` | Builds/broadcasts the downstream `BWmap` |
| `Event2.m` | ONU response to a received `BWmap`: forms and sends its upstream XGTC burst |
| `Event3.m` | XGTC burst arrival at the OLT; updates throughput/delay/PDV metrics |
| `Event4.m` | Termination event; finalizes all output metrics |
| `Event5.m` | Reserved for debugging (periodic mean-delay sampling, unused in final stats) |
| `Event6.m` | CBR packet arrival |
| `Event7.m` | VBR packet arrival |
| `Form_Traffic.m` | Builds the `Traffic` struct (CBR parameters + VBR empirical distributions) |
| `Extract_Distribution.m` | Builds packet-size/inter-arrival PMFs from a processed capture (`Output.txt`) |
| `RNG.m` | Samples a value from an arbitrary empirical PMF |
| `Set_PDT.m` | Places ONUs (uniform 20–60 km) and computes their propagation delay |
| `Jain_Index.m` | Jain's fairness index of a vector |
| `disable_fprintf.ps1` / `enable_fprintf.ps1` | Bulk toggle debug `fprintf` traces on/off (Windows) |
| `Traffic/INFO.txt` | Index of traffic-capture subfolders |
| `Traffic/Extract_OutputTXT.m` | Converts a raw Wireshark dissection export into the `Output.txt` format `Extract_Distribution.m` expects |
| `Traffic/1/` | A 720p H.264 (2 Mbit/s) capture, already processed into `Output.txt`, plus `Calculate_Throughput_of_Traffic.m` (a standalone sanity-check script reporting the capture's average throughput) |

## Known limitations and deviations from G.987.3

The thesis (Appendix A.1) documents several deliberate simplifications made
for tractability; they still apply to this code:

- Each ONU has exactly one Alloc-ID (no T-CONT types or per-flow priority
  classes — all traffic for an ONU is treated the same way).
- Fiber propagation speed is fixed at 70% of `c`.
- Of the standard's full traffic descriptor, only `R_F` and `R_A` are
  modeled, and they're shared by every AllocID.
- 24 bytes are subtracted from the per-frame capacity `C` for every ONU,
  assuming each ONU sends exactly one burst per 125 µs frame.
- The downstream channel is simplified to just the periodic `BWmap`
  broadcast — no XGEM frames, XGEM Port-IDs, or OMCI/PLOAM timing
  relationships are modeled downstream, and processing time at every network
  element is assumed negligible.

Repo-specific quirks worth knowing before extending the code:

- `Buffer_Size` is hardcoded to `Inf` in `XGPON.m`, so ONU queues never
  overflow — `Packet_Loss_Ratio` will always compute to 0 as currently
  configured.
- Only one VBR traffic profile is wired up even though the architecture
  (event IDs, `Traffic/INFO.txt`) supports several (see
  [Traffic model](#traffic-model)).
- `Event7.m` is excluded from `disable_fprintf.ps1`/`enable_fprintf.ps1`'s
  file lists.

## Citation

If you use this simulator or the PAS scheme, please cite:

```
C. Dalamagkas, "Design of a Market Mechanism for Dynamic Bandwidth Allocation
on XG-PON," Diploma Thesis, Dept. of Electrical and Computer Engineering,
University of Western Macedonia, 2017.

C. Dalamagkas, P. Sarigiannidis, I. Moscholios, T. Lagkas and M. S. Obaidat,
"PAS: A Fair Game-Driven DBA Scheme for XG-PON Systems," 2018 IEEE
International Conference on Communications (ICC), 2018.
```

## License

[GNU General Public License v3.0](LICENSE).
