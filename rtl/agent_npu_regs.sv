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
    output logic        mmio_rvalid,

    // outputs to "front-end" (Week1 stub)
    output logic        npu_enable,
    output logic        irq_en,
    output logic        doorbell_pulse,

    // inputs from "front-end" (Week1 stub)
    input logic         fe_busy,
    input logic         fe_error,
    input logic         fe_irq_done_pulse,
    input logic         fe_irq_error_pulse,

    // perf counters
    input logic [31:0]  perf_cycles,
    input logic [31:0]  perf_cmds,
    input logic [31:0]  perf_stall
);

    localparam logic [31:0] ID_VALUE      = 32'h4E50_5531; // "NPU1"
    localparam logic [31:0] VERSION_VALUE = 32'h00010000; // 1.0

    logic [31:0] ctrl;       // 0x00C
    logic [31:0] irq_status; // 0x018 W1C

    assign npu_enable = ctrl[0];
    assign irq_en     = ctrl[2];

    // ready/valid (simple always-ready slave)
    assign mmio_ready  = 1'b1;
    assign mmio_rvalid = mmio_valid & ~mmio_write;

    // apply byte strobe
    function automatic [31:0] apply_wstrb(
        input [31:0] oldv,
        input [31:0] newv,
        input [3:0]  wstrb
    );
        apply_wstrb = oldv;
        if (wstrb[0]) apply_wstrb[7:0] = newv[7:0];
        if (wstrb[1]) apply_wstrb[15:8] = newv[15:8];
        if (wstrb[2]) apply_wstrb[23:16] = newv[23:16];
        if (wstrb[3]) apply_wstrb[31:24] = newv[31:24];
    endfunction

    // IRQ status set by FE pulses + cleared by W1C
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_status <= 32'd0;
        end else begin
            if (fe_irq_done_pulse) irq_status[0] <= 1'b1;
            if (fe_irq_error_pulse) irq_status[1] <= 1'b1;

            if (mmio_valid && mmio_write && mmio_addr == 16'h018) begin
                // W1C
                irq_status <= irq_status & ~mmio_wdata;
            end
        end
    end

    // CTRL register write + DOORBELL write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl <= 32'd0;
            doorbell_pulse <= 1'b0;
        end else begin
            doorbell_pulse <= 1'b0; // default, 1-cycle pulse
            if (mmio_valid && mmio_write) begin
                unique case (mmio_addr)
                    16'h00C: ctrl <= apply_wstrb(ctrl, mmio_wdata, mmio_wstrb);
                    16'h01C: doorbell_pulse <= 1'b1;
                    default: ;
                endcase
            end
        end
    end

    // STATUS (Week1: simple)
    logic [31:0] status;
    always_comb begin
        status = 32'd0;
        status[0] = 1'b1;       // READY
        status[1] = fe_busy;    // BUSY from FE stub
        status[2] = fe_error;   // ERROR from FE stub
        status[3] = ctrl[0];    // ENABLE mirror (debug friendly)
    end

    // read mux
    always_comb begin
        unique case (mmio_addr)
            16'h000: mmio_rdata = ID_VALUE;
            16'h004: mmio_rdata = VERSION_VALUE;
            16'h00C: mmio_rdata = ctrl;
            16'h010: mmio_rdata = status;
            16'h018: mmio_rdata = irq_status;
            16'h040: mmio_rdata = perf_cycles;
            16'h044: mmio_rdata = perf_cmds;
            16'h048: mmio_rdata = perf_stall;
            default: mmio_rdata = 32'd0;
        endcase
    end

    
endmodule
