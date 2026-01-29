# Agent-Chip Architecture (Week 1)

## Positioning
- This project builds a command-driven NPU device model with Verilator-based DV.
- A GPU-style baseline (HIP/ROCm) will be added later for comparison on agent-style workloads.
- Week 1 focus: control-plane bring-up (MMIO regs + doorbell + observable status/perf placeholders).

## Block Diagram (current)
Host/Testbench
  |
  | MMIO (read/write)
  v
agent_nup_top
  |
  v
agent_npu_regs (ID/VERSION/CTRL/STATUS/IRQ/DOORBELL/QUEUE/PERF placeholder)

## Register Map (32-bit, byte-offsets)
0x000 ID            R       0x4E505531 ("NPU1")
0x004 VERSION       R       0x00010000 (1.0)
0x00C CTRL          RW      bit0 ENABLE, bit1 RESET_CORE (reserved), bit2 IRQ_EN
0x010 STATUS        R       bit0 READY(1), bit1 BUSY, bit2 ERROR, bit8 ENABLE_MIRROR
0x018 IRQ_STATUS    RW1C    bit0 DONE, bit1 ERROR, bit2 QUEUE_EMPTY (reserved)
0x01C DOORBELL      W       write triggers FE poll (Week1: stub behavior)
0x040 PERF_CYCLEs   R       cycles counter
0x044 PEF_CMDS      R       cmds executed (placeholder)
0x048 PERF_STALL    R       stall cycles (placeholder)

# Notes
- W1C: write-1-to-clear for IRQ_STATUS
- CTRL supports byte enables (WSTRB).