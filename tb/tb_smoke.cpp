#include "Vagent_npu_top.h"
#include "verilated.h"
#include <iostream>

// 一个最基础的 clock tick
static void tick(Vagent_npu_top* dut) {
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // 创建 DUT（Device Under Test）
    Vagent_npu_top* dut = new Vagent_npu_top;

    // 初始状态
    dut->clk   = 0;
    dut->rst_n = 0;
    dut->mmio_valid = 0;
    dut->mmio_write = 0;
    dut->mmio_addr  = 0;
    dut->mmio_wdata = 0;
    dut->mmio_wstrb = 0;


    // 复位阶段
    for (int i = 0; i < 5; i++) {
        tick(dut);
    }

    // 释放复位
    dut->rst_n = 1;

    // 正常运行几个 cycle
    for (int i = 0; i < 20; i++) {
        tick(dut);
    }

    std::cout << "SMOKE OK" << std::endl;

    delete dut;
    return 0;
}
