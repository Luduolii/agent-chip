module agent_npu_regs (
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
    localparam logic [31:0] ID = 32'h4E50_5531; // "NPU1"

    assign mmio_ready  = 1'b1;
    assign mmio_rvalid = mmio_valid & ~mmio_write;

    always_comb begin
        if (mmio_addr == 16'h000)
            mmio_rdata = ID;
        else
            mmio_rdata = 32'd0;
    end

endmodule
