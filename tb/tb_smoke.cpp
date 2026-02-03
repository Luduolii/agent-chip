#include "Vagent_npu_top.h"
#include "verilated.h"
#include <iostream>
#include <cassert>

// Single clock tick
static void tick(Vagent_npu_top* dut) {
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
}

// MMIO register addresses (from agent_npu_regs.sv)
static const unsigned ADDR_CTRL       = 0x00C;
static const unsigned ADDR_STATUS    = 0x010;
static const unsigned ADDR_IRQ_STATUS = 0x018;
static const unsigned ADDR_DOORBELL   = 0x01C;

static void mmio_write(Vagent_npu_top* dut, unsigned addr, uint32_t data) {
    dut->mmio_valid = 1;
    dut->mmio_write = 1;
    dut->mmio_addr  = addr & 0xFFFF;
    dut->mmio_wdata = data;
    dut->mmio_wstrb = 0xF;
    tick(dut);
    dut->mmio_valid = 0;
    dut->mmio_write = 0;
}

static uint32_t mmio_read(Vagent_npu_top* dut, unsigned addr) {
    dut->mmio_valid = 1;
    dut->mmio_write = 0;
    dut->mmio_addr  = addr & 0xFFFF;
    tick(dut);
    uint32_t r = dut->mmio_rdata;
    dut->mmio_valid = 0;
    return r;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vagent_npu_top* dut = new Vagent_npu_top;

    dut->clk   = 0;
    dut->rst_n = 0;
    dut->mmio_valid = 0;
    dut->mmio_write = 0;
    dut->mmio_addr  = 0;
    dut->mmio_wdata = 0;
    dut->mmio_wstrb = 0;

    // Reset
    for (int i = 0; i < 5; i++) {
        tick(dut);
    }
    dut->rst_n = 1;

    // Brief run to stabilize
    for (int i = 0; i < 5; i++) {
        tick(dut);
    }

    // --- Doorbell / BUSY / DONE / W1C directed sequence ---
    // 1. Enable NPU and IRQ (CTRL: ENABLE=1, IRQ_EN=1)
    mmio_write(dut, ADDR_CTRL, 1 | (1u << 2));

    // 2. Ring doorbell
    mmio_write(dut, ADDR_DOORBELL, 1);

    // 3. Poll STATUS until BUSY
    {
        int i;
        for (i = 0; i < 30; i++) {
            uint32_t s = mmio_read(dut, ADDR_STATUS);
            if (s & 2) break;  // STATUS.BUSY
            tick(dut);
        }
        assert(i < 30 && "STATUS.BUSY did not assert");
    }

    // 4. Poll STATUS until !BUSY (stub takes 8 cycles)
    {
        int i;
        for (i = 0; i < 30; i++) {
            uint32_t s = mmio_read(dut, ADDR_STATUS);
            if (!(s & 2)) break;
            tick(dut);
        }
        assert(i < 30 && "STATUS.BUSY did not clear");
    }

    // 5. Poll IRQ_STATUS until DONE
    {
        int i;
        for (i = 0; i < 30; i++) {
            uint32_t irq = mmio_read(dut, ADDR_IRQ_STATUS);
            if (irq & 1) break;  // DONE
            tick(dut);
        }
        assert(i < 30 && "IRQ_STATUS.DONE did not set");
    }

    // 6. W1C: clear DONE by writing 1 to bit 0
    mmio_write(dut, ADDR_IRQ_STATUS, 1);

    // 7. Verify DONE is cleared
    uint32_t irq_after = mmio_read(dut, ADDR_IRQ_STATUS);
    assert(!(irq_after & 1) && "IRQ_STATUS.DONE not cleared by W1C");

    std::cout << "SMOKE OK" << std::endl;

    delete dut;
    return 0;
}
