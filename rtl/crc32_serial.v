module crc32_serial (
    input         clk,
    input         rst_n,
    input         init,    // reload the starting value (1 pulse before each message)
    input         en,      // process one bit this cycle
    input         din,     // the data bit, least significant bit of each byte first
    output [31:0] crc      // final CRC (register inverted)
);
    localparam [31:0] POLY = 32'hEDB88320;   // CRC-32 polynomial, reflected form

    reg  [31:0] state;
    wire        fb = state[0] ^ din;         // feedback bit

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 32'hFFFFFFFF;
        else if (init)
            state <= 32'hFFFFFFFF;
        else if (en)
            state <= (state >> 1) ^ (fb ? POLY : 32'h0);
    end

    assign crc = ~state;
endmodule
