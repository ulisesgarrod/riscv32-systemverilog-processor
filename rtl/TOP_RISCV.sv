module TOP_RISCV(CLOCK, RST_n);

input CLOCK, RST_n;

logic [31:0] PC_addr, instr_rom, alu_result, dataram_rd_next, dataram_wr_next;
logic ena_wr_next, ena_rd_next;


ROM #(.WIDTH(32), .DEPTH(1024), .INIT_FILE("Instructions.txt")) ROM_inst
(
	.addr(PC_addr[11:2]) , // only 10 bits because this is defined by the DEPTH parameter of our ROM
	.dout(instr_rom) 	// output [WIDTH-1:0] dout
);

TOP_CORE TOP_CORE_inst
(
	.instr(instr_rom) ,	// input [31:0] instr
	.dataram_rd(dataram_rd_next) ,	// input [31:0] dataram_rd
	.CLOCK(CLOCK) ,	// input CLOCK
	.RST_n(RST_n) ,	// input RST_n
	.PC(PC_addr) ,	// output [31:0] PC
	.ena_wr(ena_wr_next) ,	// output ena_wr
	.ena_rd(ena_rd_next) ,	// output ena_rd
	.alu_out_ext(alu_result) ,	// output [31:0] alu_out_ext
	.dataram_wr(dataram_wr_next) 	// output [31:0] dataram_wr
);

RAM #(.INIT_FILE("RAM_Instructions.txt")) RAM_inst
(
	.CLK(CLOCK) ,	// input CLK
	.write_enable(ena_wr_next) ,	// input write_enable
	.read_enable(ena_rd_next) ,	// input read_enable
	.addr(alu_result[11:2]) , // only 10 bits because this is defined by the DEPTH parameter of our RAM
	.din(dataram_wr_next) ,	// input [WIDTH-1:0] din
	.dout(dataram_rd_next) 	// output [WIDTH-1:0] dout
);

endmodule
