module agent_npu_top (
    input  logic clk,
    input  logic rst_n,

    // MMIO request
    input  logic        mmio_valid,
    input  logic        mmio_write,
    input  logic [15:0] mmio_addr,
    input  logic [31:0] mmio_wdata,
    input  logic [3:0]  mmio_wstrb,

    // MMIO response
    output logic        mmio_ready,
    output logic [31:0] mmio_rdata,
    output logic        mmio_rvalid
);

    agent_npu_regs u_regs (
        .clk(clk),
        .rst_n(rst_n),

        .mmio_valid(mmio_valid),
        .mmio_write(mmio_write),
        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_wstrb(mmio_wstrb),

        .mmio_ready(mmio_ready),
        .mmio_rdata(mmio_rdata),
        .mmio_rvalid(mmio_rvalid)
    );

endmodule
