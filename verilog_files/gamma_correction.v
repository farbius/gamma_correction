////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 14/05/18
// Design Name: gamma_correction
////////////////////////////////////////////////////////////////////////////////

module gamma_correction
(   input clk,
    input rst,
// slave axi stream interface   
    input s_axis_tvalid,
    input s_axis_tuser,
    input s_axis_tlast,
    input [24 - 1  : 0] s_axis_tdata,
// master axi stream interface    
    output m_axis_tvalid,
    output m_axis_tuser,
    output m_axis_tlast,
    output [23 : 0] m_axis_tdata,
// I2C loading packet
    input SOP,
    input EOP,
    input VLD,
    input [7 : 0] packet_data   
     );
     
   reg [7 : 0] address; 
   
   always@(posedge clk) 
        if(rst)     address <= 0;
        else if(SOP & VLD)address <= 0;
        else if(EOP & VLD)address <= 8'd255;
        else if(VLD)address <= address + 1;
    
    wire  [7 : 0] m_axis_tdata_1streg;
    wire  [7 : 0] m_axis_tdata_2ndreg;
    wire  [7 : 0] m_axis_tdata_3rdreg;
    
       BRAM_Memory_24x24 #(8) i0 (.a_clk(clk), .a_wr(VLD), .a_addr(address), .a_data_in(packet_data), .a_data_out(), 
       .b_clk(clk), .b_wr(1'b0), .b_addr(s_axis_tdata[7 : 0]), .b_data_in(), .b_data_out(m_axis_tdata_1streg), .b_data_en(1'b1));
       
       BRAM_Memory_24x24 #(8) i1 (.a_clk(clk), .a_wr(VLD), .a_addr(address), .a_data_in(packet_data), .a_data_out(), 
       .b_clk(clk), .b_wr(1'b0), .b_addr(s_axis_tdata[15 : 8]), .b_data_in(), .b_data_out(m_axis_tdata_2ndreg), .b_data_en(1'b1));
       
       BRAM_Memory_24x24 #(8) i2 (.a_clk(clk), .a_wr(VLD), .a_addr(address), .a_data_in(packet_data), .a_data_out(), 
       .b_clk(clk), .b_wr(1'b0), .b_addr(s_axis_tdata[23 : 16]), .b_data_in(), .b_data_out(m_axis_tdata_3rdreg), .b_data_en(1'b1));
      
      
     localparam ShiftSteps = 6;  
     
        reg [ShiftSteps : 0] s_axis_tvalid_shift; // piplined s_axis_tvalid
        always @(posedge clk) 
        if(rst)s_axis_tvalid_shift <= 0;
        else   s_axis_tvalid_shift <= {s_axis_tvalid_shift[ShiftSteps - 1 : 0], s_axis_tvalid};
        
        reg [ShiftSteps : 0] s_axis_tlast_shift; // piplined s_axis_tlast
        always @(posedge clk) 
        if(rst)s_axis_tlast_shift <= 0;
        else   s_axis_tlast_shift <= {s_axis_tlast_shift[ShiftSteps - 1 : 0], s_axis_tlast};
        
        reg [ShiftSteps : 0] s_axis_tuser_shift; // piplined s_axis_tuser
        always @(posedge clk) 
        if(rst)s_axis_tuser_shift <= 0;
        else   s_axis_tuser_shift <= {s_axis_tuser_shift[ShiftSteps - 1 : 0], s_axis_tuser};     
        
        // piplined axi stream interface
        assign m_axis_tvalid   = s_axis_tvalid_shift[0];
        assign m_axis_tlast    = s_axis_tlast_shift[0];
        assign m_axis_tuser    = s_axis_tuser_shift[0];
        assign m_axis_tdata    = {m_axis_tdata_3rdreg, m_axis_tdata_2ndreg, m_axis_tdata_1streg};
   
    
    
    
    
    
endmodule
