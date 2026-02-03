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

    logic        npu_enable;
    logic        irq_en;
    logic        doorbell_pulse;
    logic        fe_busy;
    logic        fe_error;
    logic        fe_irq_done_pulse;
    logic        fe_irq_error_pulse;
    logic [31:0] perf_cycles;
    logic [31:0] perf_cmds;
    logic [31:0] perf_stall;

    localparam int unsigned FE_LATENCY = 8;
    logic [$clog2(FE_LATENCY + 1)-1:0] fe_busy_cnt;

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
        .mmio_rvalid(mmio_rvalid),

        .npu_enable(npu_enable),
        .irq_en(irq_en),
        .doorbell_pulse(doorbell_pulse),

        .fe_busy(fe_busy),
        .fe_error(fe_error),
        .fe_irq_done_pulse(fe_irq_done_pulse),
        .fe_irq_error_pulse(fe_irq_error_pulse),

        .perf_cycles(perf_cycles),
        .perf_cmds(perf_cmds),
        .perf_stall(perf_stall)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fe_busy_cnt <= '0;
            fe_irq_done_pulse <= 1'b0;
        end else begin
            fe_irq_done_pulse <= 1'b0;
            if (fe_busy_cnt != 0) begin
                fe_busy_cnt <= fe_busy_cnt - 1'b1;
                if (fe_busy_cnt == 1) begin
                    fe_irq_done_pulse <= irq_en;
                end
            end else if (doorbell_pulse && npu_enable) begin
                fe_busy_cnt <= FE_LATENCY[$clog2(FE_LATENCY + 1)-1:0];
            end
        end
    end

    assign fe_busy = (fe_busy_cnt != 0);
    assign fe_error = 1'b0;
    assign fe_irq_error_pulse = 1'b0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            perf_cycles <= 32'd0;
            perf_cmds <= 32'd0;
            perf_stall <= 32'd0;
        end else begin
            perf_cycles <= perf_cycles + 1'b1;
            if (doorbell_pulse && npu_enable && !fe_busy) begin
                perf_cmds <= perf_cmds + 1'b1;
            end
        end
    end

endmodule
