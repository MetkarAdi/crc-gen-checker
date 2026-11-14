module crc32_par #(parameter DW = 8) (    // DW = bits per clock (multiple of 8)
    input           clk,
    input           rst_n,
    input           init,
    input           en,
    input  [DW-1:0] data,    // data[7:0] is the first byte, each byte LSB first
    output [31:0]   crc
);
    localparam [31:0] POLY = 32'hEDB88320;

    // Apply DW single-bit CRC steps in order, as combinational logic
    function [31:0] step(input [31:0] c, input [DW-1:0] d);
        integer i;
        reg [31:0] s;
        begin
            s = c;
            for (i = 0; i < DW; i = i + 1)
                s = (s >> 1) ^ ((s[0] ^ d[i]) ? POLY : 32'h0);
            step = s;
        end
    endfunction

    reg  [31:0] state;
    wire [31:0] next_state = step(state, data);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 32'hFFFFFFFF;
        else if (init)
            state <= 32'hFFFFFFFF;
        else if (en)
            state <= next_state;
    end

    assign crc = ~state;
endmodule
