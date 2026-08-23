`timescale 1ns/1ps

module tb_ROM();

	localparam T = 20;

	parameter WIDTH = 32;
	parameter DEPTH = 1024;

	logic [$clog2(DEPTH)-1:0] addr;
	logic [WIDTH-1:0] dout;
	logic CLK;

	ROM duv(
		.addr(addr),
		.dout(dout)
	);

	always
	begin
		#(T/2) CLK = ~CLK;
	end


	task correct_read;
		begin
			// Initialize ROM contents directly
			duv.mem[0] = 32'h10000197;
			duv.mem[1] = 32'h0001A383;
			duv.mem[2] = 32'h00818413;
			duv.mem[3] = 32'h00418493;

			addr = 10'd0;
			#3;
			assert (dout == 32'h10000197) else $error("Read error at address 0");

			addr = 10'd1;
			#3;
			assert (dout == 32'h0001A383) else $error("Read error at address 1");

			addr = 10'd2;
			#3;
			assert (dout == 32'h00818413) else $error("Read error at address 2");

			addr = 10'd3;
			#3;
			assert (dout == 32'h00418493) else $error("Read error at address 3");
		end
	endtask


	initial
	begin
		CLK = 0;
		addr = 0;

		correct_read();

		@(negedge CLK);
		$display("Simulation finished");
		$stop;
	end

endmodule