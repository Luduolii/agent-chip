# Agent-Chip Architecture (Week 1)

## Positioning
- This project builds a command-driven NPU device model with Verilator-based DV.
- A GPU-style baseline (HIP/ROCm) will be added later for comparison on agent-style workloads.
- Week 1 focus: control-plane bring-up (MMIO regs + doorbell + observable status/perf placeholders).

## Block diagram (Week 1: current RTL)
Host/Testbench
  |
  | MMIO (read/write)
  v
agent_npu_top
  |
  v
agent_npu_regs (ID/VERSION/CTRL/STATUS/IRQ_STATUS/DOORBELL/PERF_*)

## Block diagram (roadmap target, W3–W8)
This is the intended end-state implied by the roadmap (W3 GEMM, W4 SPAD+DMA+queue, W6 overlap, W7/W8 fusion/pipeline).

```
                    +------------------------------+
                    |        Host software         |
                    |  driver/runtime/testbench    |
                    +---------------+--------------+
                                    |
                                    | MMIO (regs, doorbell)
                                    v
                         +----------+-----------+
                         |      agent_npu_top   |
                         |----------------------|
                         |  agent_npu_regs      |
                         |  - CTRL/STATUS       |
                         |  - IRQ_STATUS (W1C)  |
                         |  - PERF_*            |
                         +----+------------+----+
                              |            |
                              | doorbell   | cmd queue (W4+)
                              v            v
                         +----+------------+----+
                         |   Front-end (FE)     |
                         |  - polls doorbell    |
                         |  - consumes queue    |
                         |  - dispatches cmds   |
                         +----+-------+-----+---+
                              |       |     |
                     load/store|       |compute
                              v       v     v
                        +-----+--+  +--+-----+---+
System memory <-------->|  DMA   |  | Scratchpad |
 (external)             | (W4)   |  |  SRAM (W4) |
                        +-----+--+  | double-buf |
                              |     |  (W6)      |
                              +---->|            |
                                    +-----+------+
                                          |
                                          | operands/results
                                          v
                                    +-----+------+
                                    |  Compute   |
                                    |  INT8 GEMM |
                                    |  (W3)      |
                                    |  + fusion  |
                                    |  (W7/W8)   |
                                    +------------+
```

Key idea: software submits work via a command queue and rings a doorbell; FE orchestrates DMA↔scratchpad data movement and compute; status/IRQs/perf are visible via MMIO.

## Register Map (32-bit, byte-offsets)
0x000 ID            R       0x4E505531 ("NPU1")
0x004 VERSION       R       0x00010000 (1.0)
0x00C CTRL          RW      bit0 ENABLE, bit1 RESET_CORE (reserved), bit2 IRQ_EN
0x010 STATUS        R       bit0 READY(1), bit1 BUSY, bit2 ERROR, bit3 ENABLE_MIRROR
0x018 IRQ_STATUS    RW1C    bit0 DONE, bit1 ERROR, bit2 QUEUE_EMPTY (reserved)
0x01C DOORBELL      W       write triggers FE poll (Week1: stub behavior)
0x040 PERF_CYCLES   R       cycles counter
0x044 PERF_CMDS     R       cmds executed (placeholder)
0x048 PERF_STALL    R       stall cycles (placeholder)

## Notes
- W1C: write-1-to-clear for IRQ_STATUS
- CTRL supports byte enables (WSTRB).

## Control-plane bring-up flow (Week 1 mental model)
- **Discover device**: read `ID`/`VERSION`.
- **Enable device**: set `CTRL.ENABLE` (and optionally `CTRL.IRQ_EN`).
- **Kick work**: write `DOORBELL` to notify FE (Week 1: stub; W4+: tells FE to poll the command queue).
- **Observe**: poll `STATUS` (`READY/BUSY/ERROR`) and `IRQ_STATUS` (`DONE/ERROR`), clear `IRQ_STATUS` bits by writing 1s (W1C).
