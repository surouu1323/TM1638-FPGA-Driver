//============================================================
// Top module
// - Generate 1MHz clock from input clock using PLL
// - Generate gated SCLK using dedicated clock-enable cell
// - Drive TM1638 LED & button module
//============================================================
module top (
    input  wire clk,
    input  wire rst,
    input  wire trig,
    output wire SCLK,
    output wire CS_n,
    inout  wire DIO
);

    //========================================================
    // Reset (active-low)
    //========================================================
    wire rst_n;
    assign rst_n = ~rst;

    //========================================================
    // Clock signals
    //========================================================
    wire clk_1mhz;

    //========================================================
    // PLL: input clock -> 24MHz / 1MHz
    //========================================================
    PLL_24Mhz_1Mhz PLL_24Mhz_1Mhz_u (
        .clkout (),        // 24 MHz output (unused)
        .clkoutd(clk_1mhz),// 1 MHz output
        .reset  (rst),     // active-high reset
        .clkin  (clk)      // input clock
    );

    //========================================================
    // Button interface
    //========================================================
    wire [7:0] button;
    reg  [7:0] button_reg;

    // Register button data for stable LED display
    always @(posedge clk_1mhz or negedge rst_n) begin
        if (!rst_n)
            button_reg <= 8'd1;
        else
            button_reg <= button;
    end

    //========================================================
    // 7-segment display data
    //========================================================
    wire [63:0] seg;

    // Counter module generating flattened 7-seg data
    counter counter_u (
        .clk_1mhz(clk_1mhz),
        .rst_n   (rst_n),
        .seg_flat(seg)
    );

    //========================================================
    // TM1638 LED & button driver
    //========================================================
    tm1638 tm1638_inst (
        .clk    (clk_1mhz),
        .rst_n  (rst_n),
        .SCLK   (SCLK),
        .CS_n   (CS_n),
        .DIO    (DIO),
        .seg    (seg),
        .led    (button_reg),
        .button (button)
    );

endmodule
