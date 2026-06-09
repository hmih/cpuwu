// hello.v — 1-second LED toggle with 10 MHz clock
// Parameter COUNT_MAX lets the testbench override for fast simulation.

module hello #(
    parameter COUNT_MAX = 25'd9_999_999   // 1 second at 10 MHz
) (
    input  wire clk,     // 25 MHz system clock
    output reg  led      // LED output
);
    reg [24:0] counter;  // 25-bit counter (0 .. 33,554,431)

    always @(posedge clk) begin
        if (counter == COUNT_MAX) begin
            counter <= 25'd0;
            led     <= ~led;
        end else begin
            counter <= counter + 25'd1;
        end
    end
endmodule
