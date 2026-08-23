module TOP_CORE_pipeline_hazards(instr, CLOCK, RST_n, dataram_rd, PC, ena_wr, ena_rd, alu_out_ext, dataram_wr);

input [31:0] instr;
input RST_n, CLOCK;
input logic [31:0] dataram_rd;

output logic [31:0] PC;
output logic ena_wr, ena_rd;     // RAM read/write enable
output logic [31:0] alu_out_ext; // RAM address
output logic [31:0] dataram_wr;


// General signals
logic [31:0] datareg_wr;           // MemtoReg mux output
logic [31:0] PC_next;
logic [3:0] instruction_bits_next, ALU_operation;
logic PCSrc;


// ID
logic [31:0] PC_ID, instr_ID, readData1_ID, readData2_ID, imm_out_ID;
logic [31:0] readData1_ID_bypass, readData2_ID_bypass;

logic Branch_ID, MemRead_ID, MemWrite_ID, RegWrite_ID;
logic AluSrc_ID, Jal_ID, Jalr_ID;

logic [2:0] AluOp_ID;
logic [1:0] MemtoReg_ID, AuipcLui_ID;


// EX
logic RegWrite_EX, Branch_EX, MemRead_EX, MemWrite_EX;
logic AluSrc_EX, Jal_EX, Jalr_EX, zero_EX;

logic [1:0] MemtoReg_EX, AuipcLui_EX;
logic [2:0] AluOp_EX;

logic [31:0] PC_EX;
logic [31:0] PC4;
logic [31:0] readData1_EX, readData2_EX;
logic [31:0] imm_out_EX;
logic [31:0] instr_EX;
logic [31:0] value_A, value_B;
logic [31:0] alu_out_ext_EX;
logic [31:0] PC_imm;


// MEM
logic RegWrite_MEM, Branch_MEM, MemRead_MEM, MemWrite_MEM;
logic zero_MEM, Jal_MEM, Jalr_MEM;

logic [1:0] MemtoReg_MEM;

logic [31:0] PC4_MEM;
logic [31:0] alu_out_ext_MEM;
logic [31:0] readData2_MEM;
logic [31:0] PC_imm_MEM;
logic [31:0] instr_MEM;


// WB
logic RegWrite_WB;
logic [1:0] MemtoReg_WB;

logic [31:0] PC4_WB;
logic [31:0] alu_out_ext_WB;
logic [31:0] dataram_rd_WB;
logic [31:0] instr_WB;


// FORWARDING UNIT
logic [1:0] ForwardA, ForwardB;

logic [4:0] sourceA_EX, sourceB_EX;
logic [4:0] destination_EX;
logic [4:0] destination_MEM;
logic [4:0] destination_WB;

logic [31:0] readData2_EX_fwd;
logic [31:0] A_fwd;


// HAZARD UNIT
logic stall;
logic PCWrite;
logic IFIDWrite;
logic IFIDFlush;

logic uses_source1_ID;
logic uses_source2_ID;

logic [4:0] source1_ID;
logic [4:0] source2_ID;

logic [6:0] opcode_ID;


// PROGRAM COUNTER
always_ff @(posedge CLOCK or negedge RST_n)
begin
	if (!RST_n)
		PC <= '0;
	else if (PCWrite)
		PC <= PC_next;
end


assign PC_next = Jalr_MEM ? {alu_out_ext_MEM[31:1], 1'b0} :
					  PCSrc    ? PC_imm_MEM :
					  (PC + 4);


// IF/ID
always_ff @(posedge CLOCK or negedge RST_n)
begin
	if (!RST_n)
	begin
		PC_ID    <= '0;
		instr_ID <= 32'b0;
	end

	else if (IFIDFlush)
	begin
		PC_ID    <= PC;
		instr_ID <= 32'b0;
	end

	else if (IFIDWrite)
	begin
		PC_ID    <= PC;
		instr_ID <= instr;
	end
end


// REGISTER FILE
register_file register_file_inst
(
	.CLK(CLOCK),
	.RST_n(RST_n),
	.readReg1(instr_ID[19:15]),
	.readReg2(instr_ID[24:20]),
	.writeReg(instr_WB[11:7]),
	.writeData(datareg_wr),
	.readData1(readData1_ID),
	.readData2(readData2_ID),
	.RegWrite(RegWrite_WB)
);


// IMMEDIATE GENERATOR
Imm_Gen Imm_Gen_inst
(
	.instruction(instr_ID),
	.immediate(imm_out_ID)
);


// CONTROL UNIT
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


// HAZARD DETECTION UNIT
assign opcode_ID = instr_ID[6:0];

assign source1_ID = instr_ID[19:15];
assign source2_ID = instr_ID[24:20];


// Instructions that use rs1
assign uses_source1_ID =
	(opcode_ID == 7'b0110011) ||   // R-type
	(opcode_ID == 7'b0010011) ||   // I-type
	(opcode_ID == 7'b0000011) ||   // LOAD
	(opcode_ID == 7'b0100011) ||   // STORE
	(opcode_ID == 7'b1100011) ||   // BRANCH
	(opcode_ID == 7'b1100111);     // JALR


// Instructions that use rs2
assign uses_source2_ID =
	(opcode_ID == 7'b0110011) ||   // R-type
	(opcode_ID == 7'b0100011) ||   // STORE
	(opcode_ID == 7'b1100011);     // BRANCH


// Load-use hazard
assign stall =
	MemRead_EX &&
	(destination_EX != 5'd0) &&
	(
		(uses_source1_ID && (destination_EX == source1_ID)) ||
		(uses_source2_ID && (destination_EX == source2_ID))
	);


// A taken branch, JAL or JALR invalidates younger instructions
assign IFIDFlush = PCSrc || Jalr_MEM;


// A control transfer has priority over a data stall
assign PCWrite =
	(!stall) || IFIDFlush;


assign IFIDWrite =
	!stall;


// WB -> ID BYPASS
//
// If WB writes a register that the instruction currently
// in ID is reading, use the WB value directly instead of
// the old register-file value.
//

assign readData1_ID_bypass =
	(RegWrite_WB &&
	 (destination_WB != 5'd0) &&
	 (destination_WB == source1_ID))
	?
	datareg_wr :
	readData1_ID;


assign readData2_ID_bypass =
	(RegWrite_WB &&
	 (destination_WB != 5'd0) &&
	 (destination_WB == source2_ID))
	?
	datareg_wr :
	readData2_ID;


// ID/EX
always_ff @(posedge CLOCK or negedge RST_n)
begin
	if (!RST_n)
	begin
		RegWrite_EX  	<= 0;
		MemtoReg_EX  	<= 0;
		Branch_EX    	<= 0;
		MemRead_EX   	<= 0;
		MemWrite_EX  	<= 0;
		AluOp_EX    	<= 0;
		AluSrc_EX    	<= 0;
		AuipcLui_EX  	<= 0;
		Jal_EX       	<= 0;
		Jalr_EX      	<= 0;
		PC_EX        	<= 0;
		readData1_EX 	<= 0;
		readData2_EX 	<= 0;
		imm_out_EX   	<= 0;
		instr_EX     	<= 0;
		destination_EX <= 0;
	end

	// Flush instructions following a taken branch/jump
	else if (IFIDFlush)
	begin
		RegWrite_EX  	<= 0;
		MemtoReg_EX  	<= 0;
		Branch_EX    	<= 0;
		MemRead_EX   	<= 0;
		MemWrite_EX  	<= 0;
		AluOp_EX     	<= 0;
		AluSrc_EX    	<= 0;
		AuipcLui_EX  	<= 0;
		Jal_EX       	<= 0;
		Jalr_EX      	<= 0;
		PC_EX        	<= 0;
		readData1_EX 	<= 0;
		readData2_EX 	<= 0;
		imm_out_EX   	<= 0;
		instr_EX     	<= 0;
		destination_EX <= 0;
	end

	// Insert bubble for a load-use hazard
	else if (stall)
	begin
		RegWrite_EX  	<= 0;
		MemtoReg_EX  	<= 0;
		Branch_EX    	<= 0;
		MemRead_EX   	<= 0;
		MemWrite_EX  	<= 0;
		AluOp_EX     	<= 0;
		AluSrc_EX    	<= 0;
		AuipcLui_EX  	<= 0;
		Jal_EX       	<= 0;
		Jalr_EX      	<= 0;
		PC_EX        	<= 0;
		readData1_EX 	<= 0;
		readData2_EX 	<= 0;
		imm_out_EX   	<= 0;
		instr_EX     	<= 0;
		destination_EX <= 0;
	end

	else
	begin
		RegWrite_EX  	<= RegWrite_ID;
		MemtoReg_EX  	<= MemtoReg_ID;
		Branch_EX    	<= Branch_ID;
		MemRead_EX   	<= MemRead_ID;
		MemWrite_EX  	<= MemWrite_ID;
		AluOp_EX     	<= AluOp_ID;
		AluSrc_EX    	<= AluSrc_ID;
		AuipcLui_EX  	<= AuipcLui_ID;
		Jal_EX       	<= Jal_ID;
		Jalr_EX      	<= Jalr_ID;
		PC_EX        	<= PC_ID;
		readData1_EX 	<= readData1_ID_bypass;
		readData2_EX 	<= readData2_ID_bypass;
		imm_out_EX   	<= imm_out_ID;
		instr_EX     	<= instr_ID;
		destination_EX <= instr_ID[11:7];
	end
end


assign PC4 = PC_EX + 4;


// FORWARDING UNIT
assign sourceA_EX = instr_EX[19:15];
assign sourceB_EX = instr_EX[24:20];


// Forwarding for ALU input A
always_comb
begin
	if (
		RegWrite_MEM &&
		(destination_MEM != 5'b0) &&
		(destination_MEM == sourceA_EX)
	)
		ForwardA = 2'b10;

	else if (
		RegWrite_WB &&
		(destination_WB != 5'b0) &&
		(destination_WB == sourceA_EX)
	)
		ForwardA = 2'b01;

	else
		ForwardA = 2'b00;
end


// Forwarding for ALU input B / store data
always_comb
begin
	if (
		RegWrite_MEM &&
		(destination_MEM != 5'b0) &&
		(destination_MEM == sourceB_EX)
	)
		ForwardB = 2'b10;

	else if (
		RegWrite_WB &&
		(destination_WB != 5'b0) &&
		(destination_WB == sourceB_EX)
	)
		ForwardB = 2'b01;

	else
		ForwardB = 2'b00;
end



assign readData2_EX_fwd =
	(ForwardB == 2'b10) ? alu_out_ext_MEM :
	(ForwardB == 2'b01) ? datareg_wr :
	                      readData2_EX;



assign A_fwd =
	(ForwardA == 2'b10) ? alu_out_ext_MEM :
	(ForwardA == 2'b01) ? datareg_wr :
	                      readData1_EX;


// ALU INPUT A MUX
always_comb
begin
	case (AuipcLui_EX)

		2'b00:
			value_A = PC_EX;

		2'b01:
			value_A = 32'd0;

		default:
			value_A = A_fwd;

	endcase
end



// ALU input B mux
assign value_B =
	AluSrc_EX ? imm_out_EX : readData2_EX_fwd;


// ALU
ALU ALU_inst
(
	.A(value_A),
	.B(value_B),

	.ALU_control(ALU_operation),
	.ALU_result(alu_out_ext_EX),

	.zero(zero_EX)
);



assign instruction_bits_next =
	{instr_EX[30], instr_EX[14:12]};



ALU_CONTROL ALU_CONTROL_inst
(
	.ALUOp(AluOp_EX),
	.instruction_bits(instruction_bits_next),
	.ALU_control(ALU_operation)
);



assign PC_imm =
	PC_EX + imm_out_EX;


// EX/MEM
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
		instr_MEM       <= 0;
		destination_MEM <= 0;
	end

	// Remove the younger instruction already in EX
	// when a branch/jump is resolved in MEM.
	else if (IFIDFlush)
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
		instr_MEM       <= 0;
		destination_MEM <= 0;
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
		readData2_MEM   <= readData2_EX_fwd;
		destination_MEM <= destination_EX;
	end
end


// BRANCH / MEMORY CONTROL
assign PCSrc = (zero_MEM & Branch_MEM) || Jal_MEM;


assign ena_wr = MemWrite_MEM;


assign ena_rd = MemRead_MEM;


assign dataram_wr = readData2_MEM;


// MEM/WB
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
		destination_WB <= 0;
	end

	else
	begin
		PC4_WB         <= PC4_MEM;
		instr_WB       <= instr_MEM;
		RegWrite_WB    <= RegWrite_MEM;
		MemtoReg_WB    <= MemtoReg_MEM;
		alu_out_ext_WB <= alu_out_ext_MEM;
		dataram_rd_WB  <= dataram_rd;
		destination_WB <= destination_MEM;
	end
end


// WRITEBACK
assign datareg_wr =
	(MemtoReg_WB == 2'b01) ? dataram_rd_WB :
	(MemtoReg_WB == 2'b00) ? alu_out_ext_WB :
	                         PC4_WB;


assign alu_out_ext = alu_out_ext_MEM;


endmodule
