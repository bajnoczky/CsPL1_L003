# Virtual OT monitoring proof of concept

A school team project: a simulated water-tank PLC with Modbus/TCP communication,
an operator interface, and planned Linux-based passive monitoring.

The current workflow uses **one MATLAB session on Windows**:
**plc_panel** runs the server and displays the tank; **Modbus Explorer** reads
and writes its registers. See [TEAM_PLAN.md](TEAM_PLAN.md) for the planned WSL2
relay, sensor, rules, event log, and dashboard. Those components are not yet
implemented. Work is currently on the local `proof-of-concept` branch.

## Requirements

- MATLAB R2022a or newer; the prototype has been run on R2026a.
- Instrument Control Toolbox for the TCP server.
- Industrial Communication Toolbox for Modbus Explorer.

Toolboxes must be installed, not just included in your license. Check
`which tcpserver` and `which modbusExplorer`; install missing products through
MATLAB Add-Ons. No physical PLC, Python, WSL, or Simulink is needed for the
current local demo.

## Start the server panel

Open **VirtualOTLab.prj** in MATLAB, or run from the repository folder:

```matlab
openProject('VirtualOTLab.prj')
plc_panel
```

Opening the project adds `matlab` to the path. You can also use its **Open PLC
panel** shortcut. No manual `addpath` is required, and opening the project
does not start the server.

1. Leave the bind IP at **127.0.0.1** and port at **1502**.
2. Click **Start server**.
3. Open Modbus Explorer in the same MATLAB session.

The panel shows the connected client's IP, water level, target line,
controller state, and pump state. Its tank display reads local simulation
state and does not consume a Modbus connection. Process commands stay in
Explorer.

**Stop server** releases the connection. Closing the panel also stops its
timer and server. Starting again resets the tank to 30%, with a 60% target
and the controller enabled. Reconnect Explorer after restarting the server.
If the port is already in use, stop the other server or select a free port.

## Connect Modbus Explorer

Open **Apps > Modbus Explorer**, or enter:

```matlab
modbusExplorer
```

Choose Modbus TCP/IP and configure:

| Setting | Value |
| --- | --- |
| Device address | `127.0.0.1` |
| Port | `1502` |
| Timeout | `3` seconds |
| Server ID | `1` |
| Register type | Holding register |
| Initial register address | `1` |
| Precision | `uint16` |
| Byte order | Big Endian |

Click **Read**, then **Confirm Parameters**. Click **Import** and select
**config/tank_registers.mat** to load all four named registers. Import replaces
the existing read table. Click **Resume Reads** for live values and plots.

You can edit each row's **Name** column and use **Export** to save your table.
Names are display labels; communication still uses addresses. For a clear
level plot, show water level and target together and hide the boolean values.

Use Explorer's write section to change the target at address 2 or the
controller enable at address 3. The server accepts **one client connection**;
disconnect any previous Explorer connection before opening another.

## Tank behaviour and register map

The outlet always drains **2 percentage points per second**. When the pump is
on, it supplies **8 points per second**, giving a net increase of **6 points
per second**. The level is clamped to 0–100%.

With automatic control enabled, the pump turns on at **target minus 3 points**
(or zero for targets below 3) and turns off at the target. Between those
thresholds it keeps its previous state. A target of zero keeps it off.
Disabling the controller immediately turns off the pump while draining
continues. Stopping the server stops the simulation entirely.

All registers use unsigned 16-bit integers; the reported level is rounded.

| MATLAB address | Wire offset | Explorer name | Access | Values |
| --- | --- | --- | --- | --- |
| 1 | 0 | WaterLevel_pct | Read | 0–100 |
| 2 | 1 | TargetLevel_pct | Read/write | 0–100 |
| 3 | 2 | ControllerEnabled | Read/write | 0 or 1 |
| 4 | 3 | PumpRunning | Read | 0 or 1 |

MATLAB uses 1-based addresses and subtracts one on the wire. The server supports
function codes 03 (read holding registers), 06 (write single register), and
16 (write multiple registers). Invalid requests receive exceptions; other
unit IDs are ignored. An invalid MBAP header blocks processing until reconnect.

## Repository layout

| Location | Purpose |
| --- | --- |
| `matlab/plc_panel.m` | Server controls and tank display |
| `matlab/TankServer.m` | TCP connection, timing, and request handling |
| `matlab/TankPLC.m` | Tank model, pump logic, and Modbus protocol subset |
| `matlab/export_register_map.m` | Regenerate the Explorer import file |
| `config/tank_registers.mat` | Named registers for Explorer |
| `VirtualOTLab.prj`, `resources/project/` | MATLAB project paths, files, and shortcut |
| `TEAM_PLAN.md` | Remaining work and proposed WSL2 architecture |

Keep the project XML metadata and register-map MAT file in Git; they are
required project assets. Local scratch output, root log files, editor backups,
and workspace dumps are ignored. To regenerate the register map, open the
project and run `export_register_map`.

Automated tests and command-line demo scripts are deferred to a later team
task. For a quick manual check, change the target in Explorer, disable the
controller to observe draining, then enable it again and watch the panel.

## Current scope

This is a small PLC stand-in with approximate desktop timing, not an
IEC 61131-3 runtime or a complete Modbus implementation. The default endpoint
is local to this computer. The planned WSL relay will use a separate port
(1503); continue using 1502 until it is implemented. Network isolation and
passive capture remain integration tasks described in the team plan.

## References

- [MATLAB TCP server](https://www.mathworks.com/help/instrument/tcpserver.html)
- [Modbus Explorer](https://www.mathworks.com/help/icomm/ug/modbusexplorer-app.html)
- [MATLAB Projects](https://www.mathworks.com/help/matlab/matlab_prog/create-projects.html)
- [Modbus specifications](https://www.modbus.org/modbus-specifications)
- [Team Git guide (Hungarian)](GIT_GUIDE.md)
