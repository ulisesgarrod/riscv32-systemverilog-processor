module CONTROL(
    input  logic [31:0] instruction, // complete RISC-V instruction
    output logic        Branch,
    output logic        MemRead,
    output logic  [1:0] MemtoReg,
    output logic  [2:0] ALUOp,
    output logic        MemWrite,
    output logic        ALUSrc,
    output logic        RegWrite,
	 output logic			Jal,
	 output logic			Jalr,
	 output logic  [1:0] AuipcLui
);


    logic [4:0] opcode;
    assign opcode = instruction[6:2];

    always_comb begin
        Branch    = 0;
        MemRead   = 0;
        MemtoReg  = 2'b00;
        ALUOp     = 3'b000;
        MemWrite  = 0;
        ALUSrc    = 0;
        RegWrite  = 0;
		  AuipcLui  = 2'b10;
		  Jalr      = 0;
		  Jal 		= 0;
        case (opcode)

            // R-format (includes SLT and SLTU)
            7'b01100: begin
                ALUOp     = 3'b000;
                RegWrite  = 1;
            end

            // I-format
            7'b00100: begin
                ALUOp     = 3'b011;
                ALUSrc    = 1;
                RegWrite  = 1;
            end

            // LW
            7'b00000: begin
                MemRead   = 1;
                MemtoReg  = 2'b01;
                ALUSrc    = 1;
                ALUOp     = 3'b010;
                RegWrite  = 1;
            end

            // SW
            7'b01000: begin
                MemWrite  = 1;
                ALUSrc    = 1;
                ALUOp     = 3'b010;
            end

            // B-TYPE (BEQ, BGE, BGEU, BNE, BLT, BLTU)
            7'b11000: begin
                Branch    = 1;
                ALUOp     = 3'b001;
            end
				
				// LUI
				7'b01101: begin
					 RegWrite  = 1;
					 ALUOp     = 3'b100;
					 ALUSrc    = 1;
					 AuipcLui  = 2'b01; // This means the MUX outputs 0
					 
				end

				// AUIPC
				7'b00101: begin
					 RegWrite  = 1;
					 ALUOp     = 3'b100; 
					 ALUSrc    = 1;
					 AuipcLui  = 2'b00; // This means the MUX outputs the PC
				end
				
				// JAL
				7'b11011: begin
					 Jal = 1;
					 RegWrite  = 1;
					 MemtoReg  = 2'b10;
				end
				
				// JALR
				7'b11001: begin
					 Jalr 	  = 1;
					 ALUSrc    = 1;
					 ALUOp     = 3'b011;
					 RegWrite  = 1;
					 MemtoReg  = 2'b10;
				end
				
				default: begin
					Branch    = 0;
					MemRead   = 0;
					MemtoReg  = 2'b00;
					ALUOp     = 3'b000;
					MemWrite  = 0;
					ALUSrc    = 0;
					RegWrite  = 0;
					AuipcLui  = 2'b10;
					Jal 		 = 0;
					Jalr 		 = 0;
				end
        endcase
    end

endmodule
