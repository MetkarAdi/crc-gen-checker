`timescale 1ns/1ps
module tb_crc32_serial;
    reg         clk = 0, rst_n = 0, init = 0, en = 0, din = 0;
    wire [31:0] crc;

    crc32_serial dut (.clk(clk), .rst_n(rst_n), .init(init),
                      .en(en), .din(din), .crc(crc));

    always #5 clk = ~clk;

    // Send one byte, least significant bit first, one bit per clock
    task send_byte(input [7:0] b);
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                @(negedge clk);
                en  = 1;
                din = b[i];
            end
            @(negedge clk);
            en = 0;
        end
    endtask

    reg [71:0] msg = "123456789";   // 9 characters, first character in the top byte
    integer k;

    initial begin
        $dumpfile("crc.vcd");
        $dumpvars(0, tb_crc32_serial);
        #22 rst_n = 1;
        @(negedge clk); init = 1;
        @(negedge clk); init = 0;

        for (k = 8; k >= 0; k = k - 1)
            send_byte(msg[k*8 +: 8]);

        @(negedge clk);
        $display("CRC-32 of \"123456789\" = %h (expected cbf43926)", crc);
        if (crc === 32'hCBF43926) $display("RESULT: PASS");
        else                      $display("RESULT: FAIL");
        $finish;
    end
endmodule
