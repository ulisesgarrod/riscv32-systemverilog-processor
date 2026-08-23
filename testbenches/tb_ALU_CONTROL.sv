`timescale 1ns/1ps

module tb_ALU_CONTROL;

  logic [2:0] ALUOp;
  logic [3:0] instruction_bits;
  logic [3:0] ALU_control;

  ALU_CONTROL dut (
    .ALUOp(ALUOp),
    .instruction_bits(instruction_bits),
    .ALU_control(ALU_control)
  );


  task check_operation(
    input logic [2:0] op,
    input logic [3:0] bits,
    input logic [3:0] expected
  );
    begin
      ALUOp = op;
      instruction_bits = bits;

      #1;

      assert (ALU_control == expected)
        else $error(
          "ALU_CONTROL error: ALUOp=%b instruction_bits=%b expected=%b obtained=%b",
          ALUOp, instruction_bits, expected, ALU_control
        );
    end
  endtask


  initial begin

    // R-TYPE
    check_operation(3'b000, 4'b0000, 4'b0000); // ADD
    check_operation(3'b000, 4'b1000, 4'b0001); // SUB
    check_operation(3'b000, 4'b0001, 4'b0101); // SLL
    check_operation(3'b000, 4'b0010, 4'b1001); // SLT
    check_operation(3'b000, 4'b0011, 4'b1000); // SLTU
    check_operation(3'b000, 4'b0100, 4'b0100); // XOR
    check_operation(3'b000, 4'b0101, 4'b0110); // SRL
    check_operation(3'b000, 4'b1101, 4'b0111); // SRA
    check_operation(3'b000, 4'b0110, 4'b0011); // OR
    check_operation(3'b000, 4'b0111, 4'b0010); // AND


    // LOAD / STORE
    check_operation(3'b010, 4'b0010, 4'b0000); // LW / SW


    // BRANCH
    check_operation(3'b001, 4'b0000, 4'b0001); // BEQ
    check_operation(3'b001, 4'b0001, 4'b1010); // BNE
    check_operation(3'b001, 4'b0100, 4'b1001); // BLT
    check_operation(3'b001, 4'b0101, 4'b1100); // BGE
    check_operation(3'b001, 4'b0110, 4'b1000); // BLTU
    check_operation(3'b001, 4'b0111, 4'b1011); // BGEU


    // I-TYPE
    check_operation(3'b011, 4'b0000, 4'b0000); // ADDI
    check_operation(3'b011, 4'b0001, 4'b0101); // SLLI
    check_operation(3'b011, 4'b0010, 4'b1001); // SLTI
    check_operation(3'b011, 4'b0011, 4'b1000); // SLTIU
    check_operation(3'b011, 4'b0100, 4'b0100); // XORI
    check_operation(3'b011, 4'b0101, 4'b0110); // SRLI
    check_operation(3'b011, 4'b1101, 4'b0111); // SRAI
    check_operation(3'b011, 4'b0110, 4'b0011); // ORI
    check_operation(3'b011, 4'b0111, 4'b0010); // ANDI


    // LUI / AUIPC
    check_operation(3'b100, 4'b0000, 4'b0000);


    $finish;

  end

endmodule
