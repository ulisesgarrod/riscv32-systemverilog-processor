`timescale 1ns/1ps

module tb_RAM();

	localparam T = 20;
	
	parameter WIDTH = 32;        
	parameter DEPTH = 1024;
	
	logic CLK, write_enable, read_enable;
	logic [$clog2(DEPTH)-1:0] addr;
	logic [WIDTH-1:0] din, dout;
	
	
	RAM duv(
		.CLK(CLK),
		.write_enable(write_enable),
		.read_enable(read_enable),
		.addr(addr),
		.din(din),
		.dout(dout)
	);
	
	
	always
	begin
		#(T/2) CLK = ~CLK;
	end
	
	
	task correct_write;
		begin
			write_enable = 1'b1;
			read_enable = 1'b1;
			addr = 10'd13;
			din = 32'hA234;
			repeat(2) @(negedge CLK);
			addr = 10'd13;
			@(negedge CLK);
			assert (dout == 32'hA234) else $error("Write operation failed");
		end
	endtask
	
	task simultaneous_read_write;
		begin
			write_enable = 1'b1;
			read_enable = 1'b1;
			addr = 10'd16;
			din = 32'h1234;
			@(negedge CLK);
			write_enable = 1'b0;
			@(negedge CLK);
			assert (dout == 32'h1234) else $error("Simultaneous read failed");
		end
	endtask
			
			
	initial
	begin
		CLK = 0;
		correct_write();
		@(negedge CLK);
		simultaneous_read_write();
		@(negedge CLK);
		$display("Simulation finished");
		$stop;
	end
	
endmodule
