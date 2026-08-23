module TOP_CORE(instr, CLOCK, RST_n, dataram_rd, PC, ena_wr, ena_rd, alu_out_ext, dataram_wr);

input [31:0] instr;
input RST_n, CLOCK;
input logic [31:0] dataram_rd; // RAM output

output logic [31:0] PC;
output logic ena_wr, ena_rd; // RAM read/write enable input
output logic [31:0] alu_out_ext; // RAM input
output logic [31:0] dataram_wr;

logic [31:0] PC_next;
logic [31:0] reg_A, reg_B, value_A, value_B, imm_out;
logic ALUSrc_next, Branch_next, PCSrc, zero_next, RegWrite_next, MemRead_next, MemWrite_next, Jal_next, Jalr_next;
logic [1:0] AuipcLui_next;
logic [2:0] ALUOp_next;
logic [3:0] instruction_bits_next, ALU_operation;
logic [1:0] MemtoReg_next; // enables RAM mux
logic [31:0] datareg_wr; // MemtoReg mux output


always_ff @(posedge CLOCK or negedge RST_n)
	if (!RST_n)
		PC <= '0;
	else 
		PC <= PC_next;
		
CONTROL CONTROL_inst
(
	.instruction(instr),
	.Branch(Branch_next),
	.MemRead(MemRead_next),
	.MemtoReg(MemtoReg_next),
	.ALUOp(ALUOp_next),
	.MemWrite(MemWrite_next),
	.ALUSrc(ALUSrc_next),
	.RegWrite(RegWrite_next),
	.Jal(Jal_next),
	.Jalr(Jalr_next),
	.AuipcLui(AuipcLui_next)
);
		
register_file register_file_inst
(
	.CLK(CLOCK),
	.RST_n(RST_n),
	.readReg1(instr[19:15]),
	.readReg2(instr[24:20]),
	.writeReg(instr[11:7]),
	.writeData(datareg_wr),
	.readData1(reg_A),
	.readData2(reg_B),
	.RegWrite(RegWrite_next)
);

// 3-to-1 mux for ALU input A
always_comb begin
	case (AuipcLui_next)
		2'b00: value_A = PC;        
		2'b01: value_A = 32'd0;     
		2'b10: value_A = reg_A;   
		default: value_A = reg_A;
	endcase
end
		
ALU ALU_inst
(
	.A(value_A),
	.B(value_B),
	.ALU_control(ALU_operation),
	.ALU_result(alu_out_ext),
	.zero(zero_next)
);

Imm_Gen Imm_Gen_inst
(
	.instruction(instr[31:0]),
	.immediate(imm_out)
);

ALU_CONTROL ALU_CONTROL_inst
(
	.ALUOp(ALUOp_next),
	.instruction_bits(instruction_bits_next),
	.ALU_control(ALU_operation)
);

assign PCSrc = (zero_next & Branch_next) || Jal_next;

assign PC_next = PCSrc ? (PC + imm_out) :
                 Jalr_next ? {alu_out_ext[31:1], 1'b0} :
                             (PC + 4);

assign value_B = (ALUSrc_next) ? imm_out : reg_B;
assign ena_wr = MemWrite_next;
assign ena_rd = MemRead_next;
assign instruction_bits_next = {instr[30], instr[14:12]};
assign dataram_wr = reg_B;
assign datareg_wr = (MemtoReg_next == 2'b01) ? dataram_rd :
                    ((MemtoReg_next == 2'b00) ? alu_out_ext : PC + 4);

endmodule
