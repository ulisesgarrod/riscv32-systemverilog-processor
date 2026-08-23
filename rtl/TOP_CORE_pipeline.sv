module TOP_CORE_pipeline(instr, CLOCK, RST_n, dataram_rd, PC, ena_wr, ena_rd, alu_out_ext, dataram_wr);

input [31:0] instr;
input RST_n, CLOCK;
input logic [31:0] dataram_rd;

output logic [31:0] PC;
output logic ena_wr, ena_rd; // RAM read/write enable
output logic [31:0] alu_out_ext; // RAM input
output logic [31:0] dataram_wr;

logic [31:0] datareg_wr; // MemtoReg mux output
logic [31:0] PC_next;
logic [3:0] instruction_bits_next, ALU_operation;
logic PCSrc;

// ID
logic [31:0] PC_ID, instr_ID, readData1_ID, readData2_ID, imm_out_ID;
logic        Branch_ID, MemRead_ID, MemWrite_ID, RegWrite_ID, AluSrc_ID, Jal_ID, Jalr_ID;
logic [2:0]  AluOp_ID;
logic [1:0]  MemtoReg_ID, AuipcLui_ID;

// EX
logic        RegWrite_EX, Branch_EX, MemRead_EX, MemWrite_EX, AluSrc_EX, Jal_EX, Jalr_EX, zero_EX;
logic [1:0]  MemtoReg_EX, AuipcLui_EX;
logic [2:0]  AluOp_EX;
logic [31:0] PC_EX, PC4, readData1_EX, readData2_EX, imm_out_EX, instr_EX, value_A, value_B, alu_out_ext_EX, PC_imm;

// MEM
logic        RegWrite_MEM, Branch_MEM, MemRead_MEM, MemWrite_MEM, zero_MEM, Jal_MEM, Jalr_MEM;
logic [1:0]  MemtoReg_MEM;
logic [31:0] PC4_MEM, alu_out_ext_MEM, readData2_MEM, PC_imm_MEM, instr_MEM;

// WB
logic        RegWrite_WB;
logic [1:0]  MemtoReg_WB;
logic [31:0] PC4_WB, alu_out_ext_WB, dataram_rd_WB, instr_WB;



always_ff @(posedge CLOCK or negedge RST_n)
	begin
	if (!RST_n)
		PC <= '0;
	else 
		PC <= PC_next;
	end

assign PC_next = Jalr_MEM ? {alu_out_ext_MEM[31:1], 1'b0} : PCSrc ? PC_imm_MEM : (PC + 4);


//------------IF/ID + RESET------------
always_ff @(posedge CLOCK or negedge RST_n)
	begin
	if (!RST_n)
		begin
		PC_ID 	<= '0;
		instr_ID <= '0;
		end
	else
		begin
		PC_ID    <= PC;
		instr_ID <= instr;
		end
	end


register_file register_file_inst
(
	.CLK(CLOCK),						
	.RST_n(RST_n),						
	.readReg1(instr_ID[19:15]),	
	.readReg2(instr_ID[24:20]),	
	.writeReg(instr_WB[11:7]),		
	.writeData(datareg_wr),			// MemtoReg mux output						
	.readData1(readData1_ID),		
	.readData2(readData2_ID),		
	.RegWrite(RegWrite_WB) 		
);


Imm_Gen Imm_Gen_inst
(
	.instruction(instr_ID[31:0]),
	.immediate(imm_out_ID)
);


CONTROL CONTROL_inst
(
	.instruction(instr_ID),
	.Branch(Branch_ID),
	.MemRead(MemRead_ID),
	.MemtoReg(MemtoReg_ID),
	.ALUOp(AluOp_ID),
	.MemWrite(MemWrite_ID),
	.ALUSrc(AluSrc_ID),
	.RegWrite(RegWrite_ID),
	.AuipcLui(AuipcLui_ID),
	.Jal(Jal_ID),
	.Jalr(Jalr_ID)
);

//------------ID/EX + RESET------------
always_ff @(posedge CLOCK or negedge RST_n)
begin
	if (!RST_n)
	begin
		RegWrite_EX  <= 0;
		MemtoReg_EX  <= 0;
		Branch_EX 	 <= 0;
		MemRead_EX 	 <= 0;
		MemWrite_EX  <= 0;
		AluOp_EX  	 <= 0;
		AluSrc_EX    <= 0;
		AuipcLui_EX  <= 0;
		Jal_EX 		 <= 0;
		Jalr_EX 		 <= 0;
		PC_EX 		 <= 0;
		readData1_EX <= 0;
		readData2_EX <= 0;
		imm_out_EX	 <= 0;
		instr_EX 	 <= 0;
	end
	else
	begin
		RegWrite_EX  <= RegWrite_ID;
		MemtoReg_EX  <= MemtoReg_ID;
		Branch_EX    <= Branch_ID;
		MemRead_EX   <= MemRead_ID;
		MemWrite_EX  <= MemWrite_ID;
		AluOp_EX     <= AluOp_ID;
		AluSrc_EX    <= AluSrc_ID;
		AuipcLui_EX  <= AuipcLui_ID;
		Jal_EX       <= Jal_ID;
		Jalr_EX      <= Jalr_ID;
		PC_EX        <= PC_ID;
		readData1_EX <= readData1_ID;
		readData2_EX <= readData2_ID;
		imm_out_EX   <= imm_out_ID;
		instr_EX     <= instr_ID;
	end
end

assign PC4 = PC_EX + 4;
	
// 3-to-1 mux for ALU input A
always_comb begin
	case (AuipcLui_EX)
		2'b00: value_A = PC_EX;        
		2'b01: value_A = 32'd0;     
		2'b10: value_A = readData1_EX;   
		default: value_A = readData1_EX;
	endcase
end
	 
		
assign value_B = (AluSrc_EX) ? imm_out_EX : readData2_EX; // Mux that selects ALU input B		


ALU ALU_inst
(
	.A(value_A),	
	.B(value_B),
	.ALU_control(ALU_operation),
	.ALU_result(alu_out_ext_EX),
	.zero(zero_EX)
);


assign instruction_bits_next = {instr_EX[30],instr_EX[14:12]};


ALU_CONTROL ALU_CONTROL_inst
(
	.ALUOp(AluOp_EX),
	.instruction_bits(instruction_bits_next),
	.ALU_control(ALU_operation)
);


assign PC_imm = PC_EX + imm_out_EX;


//------------EX/MEM + RESET------------
always_ff @(posedge CLOCK or negedge RST_n)
begin
	if (!RST_n)
	begin
		PC4_MEM         <= 0;
		RegWrite_MEM    <= 0;
		MemtoReg_MEM    <= 0;
		Branch_MEM      <= 0;
		MemRead_MEM     <= 0;
		MemWrite_MEM    <= 0;
		zero_MEM        <= 0;
		alu_out_ext_MEM <= 0;
		Jal_MEM         <= 0;
		Jalr_MEM        <= 0;
		PC_imm_MEM      <= 0;
		readData2_MEM   <= 0;
	end
	else
	begin
		PC4_MEM         <= PC4;
		RegWrite_MEM    <= RegWrite_EX;
		MemtoReg_MEM    <= MemtoReg_EX;
		Branch_MEM      <= Branch_EX;
		MemRead_MEM     <= MemRead_EX;
		MemWrite_MEM    <= MemWrite_EX;
		zero_MEM        <= zero_EX;
		alu_out_ext_MEM <= alu_out_ext_EX;
		Jal_MEM         <= Jal_EX;
		Jalr_MEM        <= Jalr_EX;
		PC_imm_MEM      <= PC_imm;
		instr_MEM       <= instr_EX;
		readData2_MEM   <= readData2_EX;
	end
end

	
assign PCSrc = (zero_MEM & Branch_MEM) || Jal_MEM;
assign ena_wr = MemWrite_MEM;
assign ena_rd = MemRead_MEM;
assign dataram_wr = readData2_MEM;


//------------MEM/WB + RESET------------
always_ff @(posedge CLOCK or negedge RST_n)
begin
	if (!RST_n)
	begin
		PC4_WB         <= 0;
		instr_WB       <= 0;
		RegWrite_WB    <= 0;
		MemtoReg_WB    <= 0;
		alu_out_ext_WB <= 0;
		dataram_rd_WB  <= 0;
	end
	else
	begin
		PC4_WB         <= PC4_MEM;
		instr_WB       <= instr_MEM;
		RegWrite_WB    <= RegWrite_MEM;
		MemtoReg_WB    <= MemtoReg_MEM;
		alu_out_ext_WB <= alu_out_ext_MEM;
		dataram_rd_WB  <= dataram_rd;
	end
end


assign datareg_wr = (MemtoReg_WB == 2'b01) ? dataram_rd_WB : ((MemtoReg_WB == 2'b00) ? alu_out_ext_WB : PC4_WB); // Write data to register file
assign alu_out_ext = alu_out_ext_MEM;

endmodule
