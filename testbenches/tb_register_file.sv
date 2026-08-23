`timescale 1ns/1ps

module tb_register_file();

	localparam T = 20;
	
	logic CLK, RST_n;
	logic [4:0] rReg1, rReg2, wReg;
	logic RegWrite;
	logic [31:0] wData, rData1, rData2;
	
	
	register_file duv(
		.CLK(CLK),
		.RST_n(RST_n),
		.readReg1(rReg1),
		.readReg2(rReg2),
		.writeReg(wReg),
		.writeData(wData),
		.RegWrite(RegWrite),
		.readData1(rData1),
		.readData2(rData2)
	);
	
	
	always
	begin
		#(T/2) CLK = ~CLK;
	end
	
	
	task x0_zero;
		begin
			RST_n = 0;
			RegWrite = 1;
			wReg = 0;
			wData = 32'h000000A1;
			rReg1 = 0;
			@(negedge CLK);
			RST_n = 1;
			assert (rData1 == 0) else $error("Register x0 is not zero");
		end
	endtask
	
	
	task correct_write;
		begin
			wReg  = 5'b01101;
			wData = 32'h0000A234;
			repeat(2) @(negedge CLK);
			rReg1 = 5'b01101;
			@(negedge CLK);
			assert (rData1 == 32'h0000A234) else $error("Write operation failed");
			
		end
	endtask

		
	task simultaneous_read_write;
		begin
			RegWrite = 1;
			wReg = 5'b10000;
			wData = 32'h00001234;
			@(negedge CLK);
			wReg = 5'b11000;
			wData = 32'h00002345;
			@(negedge CLK);
			rReg1 = 5'b10000;
			rReg2 = 5'b11000;
			@(negedge CLK);
			assert (rData1 == 32'h00001234 && rData2 == 32'h00002345) else $error("Simultaneous read failed");
		end
	endtask
			
			
	initial
	begin
		CLK = 0;
		RegWrite = 0;
		rReg1 = 0;
		rReg2 = 0;
		wReg = 0;
		wData = 0;
		@(negedge CLK);
		x0_zero();
		@(negedge CLK);
		correct_write();
		@(negedge CLK);
		simultaneous_read_write();
		@(negedge CLK);
		$display("Test finished");
		$stop;
	end
	
endmodule
