module ALU_CONTROL (ALUOp, instruction_bits, ALU_control);

	input [2:0] ALUOp;
	input [3:0] instruction_bits;
	output logic [3:0] ALU_control;

	always_comb
	begin
	
	case(ALUOp)
	
		3'b000: 
		begin
		case(instruction_bits[2:0])
			3'b000: if(instruction_bits[3] == 0)
							ALU_control = 4'b0000; // ADD
						else
							ALU_control = 4'b0001; // SUB
		
			3'b001: ALU_control = 4'b0101; // SLL
			3'b010: ALU_control = 4'b1001; // SLT
			3'b011: ALU_control = 4'b1000; // SLTU
			3'b100: ALU_control = 4'b0100; // XOR
			3'b101: if (instruction_bits[3] == 0) 
							ALU_control = 4'b0110; // SRL
					  else	
							ALU_control = 4'b0111; // SRA

			3'b110: ALU_control = 4'b0011; // OR

			3'b111: ALU_control = 4'b0010; // AND
	
			default: ALU_control = 4'b0000;
	
		endcase
		end
		
	
		3'b010: // L-type and S-type instructions
		begin
		case(instruction_bits[2:0])
			3'b010: ALU_control = 4'b0000; // LW and SW
			default: ALU_control = 4'b0000;
		endcase
		end
		
		
		3'b001: // B-type instructions (branches)
		begin
		case(instruction_bits[2:0]) // funct3
			3'b000: ALU_control = 4'b0001; // BEQ  → SUB
			3'b001: ALU_control = 4'b1010; // BNE  → SUB (changed)
			3'b100: ALU_control = 4'b1001; // BLT  → SLT
			3'b110: ALU_control = 4'b1000; // BLTU → SLTU
			3'b101: ALU_control = 4'b1100; // BGE  → SLT
			3'b111: ALU_control = 4'b1011; // BGEU → SLTU
			default: ALU_control = 4'b0000;
		endcase
		end

	
	
		3'b011: // I-type instructions
		begin
		case(instruction_bits[2:0])
			3'b000: ALU_control = 4'b0000; // ADDI
			3'b001: ALU_control = 4'b0101; // SLLI
			3'b010: ALU_control = 4'b1001; // SLTI
			3'b011: ALU_control = 4'b1000; // SLTIU
			3'b100: ALU_control = 4'b0100; // XORI
			3'b101: if(instruction_bits[3] == 0)
							ALU_control = 4'b0110; // SRLI
					  else
							ALU_control = 4'b0111; // SRAI
			3'b110: ALU_control = 4'b0011; // ORI
			3'b111: ALU_control = 4'b0010; // ANDI
			default:ALU_control = 4'b0000;
		endcase
		end
		
		
		3'b100: // LUI and AUIPC instructions
		begin
		ALU_control = 4'b0000; 
		end
		
		default: ALU_control = 4'b0000;
	endcase
	end
	
endmodule
