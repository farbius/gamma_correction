`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:     Riftek
// Engineer:    Alexey Rostov
// Email:       a.rostov@riftek.com 
// Create Date: 14/05/18
// Design Name: gamma_correction
////////////////////////////////////////////////////////////////////////////////
`include "parameters.vh"


module gamma_correction_tb();


    reg clk;
    reg rst;
// slave axi stream interface   
    wire s_axis_tvalid;
    wire s_axis_tuser;
    wire s_axis_tlast;
    wire [24 - 1  : 0] s_axis_tdata;
// master axi stream interface    
    wire m_axis_tvalid;
    wire m_axis_tuser;
    wire m_axis_tlast;
    wire [23 : 0] m_axis_tdata;
// I2C loading packet
    reg SOP;
    reg EOP;
    reg VLD;
    reg [7 : 0] packet_data;
	
	reg     rst_fg; // reset for frame generator module
	wire read_done;
	
	`define PERIOD 5      // 100 MHz clock 
	
	initial begin
     clk       <= 0;                              
     forever #(`PERIOD)  clk =  ! clk; 
    end

	
	gamma_correction dutB (.clk(clk),.rst(rst),.s_axis_tvalid(s_axis_tvalid),.s_axis_tuser(s_axis_tuser),.s_axis_tlast(s_axis_tlast),.s_axis_tdata(s_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),.m_axis_tuser(m_axis_tuser),.m_axis_tlast(m_axis_tlast),.m_axis_tdata(m_axis_tdata), .SOP(SOP), .EOP(EOP), .VLD(VLD), .packet_data(packet_data));
    
	frame_generator #(Nrows, Ncol) dutA (.clk(clk), .rst(rst_fg), .SOF(s_axis_tuser), .EOL(s_axis_tlast), .DVAL(s_axis_tvalid), .read_done(read_done), .pixel(s_axis_tdata)); 
	 
	 
	event reset_trigger;
    event reset_done_trigger;
    event I2C_write_done;	
	
    integer fidR, fidG, fidB;
	reg  [7 : 0] packet_data_mem [0 : 255];
	reg  [7 : 0] address;
	initial $readmemh("InputData.txt", packet_data_mem, 0, 255);
	
	initial  begin 
	@(reset_done_trigger); 
	@ (posedge clk);
	SOP = 1;
	VLD = 1;
	packet_data = packet_data_mem[address];
	repeat (254) begin
	@ (posedge clk);
	SOP = 0;
    address = address + 1;
	packet_data = packet_data_mem[address];
	end
	@ (posedge clk);
	EOP = 1;
	packet_data = packet_data_mem[255];
	@ (posedge clk);
	EOP = 0;
	VLD = 0;
	-> I2C_write_done;	
	end
	
	initial begin 
         rst    <= 1;
		 address<= 0;
		 rst_fg <= 1;
		 SOP    <= 0;
	     VLD    <= 0;
		 EOP    <= 0;
	 packet_data<= 0;
         @ (reset_trigger); 
         @ (posedge clk) rst <= 1;             
         repeat (20) begin
         @ (posedge clk); 
         end 
         rst = 0;
          -> reset_done_trigger;
    end 
	

	
		  
    initial  begin    
     fidR = $fopen("Rs_out.txt","w");
     fidG = $fopen("Gs_out.txt","w");
     fidB = $fopen("Bs_out.txt","w");
          -> reset_trigger;
          @(I2C_write_done);  
		  rst_fg = 1;
		  @ (posedge clk); 
		  @ (posedge clk);
		  rst_fg = 0;
          @(m_axis_tvalid);
		while(!read_done & m_axis_tvalid)begin
      $fwrite(fidR, "%d \n", m_axis_tdata[23 : 16]);
      $fwrite(fidG, "%d \n", m_axis_tdata[15 : 8]);
      $fwrite(fidB, "%d \n", m_axis_tdata[7  : 0]); 
      @ (posedge clk); 		
	  
        end	
	  $fclose(fidR);
      $fclose(fidG);
      $fclose(fidB);
         
         #9000 $stop;                                                
    end            


endmodule
