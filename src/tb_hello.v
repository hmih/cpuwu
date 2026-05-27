// tb_hello.v -- testbench for hello module
`timescale 1ns / 1ps

module tb_hello;
    reg clk;
    wire led;

    hello uut (
        .clk(clk),
        .led(led)
    );

    // 25 MHz clock: 20 ns period
    always #10 clk = ~clk;

    initial begin
        $dumpfile("hello_tb.vcd");
        $dumpvars(0, tb_hello);
        clk = 0;

        // Run for a few toggle cycles (bit 24 toggles every 2^24 cycles)
        // 2^25 * 20ns = 671 ms to see one full led toggle
        // Just run long enough to see counter advancing
        #5000;  // 5 µs — see lower counter bits increment

        $finish;
    end
endmodule
