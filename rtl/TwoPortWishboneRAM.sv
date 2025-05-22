`timescale 1ns/1ps
`default_nettype        none

module TwoPortWishboneRAM (
    input logic clk_i,
    input logic rst_n_i,

    input logic pA_wb_stb_i,
    input logic pB_wb_stb_i,

    input logic [8:0] pA_wb_addr_i,
    input logic [8:0] pB_wb_addr_i,
    
    input logic [3:0] pA_wb_we_i,
    input logic [3:0] pB_wb_we_i,
    
    input logic [31:0] pA_wb_data_i,
    input logic [31:0] pB_wb_data_i,

    output logic pA_wb_stall_o,
    output logic pB_wb_stall_o,

    output logic pA_wb_ack_o,
    output logic pB_wb_ack_o,

    output logic [31:0] pA_wb_data_o,
    output logic [31:0] pB_wb_data_o
);

logic [3:0] Ram_0_WE0;
logic [3:0] Ram_1_WE0;

logic Ram_0_EN0;
logic Ram_1_EN0;

logic [31:0] Ram_0_Di0;
logic [31:0] Ram_1_Di0;

logic [31:0] Ram_0_Do0;
logic [31:0] Ram_1_Do0;

logic [7:0] Ram_0_A0;
logic [7:0] Ram_1_A0;

logic pA_Ram_sel;
logic pB_Ram_sel;
logic [7:0] pA_Ram_A0;
logic [7:0] pB_Ram_A0;

logic next_port_priority;
logic next_pA_wb_ack_o;
logic next_pB_wb_ack_o;

logic port_priority;

assign pA_Ram_sel = pA_wb_addr_i[8];
assign pB_Ram_sel = pB_wb_addr_i[8];
assign pA_Ram_A0 = pA_wb_addr_i[7:0];
assign pB_Ram_A0 = pB_wb_addr_i[7:0];

assign pA_wb_data_o = pA_Ram_sel ? Ram_1_Do0 : Ram_0_Do0;
assign pB_wb_data_o = pB_Ram_sel ? Ram_1_Do0 : Ram_0_Do0;

DFFRAM256x32 Ram_0 (
    .CLK(clk_i),
    .WE0(Ram_0_WE0),
    .EN0(Ram_0_EN0),
    .Di0(Ram_0_Di0),
    .Do0(Ram_0_Do0),
    .A0(Ram_0_A0)
);

DFFRAM256x32 Ram_1 (
    .CLK(clk_i),
    .WE0(Ram_1_WE0),
    .EN0(Ram_1_EN0),
    .Di0(Ram_1_Di0),
    .Do0(Ram_1_Do0),
    .A0( Ram_1_A0)
);

always_comb begin
    Ram_0_EN0 = 0;
    Ram_1_EN0 = 0;

    Ram_0_WE0 = 0;
    Ram_1_WE0 = 0;

    Ram_0_A0 = 0;
    Ram_1_A0 = 0;

    Ram_0_Di0 = 0;
    Ram_1_Di0 = 0;

    next_port_priority = 0;
    
    next_pA_wb_ack_o = 0;
    next_pB_wb_ack_o = 0;

    pA_wb_stall_o = 0;
    pB_wb_stall_o = 0;


    if (pA_wb_stb_i & pB_wb_stb_i) begin
        if (pA_Ram_sel ^ pB_Ram_sel) begin // no conflict of ports
            Ram_0_EN0 = 1;
            Ram_1_EN0 = 1;

            Ram_0_A0 = pB_Ram_sel ? pA_Ram_A0 : pB_Ram_A0;
            Ram_1_A0 = pA_Ram_sel ? pA_Ram_A0 : pB_Ram_A0;

            Ram_0_WE0 = pB_Ram_sel ? pA_wb_we_i : pB_wb_we_i;
            Ram_1_WE0 = pA_Ram_sel ? pA_wb_we_i : pB_wb_we_i;

            Ram_0_Di0 = pB_Ram_sel ? pA_wb_data_i : pB_wb_data_i;
            Ram_1_Di0 = pA_Ram_sel ? pA_wb_data_i : pB_wb_data_i;

            next_port_priority = port_priority;
            
            next_pA_wb_ack_o = 1;
            next_pB_wb_ack_o = 1;
        end
        else begin // port conflict
            Ram_0_EN0 = ~pA_Ram_sel;
            Ram_1_EN0 =  pA_Ram_sel;

            Ram_0_A0 = port_priority ? pB_Ram_A0 : pA_Ram_A0;
            Ram_1_A0 = port_priority ? pB_Ram_A0 : pA_Ram_A0;

            Ram_0_WE0 = port_priority ? pB_wb_we_i : pA_wb_we_i;
            Ram_1_WE0 = port_priority ? pB_wb_we_i : pA_wb_we_i;

            Ram_0_Di0 = port_priority ? pB_wb_data_i : pA_wb_data_i;
            Ram_1_Di0 = port_priority ? pB_wb_data_i : pA_wb_data_i;

            next_port_priority = ~port_priority;
            
            next_pA_wb_ack_o = ~port_priority;
            next_pB_wb_ack_o =  port_priority;

            pA_wb_stall_o =  port_priority;
            pB_wb_stall_o = ~port_priority;

        end
    end
    else if (pA_wb_stb_i) begin
        Ram_0_EN0 = ~pA_Ram_sel;
        Ram_1_EN0 =  pA_Ram_sel;

        Ram_0_A0 = pA_Ram_A0;
        Ram_1_A0 = pA_Ram_A0;

        Ram_0_WE0 = pA_wb_we_i;
        Ram_1_WE0 = pA_wb_we_i;

        Ram_0_Di0 = pA_wb_data_i;
        Ram_1_Di0 = pA_wb_data_i;

        next_port_priority = 1;
        
        next_pA_wb_ack_o = 1;
    end
    else if (pB_wb_stb_i) begin
        Ram_0_EN0 = ~pB_Ram_sel;
        Ram_1_EN0 =  pB_Ram_sel;

        Ram_0_A0 = pB_Ram_A0;
        Ram_1_A0 = pB_Ram_A0;

        Ram_0_WE0 = pB_wb_we_i;
        Ram_1_WE0 = pB_wb_we_i;

        Ram_0_Di0 = pB_wb_data_i;
        Ram_1_Di0 = pB_wb_data_i;

        next_port_priority = 0;
        
        next_pB_wb_ack_o = 1;
    end
    else begin // no transaction
        
    end
end

always_ff @( posedge clk_i ) begin
    if (~rst_n_i) begin
        pA_wb_ack_o <= 0;
        pB_wb_ack_o <= 0;
        
        port_priority <= 0;
    end
    else begin
        port_priority <= next_port_priority;

        pA_wb_ack_o <= next_pA_wb_ack_o;
        pB_wb_ack_o <= next_pB_wb_ack_o;

        port_priority <= next_port_priority;
    end
end


    
endmodule