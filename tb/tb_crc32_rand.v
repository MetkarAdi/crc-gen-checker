`timescale 1ns/1ps
module tb_crc32_rand;
    parameter NUM_MSG = 200;
    parameter STRIDE  = 18;      // words per message in vectors.hex

    reg         clk = 0, rst_n = 0, init = 0, en = 0, din = 0;
    wire [31:0] crc;

    crc32_serial dut (.clk(clk), .rst_n(rst_n), .init(init),
                      .en(en), .din(din), .crc(crc));

    always #5 clk = ~clk;

    reg [31:0] vec [0:NUM_MSG*STRIDE-1];
    reg [31:0] tmp, expected;
    reg [7:0]  byte_val;
    integer    m, i, b, len, errors;

    initial begin
        $readmemh("vectors.hex", vec);
        errors = 0;
        #22 rst_n = 1;

        for (m = 0; m < NUM_MSG; m = m + 1) begin
            len      = vec[m*STRIDE];
            expected = vec[m*STRIDE + 1];

            @(negedge clk); init = 1;
            @(negedge clk); init = 0;

            for (i = 0; i < len; i = i + 1) begin
                tmp      = vec[m*STRIDE + 2 + i];
                byte_val = tmp[7:0];
                for (b = 0; b < 8; b = b + 1) begin
                    @(negedge clk);
                    en  = 1;
                    din = byte_val[b];
                end
            end
            @(negedge clk); en = 0;
            @(negedge clk);

            if (crc !== expected) begin
                errors = errors + 1;
                $display("MISMATCH msg %0d (len %0d): got %h expected %h",
                         m, len, crc, expected);
            end
        end

        $display("messages checked: %0d   errors: %0d", NUM_MSG, errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $finish;
    end
endmodule
