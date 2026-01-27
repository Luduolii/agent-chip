interface mmio_if (input logic clk);
    logic        valid;
    logic        write;
    logic [15:0] addr;
    logic [31:0] wdata;
    logic [3:0]  wstrb;

    logic        ready;
    logic [31:0] rdata;
    logic        rvalid;
endinterface
