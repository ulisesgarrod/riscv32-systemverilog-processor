module register_file(
    input  logic        CLK, RST_n,
    input  logic [4:0]  readReg1, readReg2, writeReg,
    input  logic [31:0] writeData,
    input  logic        RegWrite,
    output logic [31:0] readData1, readData2
);

logic [31:0] registers [31:0]; // 32 registers of 32 bits

always_ff @(posedge CLK or negedge RST_n) begin
    if (!RST_n) begin
        registers <= '{default:0};   // reset to zero
    end else begin
        registers[0] <= 32'b0;       // x0 is always 0
        if (RegWrite && writeReg != 5'd0)
            registers[writeReg] <= writeData;
    end
end

assign readData1 = registers[readReg1];
assign readData2 = registers[readReg2];

endmodule
