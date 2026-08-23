module GPIO (
  // Bus side
  input  logic        clk,
  input  logic        reset,      // Active low
  input  logic        write_en,   // Register 1 write enable
  input  logic        read_en,    // Register 2 read enable
  input  logic [15:0] dataw,      // Data written by the core to GPIO
  output logic [15:0] datar,      // Data read by the core from GPIO

  // Board side
  input  logic [15:0] SW,         // Physical switches
  output logic [15:0] LEDR,       // Red LEDs
  output logic [6:0]  HEX0,       // Units
  output logic [6:0]  HEX1,       // Tens
  output logic [6:0]  HEX2,       // Hundreds
  output logic [6:0]  HEX3        // Thousands
);

  // REGISTER 1: LEDR (write)
  // LEDR stores dataw when write_en = 1
  always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
      LEDR <= 16'd0;
    end else begin
      if (write_en) begin
        LEDR <= dataw;
      end
    end
  end

  // REGISTER 2: asynchronous read
  // datar returns the switch values when read_en = 1
  always_comb begin
    if (read_en)
      datar = SW;
    else
      datar = 16'd0;
  end

  // BCD + 7-segment conversion from LEDR output
  // Take the LEDR value (0..65535) and limit it to 0..9999
  logic [15:0] val;
  logic [3:0]  u, d, c, m; // Units, tens, hundreds, thousands

  always_comb begin
    val = LEDR;

    if (val > 16'd9999)
      val = 16'd9999;

    // Binary-to-BCD conversion using division (synthesizable)
    u =  val % 10;
    d = (val / 10)   % 10;
    c = (val / 100)  % 10;
    m = (val / 1000) % 10;
  end

  // BCD-to-7-segment decoder (assuming active-low outputs)
  function automatic logic [6:0] bcd_to_7seg(input logic [3:0] bcd);
    case (bcd)
      4'd0: bcd_to_7seg = 7'b1000000;
      4'd1: bcd_to_7seg = 7'b1111001;
      4'd2: bcd_to_7seg = 7'b0100100;
      4'd3: bcd_to_7seg = 7'b0110000;
      4'd4: bcd_to_7seg = 7'b0011001;
      4'd5: bcd_to_7seg = 7'b0010010;
      4'd6: bcd_to_7seg = 7'b0000010;
      4'd7: bcd_to_7seg = 7'b1111000;
      4'd8: bcd_to_7seg = 7'b0000000;
      4'd9: bcd_to_7seg = 7'b0010000;
      default: bcd_to_7seg = 7'b1111111; // All segments off
    endcase
  endfunction

  // Assign each digit to its corresponding display
  always_comb begin
    HEX0 = bcd_to_7seg(u); // Units
    HEX1 = bcd_to_7seg(d); // Tens
    HEX2 = bcd_to_7seg(c); // Hundreds
    HEX3 = bcd_to_7seg(m); // Thousands
  end

endmodule
