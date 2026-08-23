module Imm_Gen (
    input  logic [31:0] instruction, // complete instruction
    output logic [31:0] immediate    // sign-extended immediate
);

    // Instruction opcode
    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    // RV32I opcodes used in the project
    localparam logic [6:0]
        OPCODE_LOAD   = 7'b0000011, // LW
        OPCODE_OPIMM  = 7'b0010011, // ADDI, ANDI, ...
        OPCODE_STORE  = 7'b0100011, // SW
        OPCODE_BRANCH = 7'b1100011, // BEQ, BNE, BGE
        OPCODE_LUI    = 7'b0110111, // LUI
        OPCODE_AUIPC  = 7'b0010111, // AUIPC
        OPCODE_JAL    = 7'b1101111, // JAL
        OPCODE_JALR   = 7'b1100111; // JALR

    always_comb begin
        unique case (opcode)

            // I-TYPE
            // LW (LOAD) and immediate ALU instructions (ADDI, ANDI, SLTI, ...)
            OPCODE_LOAD,
            OPCODE_OPIMM: begin
                // immediate[31:0] = sign-extend(instruction[31:20])
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end

            // S-TYPE
            // SW
            OPCODE_STORE: begin
                // immediate[31:0] = sign-extend(instruction[31:25] instruction[11:7])
                immediate = {{20{instruction[31]}},
                             instruction[31:25],
                             instruction[11:7]};
            end

            // B-TYPE
            // BEQ, BNE, BGE (all use the same B-type format)
            OPCODE_BRANCH: begin
                // immediate[31:0] = sign-extend( instruction[31] instruction[7]
                //                                 instruction[30:25] instruction[11:8] 0 )
                immediate = {{19{instruction[31]}},
                             instruction[31],
                             instruction[7],
                             instruction[30:25],
                             instruction[11:8],
                             1'b0};
            end

            // U-TYPE
            // LUI and AUIPC (same format)
            OPCODE_LUI,
            OPCODE_AUIPC: begin
                // immediate[31:0] = instruction[31:12] << 12
                immediate = {instruction[31:12], 12'b0};
            end

            OPCODE_JAL: begin
                immediate = {{11{instruction[31]}}, // sign-extend from imm[20]
                             instruction[31],       // imm[20]
                             instruction[19:12],    // imm[19:12]
                             instruction[20],       // imm[11]
                             instruction[30:21],    // imm[10:1]
                             1'b0};                 // imm[0] = 0
            end

            OPCODE_JALR: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end

            // R-TYPE / others
            // ADD, SUB, SLT, ... do not use an immediate
            default: begin
                immediate = 32'd0;
            end

        endcase
    end

endmodule
