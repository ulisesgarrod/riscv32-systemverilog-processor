`timescale 1ns/1ps

module tb_TOP_RISCV_pipeline_hazards();

	localparam T = 20;
	
	logic CLOCK, RST_n;
	
	
	TOP_RISCV_pipeline_hazards duv (
		.CLOCK(CLOCK),
		.RST_n(RST_n)
	);
	
	
	always
	begin
		#(T/2) CLOCK = ~CLOCK;
	end
	
	initial
	begin
		CLOCK = 0;
		RST_n = 0;
		@(negedge CLOCK);
		RST_n = 1;
		repeat(2000) @(negedge CLOCK);
		$display("Test finished");
		$stop;
	end
	
endmodule
