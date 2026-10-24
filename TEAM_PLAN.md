# Team plan: virtual OT monitoring demo

**Goal:** a small, repeatable demonstration of a simulated industrial process,
passive Modbus monitoring, rule-based alerts, and an event dashboard.

## Proposed setup

Use **MATLAB on Windows + Ubuntu in WSL2**:

```text
Windows Modbus Explorer -> WSL TCP relay (:1503) -> Windows MATLAB PLC (:1502)
                                  |
                      TShark -> rules -> CSV log -> dashboard
```

- Keep the existing MATLAB project, server panel, and Explorer on Windows.
- In WSL, run a TCP relay, TShark, a small Python rules/logger, and Streamlit.
- Explorer connects through the relay so the traffic actually passes through
  Linux. Direct Windows-to-Windows loopback traffic is not our capture path.
- The relay forwards bytes; the separate sensor only observes packets and
  never polls or controls the PLC. Capture one relay leg to avoid duplicate events.
- No physical PLC or connection to a real OT network.

**Networking to verify first:** choose the WSL networking mode and reachable
addresses, bind the PLC accordingly, and restrict access to the demo endpoints.
WSL does not automatically provide an isolated OT network; confirm this setup
meets the lecturer's expectation. A conventional Linux VM with a host-only
network remains the fallback if stronger separation is required.

The PLC sees the relay as its client. Original client identity must come from
the client-facing capture, not the PLC's connection-status display.

## Already working locally

- MATLAB tank simulation, automatic pump control, and Modbus/TCP server.
- Server panel: Start/Stop, IP/port, client status, and tank graphic.
- Named register import for Explorer; panel + Explorer are the current workflow.
- Local `proof-of-concept` branch; the WSL relay/capture path is not yet verified.

## Remaining TODOs

| Work package | Minimum deliverable |
| --- | --- |
| WSL and networking | Install WSL2/Ubuntu, TShark, relay, and Python dependencies; verify reachability and access restrictions. MATLAB stays on Windows. |
| Relay and passive sensor | Forward WSL port 1503 to Windows PLC port 1502. Identify the capture interface; decode Modbus on the client-facing leg and extract timestamps, endpoints, operations, registers/values, and exceptions. |
| Rules and log | Record decoded events and alerts in CSV; make thresholds configurable. |
| Demo scenarios | Script an invalid target write, a burst of reads, and a pause in communication. |
| Dashboard | Show recent operations/alerts, request rate, last communication, and log download. |
| Verification (later) | Add automated checks for PLC logic, network requests, panel lifecycle, and the complete monitoring workflow. |
| Integration and handover | Write a repeatable Windows + WSL setup/launch guide and run the full demo. |

**First integration milestone:** one Explorer register write appears correctly
in the Linux capture. Build rules and the dashboard after that works.

## Final demonstration

1. Start the PLC, relay, sensor, dashboard, and Explorer; show normal operation.
2. Send an out-of-range target; log the attempted write and PLC rejection.
3. Generate excess requests; show a rate alert.
4. Pause client communication; show “no traffic observed for X seconds.”
5. Show the timestamped event log and dashboard alerts.

Keep scope small: three rules, one dashboard page, no machine learning.
Agree owners for the work packages and a shared integration date at the meeting.
