`timescale 1ns/1ps
module tb_TOP_CORE();

	localparam T = 20;
	
	logic [31:0] instr, datareg_wr, PC, alu_out_ext, dataram_wr, dataram_rd_next;
	logic CLOCK, RST_n, ena_wr, ena_rd, MemtoReg_next;
	
	logic [31:0] registers [31:0]; // x0=registers[0], x1=registers[1], etc.
	logic [31:0] rs1, rs2, imm_ext_32, expected_PC1, expected_PC2, expected_addr; // 32-bit contents
	logic [11:0] imm_or_shamt, imm;
	logic [2:0] func3;
	logic [31:0] expected_result;
	logic true_false;
	logic [19:0] imm_U_type;
	logic [20:0] imm_Jal;
	logic [4:0] rd_addr;
	
	TOP_CORE duv
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


	// COVERGROUPS
	
	// R_TYPE (ACTIVE)
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
		begin
			for (int i = 0; i < 32; i++) begin
				duv.register_file_inst.registers[i] = $random;
			end
			duv.register_file_inst.registers[0] = 32'h0; // R0 is always 0
		end
	endtask
	
	assign registers = duv.register_file_inst.registers;
	
	task R_instructions;
		begin
			// 2. START OF LOGIC
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
			
			rs1 = registers[instr[19:15]];
			rs2 = registers[instr[24:20]];
			func3 = instr[14:12];
			
			case(func3)
				 3'b000: begin
					  if(instr[31:25] == 7'b0000000)
							expected_result = rs1 + rs2; 
					  else
							expected_result = rs1 - rs2; 
				 end
				 3'b001: expected_result = rs1 << rs2[4:0];
				 3'b010: expected_result = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;
				 3'b011: expected_result = (rs1 < rs2) ? 32'd1 : 32'd0; 
				 3'b100: expected_result = rs1 ^ rs2;
				 3'b101: begin
					  if(instr[31:25] == 7'b0000000)
							expected_result = rs1 >> rs2[4:0];
					  else
							expected_result = $signed(rs1) >>> rs2[4:0];
				 end
				 3'b110:	expected_result = rs1 | rs2;
				 3'b111: expected_result = rs1 & rs2;
				 default: expected_result = '0;
			endcase
			
			@(negedge CLOCK)
			assert (alu_out_ext == expected_result) else $error("R-type operation performed incorrectly");

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
			
			rs1 = registers[instr[19:15]];
			imm_or_shamt = instr[31:20];
			imm_ext_32 = {{20{imm_or_shamt[11]}}, imm_or_shamt};
			func3 = instr[14:12];
			case(func3)
				 3'b000: expected_result = rs1 + imm_ext_32; // ADDI
				 3'b001: expected_result = rs1 << imm_or_shamt[4:0];  // SLLI
				 3'b010: expected_result = ($signed(rs1) < $signed(imm_ext_32)) ? 32'd1 : 32'd0; // SLTI
				 3'b011: expected_result = (rs1 < $signed(imm_ext_32)) ? 32'd1 : 32'd0; // SLTIU
				 3'b100: expected_result = rs1 ^ imm_ext_32; // XORI
				 3'b101: begin
					  if(instr[31:25] == 7'b0000000)
							expected_result = rs1 >> imm_or_shamt[4:0]; // SRLI
					  else
							expected_result = $signed(rs1) >>> imm_or_shamt[4:0]; // SRAI
				 end
				 3'b110:	expected_result = rs1 | imm_ext_32; // ORI
				 3'b111: expected_result = rs1 & imm_ext_32; // ANDI
				 default: expected_result = '0;
			endcase
			
			@(negedge CLOCK)
			assert (alu_out_ext == expected_result) else $error("I-type operation performed incorrectly");

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
			   3'b000: true_false = (rs1 == rs2); // BEQ → SUB
			   3'b001: true_false = (rs1 != rs2); // BNE → SUB
			   3'b100: true_false = ($signed(rs1) < $signed(rs2)); // BLT → SLT
			   3'b110: true_false = (rs1 < rs2); // BLTU → SLTU
			   3'b101: true_false = ($signed(rs1) >= $signed(rs2)); // BGE → SLT
			   3'b111: true_false = (rs1 >= rs2); // BGEU → SLTU
			   default: true_false = 1'b0;
			endcase
			
			expected_result = (true_false) ? (PC + imm_ext_32) : (PC + 4);
			
			@(posedge CLOCK)
			#2
			assert (expected_result == PC) else $error("B-type operation performed incorrectly");

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
			
			imm_U_type = instr[31:12];
			if (instr[6:0] == 7'b0010111)
				expected_result = {imm_U_type, 12'b0} + PC; // AUIPC
			else	
				expected_result = {imm_U_type, 12'b0};
			
			@(posedge CLOCK)
			assert (expected_result == alu_out_ext) else $error("U-type operation performed incorrectly");
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
			
			imm = instr[31:20];
			rs1 = registers[instr[19:15]];
			rd_addr = instr[11:7];
			
			expected_addr = rs1 + {{20{imm[11]}},imm}; // Checks that the expected address matches the address used in memory
			
			@(posedge CLOCK)
			assert (expected_addr == alu_out_ext) else $error("Load operation address is incorrect");
			assert (duv.register_file_inst.RegWrite == 1'b1) else $error("Register file does not write any word");
			assert (duv.CONTROL_inst.ALUSrc == 1'b1) else $error("Immediate value is not used in address calculation");
			assert (ena_rd == 1'b1) else $error("No data is read from RAM");
			assert (duv.register_file_inst.writeReg == rd_addr) else $error("Data is not stored at the correct address");

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
			
			imm = {instr[31:25],instr[11:7]};
			rs1 = registers[instr[19:15]];
			rs2 = registers[instr[24:20]]; // Data to be written to memory
			
			expected_addr = rs1 + {{20{imm[11]}},imm}; // Checks that the expected address matches the address used in memory
			
			@(posedge CLOCK)
			assert (expected_addr == alu_out_ext) else $error("Store word operation address is incorrect");
			assert (duv.register_file_inst.RegWrite == 1'b0) else $error("Register file must not write any word");
			assert (duv.CONTROL_inst.ALUSrc == 1'b1) else $error("Immediate value is not used in address calculation");
			assert (ena_wr == 1'b1) else $error("RAM write is not enabled");
			assert (duv.register_file_inst.readData2 == rs2) else $error("Stored data does not match the source register");
		
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
			
			imm_Jal = {instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
			imm_ext_32 = {{11{instr[31]}}, imm_Jal};
			rd_addr = instr[11:7];
			expected_PC1 = PC + imm_ext_32;
			expected_PC2 = PC + 4;
			@(posedge CLOCK)
			#2 // Delay added to avoid race condition
			assert (expected_PC1 == PC) else $error("PC jump was not performed correctly");
			assert (duv.CONTROL_inst.Jal == 1'b1) else $error("Jal is not enabled correctly; check CONTROL");
			if (rd_addr != 0)
				begin
					assert (expected_PC2 == duv.register_file_inst.registers[rd_addr]) else $error("Return address was not stored correctly");
				end
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
			
			imm = instr[31:20];
			imm_ext_32 = {{20{instr[31]}}, imm};
			rd_addr = instr[11:7];
			func3 = instr[14:12];
			rs1 = registers[instr[19:15]];
			expected_PC1 = (rs1 + imm_ext_32) & 32'hFFFFFFFE;
			expected_PC2 = PC + 4;
			
			@(posedge CLOCK)
			#2 // Delay added to avoid race condition
			assert (expected_PC1 == PC) else $error("PC jump was not performed correctly");
			assert (duv.CONTROL_inst.Jalr == 1'b1) else $error("Jalr is not enabled correctly; check CONTROL");
			if (rd_addr != 0)
				begin
					assert (expected_PC2 == duv.register_file_inst.registers[rd_addr]) else $error("Return address was not stored correctly");
				end
			coverageJalr.sample();
			
		end
	endtask

	
	task reset;
		begin
			RST_n = 1'b0; // Assert Reset
			
			instr = 32'h00000000; 
			datareg_wr = 32'b0;

			repeat(5) @(negedge CLOCK); // Wait a few cycles with Reset asserted
			RST_n = 1'b1; // Release Reset
		end
	endtask
			
	initial
	begin
		CLOCK = 0;
		// Initialize memory		
		reset();
		
		@(negedge CLOCK);
		while (coverageR.crossR.get_coverage() < 70)
			
			begin
				@(posedge CLOCK)
				init_registers();
				#2
				R_instructions;
			end

		 @(negedge CLOCK);
		 while (coverageI.crossI.get_coverage() < 70)
			
			 begin
				 @(posedge CLOCK)
				 init_registers();
				 #2
				 I_instructions;
			 end
			 
		 @(negedge CLOCK);
		 while (coverageB.crossB.get_coverage() < 100)
			
			 begin
				 @(posedge CLOCK)
				 init_registers();
				 #5
				 B_instructions;
			 end
			 
		 @(negedge CLOCK);
		 while (coverageU.crossU.get_coverage() < 100)
			
			 begin
				 @(posedge CLOCK)
				 init_registers();
				 #2
				 U_instructions;
			 end
			 
		 @(negedge CLOCK);
		 while (coverage_load.cross_load.get_coverage() < 50)
			
			 begin
				 @(posedge CLOCK)
				 init_registers();
				 #2
				 load_instructions;
			 end
			 
		 @(negedge CLOCK);
		 while (coverageS.crossS.get_coverage() < 50)
			
			 begin
				 @(posedge CLOCK)
				 init_registers();
				 #2
				 S_instructions;
			 end
		
		@(negedge CLOCK);
		 while (coverageJal.crossJal.get_coverage() < 50)
			
			 begin
				 @(posedge CLOCK)
				 init_registers();
				 #5
				 Jal_instructions;
			 end
			 
		@(negedge CLOCK);
		 while (coverageJalr.crossJalr.get_coverage() < 50)
			
			 begin
				 @(posedge CLOCK)
				 init_registers();
				 #5
				 Jalr_instructions;
			 end
			 
		$display("Test finished");
		$stop;	
	end
	
	
endmodule
