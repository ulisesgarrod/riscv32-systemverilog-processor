// Parameterizable ROM: asynchronous read
module ROM #(
    parameter WIDTH = 32,              // bits per word
    parameter DEPTH = 1024,            // number of locations
    parameter INIT_FILE = ""           // initialization file
)(
    input  [$clog2(DEPTH)-1:0] addr,   // address (log2(DEPTH) bits)
    output [WIDTH-1:0] dout
);
    // Memory: DEPTH x WIDTH
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Optional initialization
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem); 
        end
    end

    // Asynchronous read
    assign dout = mem[addr];

endmodule
