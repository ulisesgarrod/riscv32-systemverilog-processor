// Parameterizable RAM: asynchronous read, synchronous write, read enable
module RAM #(
    parameter WIDTH = 32,              // bits per word
    parameter DEPTH = 1024,            // number of locations
    parameter INIT_FILE = ""           // initialization file
)(
    input                      CLK,
    input                      write_enable,     // write enable
    input                      read_enable,      // read enable
    input  [$clog2(DEPTH)-1:0] addr,             // address
    input  [WIDTH-1:0]         din,              // input data
    output [WIDTH-1:0]         dout              // output data
);

    // Memory: DEPTH x WIDTH
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Optional initialization
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // Synchronous write
    always @(posedge CLK) begin
        if (write_enable) begin
            mem[addr] <= din;
        end
    end

    // Asynchronous read WITH enable
    assign dout = (read_enable) ? mem[addr] : {WIDTH{1'b0}};

endmodule
