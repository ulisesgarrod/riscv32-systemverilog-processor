`timescale 1ns/1ps

`include "TOP_CORE.sv"

module tb_TOP_CORE_pipeline_gmodel();

	localparam T = 20;

	// Single-cycle inputs/outputs
	logic [31:0] instr, datareg_wr, PC, alu_out_ext, dataram_wr, dataram_rd_next;
	logic CLOCK, RST_n, ena_wr, ena_rd, MemtoReg_next;
	
	// Pipeline inputs/outputs
	logic [31:0] alu_out_ext_pipeline, PC_pipeline, dataram_wr_pipeline;
	logic ena_wr_pipeline, ena_rd_pipeline;
		
	logic [31:0] registers [31:0]; // x0=registers[0], x1=registers[1], etc.
	logic [31:0] rs1, rs2, imm_ext_32, expected_PC1, expected_PC2, expected_addr, rd_addr_value;
	logic [11:0] imm_or_shamt, imm;
	logic [2:0] func3;
	logic [31:0] expected_result, single_cycle_result;
	logic true_false;
	logic [19:0] imm_U_type;
	logic [20:0] imm_Jal;
	logic [4:0] rd_addr;
	

	TOP_CORE duv_gmodel
	(
		.instr(instr),
		.dataram_rd(alu_out_ext),
		.CLOCK(CLOCK),
		.RST_n(RST_n),
		.PC(PC),
		.ena_wr(ena_wr),
		.ena_rd(ena_rd),
		.alu_out_ext(alu_out_ext),
		.dataram_wr(dataram_wr)
	);
	

	TOP_CORE_pipeline duv_pipeline
	(
		.instr(instr),
		.dataram_rd(alu_out_ext_pipeline),
		.CLOCK(CLOCK),
		.RST_n(RST_n),
		.PC(PC_pipeline),
		.ena_wr(ena_wr_pipeline),
		.ena_rd(ena_rd_pipeline),
		.alu_out_ext(alu_out_ext_pipeline),
		.dataram_wr(dataram_wr_pipeline)
	);
	

	class randomInstruction;
		rand logic [31:0] instr;

		constraint R_format {
			instr[6:0] == 7'b0110011;
			instr[31:25] == 7'b0000000 ||
			instr[31:25] == 7'b0100000 && instr[14:12] == 3'b000 ||
			instr[31:25] == 7'b0100000 && instr[14:12] == 3'b101;
		} 
				
		constraint I_format {
			instr[6:0] == 7'b0010011;
			
			(instr[14:12] == 3'b001) -> (instr[31:25] == 7'b0000000);
			(instr[14:12] == 3'b101) -> (instr[31:25] inside {7'b0000000, 7'b0100000});
		}
		
		
		constraint B_format {
			instr[6:0] == 7'b1100011;
			instr[14:12] == 3'b000 ||
			instr[14:12] == 3'b001 ||
			instr[14:12] == 3'b100 ||
			instr[14:12] == 3'b101 ||
			instr[14:12] == 3'b110 ||
			instr[14:12] == 3'b111;		
		}
		
		constraint U_format {
			instr[6:0] == 7'b0010111 || instr[6:0] == 7'b0110111; // AUIPC or LUI
		}
		
		constraint load_format {
			instr[6:0] == 7'b0000011;
			instr[14:12] == 3'b010;
		}
		
		constraint S_format {
			instr[6:0] == 7'b0100011;
			instr[14:12] == 3'b010;
		}
		
		constraint Jal_format {
			instr[6:0] == 7'b1101111;
		}
		
		constraint Jalr_format {
			instr[6:0] == 7'b1100111;
			instr[14:12] == 3'b000;
		}
	endclass


	// --- COVERGROUPS ---
	
	// R_TYPE
	covergroup R_type;
		rd_cp: coverpoint instr[11:7] {
			bins val[] = {[0:31]};
		}
		rs1_cp: coverpoint instr[19:15] {
			bins val[4] = {[0:31]};
		}
		rs2_cp: coverpoint instr[24:20] {
			bins val[4] = {[0:31]};
		}
		func3_cp: coverpoint instr[14:12] {
			bins val[] = {[0:7]};
		}
		crossR: cross rd_cp, rs1_cp, rs2_cp, func3_cp;
	endgroup;
	
	
	
	covergroup I_type;
		rd_cp: coverpoint instr[11:7] {
			bins val[] = {[0:31]};
		}
		rs1_cp: coverpoint instr[19:15] {
			bins val[4] = {[0:31]};
		}
		func3_cp: coverpoint instr[14:12] {
			bins val[] = {[0:7]};
		}
		imm_cp: coverpoint $signed(instr[31:20]) {
			bins val[4] = {[-2048:2047]};
		} 
		crossI: cross rd_cp, rs1_cp, func3_cp, imm_cp;
	endgroup;


	covergroup B_type; 
		rs1_cp: coverpoint instr[19:15] {
			bins val[4] = {[0:31]};
		}
		rs2_cp: coverpoint instr[24:20] {
			bins val[4] = {[0:31]};
		}
		func3_cp: coverpoint instr[14:12] {
			bins val[] = {[0:7]};
		}
		imm_cp: coverpoint $signed({instr[31],instr[7],instr[30:25],instr[11:8]}) {
			bins val[4] = {[-2048:2047]};
		}
		crossB: cross rs1_cp, rs2_cp, imm_cp;
	endgroup;
	
	
	covergroup U_type; 
		rd_cp: coverpoint instr[11:7] {
			bins val[] = {[0:31]};
		}
		imm_cp: coverpoint $signed({instr[31:12]}) {
			bins val[8] = {[-524288:524287]};
		}
		crossU: cross rd_cp, imm_cp;
	endgroup;


	covergroup load_type;
		imm_cp: coverpoint $signed({instr[31:20]}) {
			bins val[8] = {[-2048:2047]};
		}
		rs1_cp: coverpoint instr[19:15] {
			bins val[4] = {[0:31]};
		}
		rd_cp: coverpoint instr[11:7] {
			bins val[] = {[0:31]};
		}
		cross_load: cross imm_cp, rs1_cp, rd_cp;
	endgroup;
	
	
	covergroup S_type;
		imm_cp: coverpoint $signed({instr[31:25],instr[11:7]}) {
			bins val[] = {[-2048:2047]};
		}
		rs1_cp: coverpoint instr[19:15] {
			bins val[4] = {[0:31]};
		}
		crossS: cross imm_cp, rs1_cp;
	endgroup;
	
	
	covergroup Jal_type;
		imm_cp: coverpoint $signed({instr[31:12]}) {
			bins val[4] = {[-524288:524287]};
		}
		rd_cp: coverpoint instr[11:7] {
			bins val[] = {[0:31]};
		}
		crossJal: cross rd_cp, imm_cp;
	endgroup;
	
	
	covergroup Jalr_type;
		imm_cp: coverpoint $signed({instr[31:20]}) {
			bins val[4] = {[-2048:2047]};
		}
		rs1_cp: coverpoint instr[19:15] {
			bins val[4] = {[0:31]};
		}
		rd_cp: coverpoint instr[11:7] {
			bins val[] = {[0:31]};
		}
		crossJalr: cross rd_cp, imm_cp, rs1_cp;
	endgroup;
	
	
	// Object declaration
	randomInstruction busInst = new;
	R_type coverageR = new;
	I_type coverageI = new;
	B_type coverageB = new;
	U_type coverageU = new;
	load_type coverage_load = new;
	S_type coverageS = new;
	Jal_type coverageJal = new;
	Jalr_type coverageJalr = new;
	
	
	// CLOCK DEFINITION
	always
	begin
		#(T/2) CLOCK = ~CLOCK;
	end
	
	
	// TASK TO INITIALIZE REGISTERS (avoids 'X' values)
	task init_registers;
		logic [31:0] random_value; 
		
		begin
			for (int i = 0; i < 32; i++) begin
				
				random_value = $random;
				
				duv_gmodel.register_file_inst.registers[i] = random_value;
				duv_pipeline.register_file_inst.registers[i] = random_value;
			end
			
			// Ensure R0 is zero in both cores
			duv_gmodel.register_file_inst.registers[0] = 32'h0;
			duv_pipeline.register_file_inst.registers[0] = 32'h0;
		end
	endtask
	
	
	assign registers = duv_gmodel.register_file_inst.registers;
	
	
	task R_instructions;
		begin
			busInst.R_format.constraint_mode(1);
			busInst.I_format.constraint_mode(0);
			busInst.B_format.constraint_mode(0);
			busInst.U_format.constraint_mode(0);
			busInst.load_format.constraint_mode(0);
			busInst.S_format.constraint_mode(0);
			busInst.Jalr_format.constraint_mode(0);
			busInst.Jal_format.constraint_mode(0);
				
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr; 
				
			@(negedge CLOCK);
			single_cycle_result = alu_out_ext;
			
			repeat(4) @(negedge CLOCK);
			
			assert (single_cycle_result == alu_out_ext_pipeline)
				else $error("R-type operation performed incorrectly");

			coverageR.sample();
		end
	endtask
	
	
	task I_instructions;
		begin
			busInst.R_format.constraint_mode(0);
			busInst.I_format.constraint_mode(1);
			busInst.B_format.constraint_mode(0);
			busInst.U_format.constraint_mode(0);
			busInst.load_format.constraint_mode(0);
			busInst.S_format.constraint_mode(0);
			busInst.Jalr_format.constraint_mode(0);
			busInst.Jal_format.constraint_mode(0);
			
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr;
			
			@(negedge CLOCK);
			single_cycle_result = alu_out_ext;
			
			repeat(4) @(negedge CLOCK);
			
			assert (single_cycle_result == alu_out_ext_pipeline)
				else $error("I-type operation performed incorrectly");

			coverageI.sample();
			
		end
	endtask
	
	
	task B_instructions;
		begin
			busInst.R_format.constraint_mode(0);
			busInst.I_format.constraint_mode(0);
			busInst.B_format.constraint_mode(1);
			busInst.U_format.constraint_mode(0);
			busInst.load_format.constraint_mode(0);
			busInst.S_format.constraint_mode(0);
			busInst.Jalr_format.constraint_mode(0);
			busInst.Jal_format.constraint_mode(0);
			
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr;
			
			rs1 = registers[instr[19:15]];
			rs2 = registers[instr[24:20]];
			func3 = instr[14:12];
			imm = {instr[31], instr[7], instr[30:25], instr[11:8]};
			imm_ext_32 = {{19{instr[31]}}, imm, 1'b0};
			
			case(func3)
				3'b000: true_false = (rs1 == rs2); // BEQ
				3'b001: true_false = (rs1 != rs2); // BNE
				3'b100: true_false = ($signed(rs1) < $signed(rs2)); // BLT
				3'b110: true_false = (rs1 < rs2); // BLTU
				3'b101: true_false = ($signed(rs1) >= $signed(rs2)); // BGE
				3'b111: true_false = (rs1 >= rs2); // BGEU
				default: true_false = 1'b0;
			endcase
			
			repeat(2) @(negedge CLOCK);
			single_cycle_result = PC;
			
			if (true_false == 1'b1)
			begin
				repeat(3) @(negedge CLOCK);
				assert (single_cycle_result == PC_pipeline)
					else $error("B-type operation performed incorrectly");
			end
			else if (true_false == 1'b0)
			begin
				assert (single_cycle_result == PC_pipeline)
					else $error("B-type operation performed incorrectly");
			end

			coverageB.sample();
			
		end
	endtask
	
	
	task U_instructions;
		begin
			busInst.R_format.constraint_mode(0);
			busInst.I_format.constraint_mode(0);
			busInst.B_format.constraint_mode(0);
			busInst.U_format.constraint_mode(1);
			busInst.load_format.constraint_mode(0);
			busInst.S_format.constraint_mode(0);
			busInst.Jalr_format.constraint_mode(0);
			busInst.Jal_format.constraint_mode(0);
			
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr;

			@(negedge CLOCK);
			single_cycle_result = alu_out_ext;
			
			repeat(3) @(negedge CLOCK);
			
			assert (single_cycle_result == alu_out_ext_pipeline)
				else $error("U-type operation performed incorrectly");
			
			coverageU.sample();
		end
	endtask
	
	
	task load_instructions;
		begin
			busInst.R_format.constraint_mode(0);
			busInst.I_format.constraint_mode(0);
			busInst.B_format.constraint_mode(0);
			busInst.U_format.constraint_mode(0);
			busInst.load_format.constraint_mode(1);
			busInst.S_format.constraint_mode(0);
			busInst.Jalr_format.constraint_mode(0);
			busInst.Jal_format.constraint_mode(0);
			
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr;
			
			@(negedge CLOCK);
			single_cycle_result = alu_out_ext;
			
			repeat(4) @(negedge CLOCK);
			
			assert (single_cycle_result == alu_out_ext_pipeline)
				else $error("Load operation address is incorrect");

			coverage_load.sample();
			
		end
	endtask


	task S_instructions;
		begin
			busInst.R_format.constraint_mode(0);
			busInst.I_format.constraint_mode(0);
			busInst.B_format.constraint_mode(0);
			busInst.U_format.constraint_mode(0);
			busInst.load_format.constraint_mode(0);
			busInst.S_format.constraint_mode(1);
			busInst.Jalr_format.constraint_mode(0);
			busInst.Jal_format.constraint_mode(0);
			
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr;
			
			@(negedge CLOCK);
			single_cycle_result = alu_out_ext;
			
			repeat(4) @(negedge CLOCK);
			
			assert (single_cycle_result == alu_out_ext_pipeline)
				else $error("Store word address is incorrect");

			coverageS.sample();
			
		end
	endtask
	
	
	task Jal_instructions;
		begin
			busInst.R_format.constraint_mode(0);
			busInst.I_format.constraint_mode(0);
			busInst.B_format.constraint_mode(0);
			busInst.U_format.constraint_mode(0);
			busInst.load_format.constraint_mode(0);
			busInst.S_format.constraint_mode(0);
			busInst.Jalr_format.constraint_mode(0);
			busInst.Jal_format.constraint_mode(1);
			
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr;
			
			repeat(2) @(negedge CLOCK);
			single_cycle_result = PC;
			
			repeat(3) @(negedge CLOCK);
			
			assert (single_cycle_result == PC_pipeline)
				else $error("PC jump was not performed correctly");
	
			coverageJal.sample();
			
		end
	endtask
	
	
	task Jalr_instructions;
		begin
			busInst.R_format.constraint_mode(0);
			busInst.I_format.constraint_mode(0);
			busInst.B_format.constraint_mode(0);
			busInst.U_format.constraint_mode(0);
			busInst.load_format.constraint_mode(0);
			busInst.S_format.constraint_mode(0);
			busInst.Jalr_format.constraint_mode(1);
			busInst.Jal_format.constraint_mode(0);
			
			assert(busInst.randomize()) else $error("randomize() failed");
			instr = busInst.instr;
			
			repeat(2) @(negedge CLOCK);
			single_cycle_result = PC;
			
			repeat(3) @(negedge CLOCK);
			
			assert (single_cycle_result == PC_pipeline)
				else $error("PC jump was not performed correctly");

			coverageJalr.sample();
			
		end
	endtask

	
	task reset;
		begin
			RST_n = 1'b0; // Assert Reset
			
			instr = 32'h00000000; 
			datareg_wr = 32'b0; 

			@(negedge CLOCK); // Wait with Reset asserted
			RST_n = 1'b1; // Release Reset
		end
	endtask
			
	
	initial
	begin
		CLOCK = 0;
		
		reset();
		
  		@(negedge CLOCK);
		while (coverageR.crossR.get_coverage() < 70)
		begin
			#5
			reset();
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(15) @(posedge CLOCK);
			#2
			R_instructions;
		end


		@(negedge CLOCK);
		while (coverageI.crossI.get_coverage() < 70)
		begin
			#5
			reset();
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(15) @(posedge CLOCK);
			#2
			I_instructions;
		end
			 

		@(negedge CLOCK);
		while (coverageB.crossB.get_coverage() < 100)
		begin
			reset();
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(7) @(posedge CLOCK);
			#2
			B_instructions;
		end
			

 		@(negedge CLOCK);
		while (coverageU.crossU.get_coverage() < 100)
		begin
			reset();
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(15) @(posedge CLOCK);
			#2
			U_instructions;
		end 
			

		@(negedge CLOCK);
		while (coverage_load.cross_load.get_coverage() < 50)
		begin
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(15) @(posedge CLOCK);
			#2
			load_instructions;
		end
			 

		@(negedge CLOCK);
		while (coverageS.crossS.get_coverage() < 50)
		begin
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(15) @(posedge CLOCK);
			#2
			S_instructions;
		end
 

		@(negedge CLOCK);
		while (coverageJal.crossJal.get_coverage() < 50)
		begin
			repeat(2) @(negedge CLOCK);
			reset();
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(15) @(posedge CLOCK);
			#2
			Jal_instructions;
		end
		 

		@(negedge CLOCK);
		while (coverageJalr.crossJalr.get_coverage() < 50)
		begin
			repeat(2) @(negedge CLOCK);
			reset();
			repeat(4) @(posedge CLOCK);
			init_registers();
			repeat(15) @(posedge CLOCK);
			#5
			Jalr_instructions;
		end
		 

		$display("Test finished");
		$stop;	
	end
	
	
endmodule
