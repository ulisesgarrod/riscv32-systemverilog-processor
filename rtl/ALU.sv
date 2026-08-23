module ALU (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [3:0]  ALU_control,
    output logic [31:0] ALU_result,
    output logic        zero
);

    always @(*) begin
        case (ALU_control)
            4'b0000: ALU_result = A + B; // ADD
            4'b0001: ALU_result = A - B; // SUB
            4'b0010: ALU_result = A & B; // AND
            4'b0011: ALU_result = A | B; // OR
            4'b0100: ALU_result = A ^ B; // XOR

            // LOGICAL SHIFT LEFT
            4'b0101: ALU_result = A << B[4:0]; // SLL

            // LOGICAL SHIFT RIGHT
            4'b0110: ALU_result = A >> B[4:0]; // SRL

            // ARITHMETIC SHIFT RIGHT (SIGNED)
            4'b0111: ALU_result = $signed(A) >>> B[4:0]; // SRA

            // LESS THAN (unsigned)
			   4'b1000: ALU_result = (A < B) ? 32'd1 : 32'd0; // SLTU --> BLTU

            // LESS THAN (signed)
			   4'b1001: ALU_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT --> BLT
				
				//BNE
				4'b1010: ALU_result = A - B;

				// LESS THAN (unsigned)
				4'b1011: ALU_result = (A < B) ? 32'd1 : 32'd0;   // SLTU  --> BGEU
	
	         // LESS THAN (signed)
				4'b1100: ALU_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT --> BGE			

            default: ALU_result = 32'd0;

        endcase
    end

    assign zero =
    (ALU_control == 4'b0001) ? (ALU_result == 0) :      // BEQ  → equal
    (ALU_control == 4'b1010) ? (ALU_result != 0) :      // BNE  → not equal
    (ALU_control == 4'b1001) ? (ALU_result == 1) :      // BLT  → SLT = 1
    (ALU_control == 4'b1000) ? (ALU_result == 1) :      // BLTU → SLTU = 1
 	 (ALU_control == 4'b1100) ? (ALU_result == 0) :      // BGE  → SLT = 0
	 (ALU_control == 4'b1011) ? (ALU_result == 0) :      // BGEU → SLTU = 0
    1'b0;                                               // remaining cases (no branch)

endmodule
