`timescale 1ns/1ps
`default_nettype        none


module tb_ram;
`ifdef USE_POWER_PINS
    wire VPWR;
    wire VGND;
    assign VPWR=1;
    assign VGND=0;
`endif

// IO 
logic           clk_i;
logic           rst_n_i;
logic           pA_wb_stb_i;
logic           pB_wb_stb_i;
logic [8:0]     pA_wb_addr_i;
logic [8:0]     pB_wb_addr_i;
logic [3:0]     pA_wb_we_i;
logic [3:0]     pB_wb_we_i;
logic [31:0]    pA_wb_data_i;
logic [31:0]    pB_wb_data_i;

logic           pA_wb_stall_o;
logic           pB_wb_stall_o;
logic           pA_wb_ack_o;
logic           pB_wb_ack_o;
logic [31:0]    pA_wb_data_o;
logic [31:0]    pB_wb_data_o;

// Instantiate Design 
TwoPortWishboneRAM RAM (.*);


// Sample to drive clock
localparam CLK_PERIOD = 40;
always begin
    #(CLK_PERIOD/2) 
    clk_i<=~clk_i;
end

// Necessary to create Waveform
initial begin
    // Name as needed
    $dumpfile("tb_ram.vcd");
    $dumpvars(0);
end

always begin
    clk_i <= 0;
    rst_n_i <= 0;

    @(posedge clk_i);
    // $display("Time = %0t", $time);

    rst_n_i <= 1;

    pA_wb_stb_i <= 1;
    pA_wb_addr_i <= 0;
    pA_wb_we_i <= 'hf;
    pA_wb_data_i <= 'h1234abcd;
    
    pB_wb_stb_i <= 1;
    pB_wb_addr_i <= 8;
    pB_wb_we_i <= 'hf;
    pB_wb_data_i <= 'hdeadbeef;

    #1;
    assert(pA_wb_stall_o == 0)          else $error("A should NOT be stalling");
    assert(pB_wb_stall_o == 1)          else $error("B should be stalling");

    @(posedge clk_i);
    pA_wb_addr_i <= 0;
    pA_wb_we_i <= 'h0;
    pA_wb_data_i <= 'h0;

    #1;
    assert(pA_wb_ack_o == 1)            else $error("A should be acking a write");

    assert(pA_wb_stall_o == 1)          else $error("A should be stalling");
    assert(pB_wb_stall_o == 0)          else $error("B should NOT be stalling");

    @(posedge clk_i);
    pB_wb_addr_i <= 8;
    pB_wb_we_i <= 'h0;
    pB_wb_data_i <= 'h0;

    #1;
    assert(pB_wb_ack_o == 1)            else $error("B should be acking a write");

    assert(pA_wb_stall_o == 0)          else $error("A should NOT be stalling");
    assert(pB_wb_stall_o == 1)          else $error("B should be stalling");

    @(posedge clk_i);

    #1;
    assert(pA_wb_ack_o == 1)            else $error("A should be acking a read");
    assert(pA_wb_data_o == 'h1234abcd)  else $error("expected: %x, got: %x\n", 'h1234abcd, pA_wb_data_o);

    assert(pA_wb_stall_o == 1)          else $error("A should be stalling");
    assert(pB_wb_stall_o == 0)          else $error("B should NOT be stalling");
    
    @(posedge clk_i);

    #1;
    assert(pB_wb_ack_o == 1)            else $error("A should be acking a read");
    assert(pB_wb_data_o == 'hdeadbeef)  else $error("expected: %x, got: %x\n", 'hdeadbeef, pB_wb_data_o);

    @(negedge clk_i);
    pA_wb_stb_i <= 0;
    pA_wb_addr_i <= 0;
    pA_wb_we_i <= 'h0;
    pA_wb_data_i <= 'h0;
    
    pB_wb_stb_i <= 0;
    pB_wb_addr_i <= 0;
    pB_wb_we_i <= 'h0;
    pB_wb_data_i <= 'h0;

    $finish();
end

endmodule