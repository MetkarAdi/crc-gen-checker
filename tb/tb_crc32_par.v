`timescale 1ns/1ps
module tb_crc32_par;
    parameter NUM_MSG = 200;
    parameter STRIDE  = 18;

    reg         clk = 0, rst_n = 0, init = 0;
    reg         en8 = 0, en32 = 0;
    reg  [7:0]  d8  = 0;
    reg  [31:0] d32 = 0;
    wire [31:0] crc8, crc32w;

    crc32_par #(.DW(8))  u8  (.clk(clk), .rst_n(rst_n), .init(init),
                              .en(en8),  .data(d8),  .crc(crc8));
    crc32_par #(.DW(32)) u32 (.clk(clk), .rst_n(rst_n), .init(init),
                              .en(en32), .data(d32), .crc(crc32w));

    always #5 clk = ~clk;

    reg [31:0] vec [0:NUM_MSG*STRIDE-1];
    reg [31:0] expected;
    integer m, i, w, len, base, err8, err32, chk32;

    initial begin
        $readmemh("vectors.hex", vec);
        err8 = 0; err32 = 0; chk32 = 0;
        #22 rst_n = 1;

        for (m = 0; m < NUM_MSG; m = m + 1) begin
            base     = m*STRIDE;
            len      = vec[base];
            expected = vec[base + 1];

            @(negedge clk); init = 1;
            @(negedge clk); init = 0;

            // 8 bits per clock: one byte each cycle
            for (i = 0; i < len; i = i + 1) begin
                @(negedge clk);
                en8 = 1;
                d8  = vec[base + 2 + i][7:0];
            end
            @(negedge clk); en8 = 0;

            // 32 bits per clock: only when the length is a whole number of words
            if (len % 4 == 0) begin
                for (w = 0; w < len/4; w = w + 1) begin
                    @(negedge clk);
                    en32 = 1;
                    d32  = { vec[base + 2 + 4*w + 3][7:0],
                             vec[base + 2 + 4*w + 2][7:0],
                             vec[base + 2 + 4*w + 1][7:0],
                             vec[base + 2 + 4*w + 0][7:0] };
                end
                @(negedge clk); en32 = 0;
            end

            @(negedge clk);

            if (crc8 !== expected) begin
                err8 = err8 + 1;
                $display("8-bit MISMATCH msg %0d: got %h expected %h", m, crc8, expected);
            end
            if (len % 4 == 0) begin
                chk32 = chk32 + 1;
                if (crc32w !== expected) begin
                    err32 = err32 + 1;
                    $display("32-bit MISMATCH msg %0d: got %h expected %h", m, crc32w, expected);
                end
            end
        end

        $display("8-bit  parallel: %0d messages checked, %0d errors", NUM_MSG, err8);
        $display("32-bit parallel: %0d messages checked, %0d errors", chk32, err32);
        if (err8 == 0 && err32 == 0) $display("RESULT: PASS");
        else                         $display("RESULT: FAIL");
        $finish;
    end
endmodule
