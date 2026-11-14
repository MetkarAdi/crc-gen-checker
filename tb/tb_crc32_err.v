`timescale 1ns/1ps
module tb_crc32_err;
    parameter NUM_MSG = 200;
    parameter STRIDE  = 18;
    localparam [31:0] RESIDUE = 32'h2144DF1C;   // output for message + its own CRC, no errors

    reg         clk = 0, rst_n = 0, init = 0, en = 0;
    reg  [7:0]  data = 0;
    wire [31:0] crc;

    crc32_par #(.DW(8)) dut (.clk(clk), .rst_n(rst_n), .init(init),
                             .en(en), .data(data), .crc(crc));

    always #5 clk = ~clk;

    reg [31:0] vec [0:NUM_MSG*STRIDE-1];
    reg [7:0]  buffer [0:19];          // message (up to 16 bytes) + 4 CRC bytes
    reg        ok;                     // 1 = checker says "no error"
    reg [31:0] expected;
    reg        dup;
    integer    p [0:4];
    integer    m, i, j, k, n, len, total, bits, base, pos;
    integer    clean_bad, single_n, single_miss, multi_n, multi_miss;

    // Feed buffer[0..nbytes-1] through the CRC and check for the residue
    task run_buffer(input integer nbytes);
        integer t;
        begin
            @(negedge clk); init = 1;
            @(negedge clk); init = 0;
            for (t = 0; t < nbytes; t = t + 1) begin
                @(negedge clk);
                en   = 1;
                data = buffer[t];
            end
            @(negedge clk); en = 0;
            @(negedge clk);
            ok = (crc === RESIDUE);
        end
    endtask

    initial begin
        $readmemh("vectors.hex", vec);
        clean_bad = 0; single_n = 0; single_miss = 0; multi_n = 0; multi_miss = 0;
        #22 rst_n = 1;

        for (m = 0; m < NUM_MSG; m = m + 1) begin
            base     = m*STRIDE;
            len      = vec[base];
            expected = vec[base + 1];

            for (i = 0; i < len; i = i + 1)
                buffer[i] = vec[base + 2 + i][7:0];
            for (i = 0; i < 4; i = i + 1)
                buffer[len + i] = expected[8*i +: 8];   // CRC appended, LSB first
            total = len + 4;
            bits  = total * 8;

            // 1) Clean message must pass
            run_buffer(total);
            if (!ok) begin
                clean_bad = clean_bad + 1;
                $display("FALSE ALARM on clean msg %0d", m);
            end

            // 2) Every single-bit error, in the data and in the CRC field
            for (pos = 0; pos < bits; pos = pos + 1) begin
                buffer[pos/8] = buffer[pos/8] ^ (8'h01 << (pos % 8));
                run_buffer(total);
                single_n = single_n + 1;
                if (ok) begin
                    single_miss = single_miss + 1;
                    $display("MISSED single-bit error: msg %0d bit %0d", m, pos);
                end
                buffer[pos/8] = buffer[pos/8] ^ (8'h01 << (pos % 8));   // restore
            end

            // 3) Random multi-bit errors: 2 to 5 distinct bits, 5 trials per message
            for (n = 0; n < 5; n = n + 1) begin
                k = 2 + ($urandom % 4);
                for (i = 0; i < k; i = i + 1) begin
                    dup = 1;
                    while (dup) begin
                        p[i] = $urandom % bits;
                        dup = 0;
                        for (j = 0; j < i; j = j + 1)
                            if (p[j] == p[i]) dup = 1;
                    end
                end
                for (i = 0; i < k; i = i + 1)
                    buffer[p[i]/8] = buffer[p[i]/8] ^ (8'h01 << (p[i] % 8));
                run_buffer(total);
                multi_n = multi_n + 1;
                if (ok) begin
                    multi_miss = multi_miss + 1;
                    $display("MISSED %0d-bit error in msg %0d", k, m);
                end
                for (i = 0; i < k; i = i + 1)
                    buffer[p[i]/8] = buffer[p[i]/8] ^ (8'h01 << (p[i] % 8));  // restore
            end
        end

        $display("clean messages : %0d checked, %0d false alarms", NUM_MSG, clean_bad);
        $display("single-bit errs: %0d injected, %0d missed", single_n, single_miss);
        $display("multi-bit errs : %0d injected, %0d missed", multi_n, multi_miss);
        if (clean_bad == 0 && single_miss == 0 && multi_miss == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $finish;
    end
endmodule
