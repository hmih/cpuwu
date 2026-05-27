// hello.v -- simple counter driving an LED
// Toggles output every ~1 second with a 25 MHz clock

module hello (
    input  wire clk,    // 25 MHz system clock
    output reg  led     // LED output
);
    // 25-bit counter: 2^25 / 25e6 ≈ 1.34 seconds
    reg [24:0] counter;

    always @(posedge clk) begin
        counter <= counter + 1;
        led     <= counter[24];
    end
endmodule
