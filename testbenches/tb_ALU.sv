`timescale 1ns/1ps

module tb_ALU();

	parameter T = 20;
	
	reg CLOCK;
	reg signed [31:0] A, B;
	reg [3:0] ALU_control;
	wire zero;
	wire [31:0] ALU_result;
	
	ALU duv
	(
		.A(A) ,
		.B(B) ,
		.ALU_control(ALU_control) ,
		.zero(zero) ,
		.ALU_result(ALU_result)
	);
	
// Clock generation
	always 
	begin 
	#(T/2) CLOCK = ~CLOCK;
	end
	
// Tasks								
	task op_ADD;
		begin
			A = $random;
			B = $random;
			@(posedge CLOCK);
			ALU_control = 4'b0000;
		end
	endtask
	
	task op_SUB;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b0001;
		end
	endtask
	
	task op_AND;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b0010;
		end
	endtask

	task op_OR;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b0011;
		end
	endtask

	task op_XOR;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b0100;
		end
	endtask
	
	task op_SLL;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b0101;
		end
	endtask
	
	task op_SRL;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b0110;
		end
	endtask
	
	task op_SRA;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b0111;
		end
	endtask

	task op_SLTU;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b1000;
		end
	endtask
	
	task op_SLT;
		begin
			A = $random;
			B = $random;
			ALU_control = 4'b1001;
		end
	endtask
	
	task initialize;
		begin
			CLOCK = 0;
			A = '0;
			B = '0;
			ALU_control = '0;
		end
	endtask 
	
	task zero_active;
		begin
			A = 32'd199;
			B = 32'd100;
			ALU_control = 4'b1000;
		end
	endtask
	
	task zero_active2;
		begin
			A = 32'sd199;
			B = -32'sd100;
			ALU_control = 4'b1001;
		end
	endtask
	
	
	assert property (@(posedge CLOCK) (ALU_control == 4'b0000) |-> (ALU_result == A + B))	else	$error("ADD operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b0001) |-> (ALU_result == A - B))	else	$error("SUB operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b0010) |-> (ALU_result == (A&B)))	else	$error("AND operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b0011) |-> (ALU_result == A | B))	else	$error("OR operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b0100) |-> (ALU_result == A ^ B))	else	$error("XOR operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b0101) |-> (ALU_result == A << B[4:0]))	else	$error("SLL operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b0110) |-> (ALU_result == A >> B[4:0]))	else	$error("SRL operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b0111) |-> (ALU_result == $signed(A) >>> B[4:0]))	else	$error("SRA operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b1000) |-> (ALU_result == (A < B)))	else	$error("SLTU operation was performed incorrectly");
	assert property (@(posedge CLOCK) (ALU_control == 4'b1001) |-> (ALU_result == $signed(A) < $signed(B)))	else	$error("SLT operation was performed incorrectly");
	assert property (@(posedge CLOCK) (zero == 1'b1) |-> (ALU_result == '0))	else	$error("Zero output is asserted incorrectly");

	initial 
	begin
	$display("Running testbench");
	initialize();
	@(negedge CLOCK)
	op_ADD();
	@(negedge CLOCK)
	op_SUB();
	@(negedge CLOCK)
	op_AND();
	@(negedge CLOCK)
	op_OR();
	@(negedge CLOCK)
	op_XOR();
	@(negedge CLOCK)
	op_SLL();
	@(negedge CLOCK)
	op_SRL();
	@(negedge CLOCK)
	op_SRA();
	@(negedge CLOCK)
	op_SLTU();
	@(negedge CLOCK)
	op_SLT();
	@(negedge CLOCK)
	zero_active();
	@(negedge CLOCK)
	zero_active2();
	repeat(10) @(negedge CLOCK)
	$stop;
	end

endmodule
