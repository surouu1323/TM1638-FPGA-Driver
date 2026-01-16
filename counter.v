module counter (
    input        clk_1mhz,
    input        rst_n,
    output [63:0] seg_flat   // 8 LED, mỗi LED 1 byte (FLATTEN)
);

    // =====================================================
    // Clock divider: 1 MHz -> 10 Hz
    // =====================================================
    reg [23:0] div_cnt;
    reg        tick_10hz;

    always @(posedge clk_1mhz or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt   <= 0;
            tick_10hz <= 1'b0;
        end else if (div_cnt == 24'd999_999) begin
            div_cnt   <= 0;
            tick_10hz <= 1'b1;
        end else begin
            div_cnt   <= div_cnt + 1'b1;
            tick_10hz <= 1'b0;
        end
    end

    // =====================================================
    // 4-bit HEX counter: 0 -> F
    // =====================================================
    reg [3:0] hex_cnt;

    always @(posedge clk_1mhz or negedge rst_n) begin
        if (!rst_n)
            hex_cnt <= 4'h0;
        else if (tick_10hz)
            hex_cnt <= hex_cnt + 1'b1;
    end



    // =====================================================
    // FLATTEN array -> output bus
    // =====================================================
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : FLATTEN_OUT
            assign seg_flat[i*8 +: 8] = {1'b0, hex_to_7seg(hex_cnt)};
        end
    endgenerate

    // =====================================================
    // Hex to 7-segment decoder
    // =====================================================
    function [6:0] hex_to_7seg;
        input [3:0] hex;
        begin
            case (hex)
                4'h0: hex_to_7seg = 7'b0111111;
                4'h1: hex_to_7seg = 7'b0000110;
                4'h2: hex_to_7seg = 7'b1011011;
                4'h3: hex_to_7seg = 7'b1001111;
                4'h4: hex_to_7seg = 7'b1100110;
                4'h5: hex_to_7seg = 7'b1101101;
                4'h6: hex_to_7seg = 7'b1111101;
                4'h7: hex_to_7seg = 7'b0000111;
                4'h8: hex_to_7seg = 7'b1111111;
                4'h9: hex_to_7seg = 7'b1101111;
                4'hA: hex_to_7seg = 7'b1110111;
                4'hB: hex_to_7seg = 7'b1111100;
                4'hC: hex_to_7seg = 7'b0111001;
                4'hD: hex_to_7seg = 7'b1011110;
                4'hE: hex_to_7seg = 7'b1111001;
                4'hF: hex_to_7seg = 7'b1110001;
                default: hex_to_7seg = 7'b0000000;
            endcase
        end
    endfunction

endmodule
