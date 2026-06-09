// tb_hello.v — testbench for hello module
// Overrides COUNT_MAX to a small value for fast simulation.

`timescale 1ns / 1ps

module tb_hello;
    reg clk;
    wire led;

    // COUNT_MAX = 5 → toggle every 6 cycles (120 ns)
    hello #(.COUNT_MAX(25'd5)) uut (
        .clk(clk),
        .led(led)
    );

    // 25 MHz clock: 20 ns period (10 ns half-cycle)
    always #10 clk = ~clk;

    initial begin
        $dumpfile("gen/hello_tb.vcd");
        $dumpvars(0, tb_hello);
        clk = 0;

        // Let it toggle a few times: 6 cycles × 20 ns = 120 ns per toggle
        // 500 ns covers ~4 toggles
        #500;
        $finish;
    end
endmodule
