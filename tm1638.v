//============================================================
// TM1638 Driver Module
// - Drive 8-digit 7-segment LEDs
// - Control discrete LEDs
// - Read button states
// - Generate SCLK enable for external clock-gating cell
//============================================================
module tm1638 (
    input  wire        clk,
    input  wire        rst_n,

    output wire        SCLK,   // SCLK enable (to external clock-enable cell)
    output reg         CS_n,       // Chip select (active low)
    inout  wire        DIO,        // Bidirectional data line

    input  wire [63:0] seg,        // Flattened 7-seg data (8 digits)
    input  wire [7:0]  led,        // Discrete LEDs
    output reg  [7:0]  button      // Button status
);

    //========================================================
    // Configuration
    //========================================================
    localparam BRIDGNESS = 3'd0;

    //========================================================
    // Main FSM states
    //========================================================
    localparam 
        ST_INITIAL  = 2'd0,   // Display control command
        ST_LEDS_CMD = 2'd1,   // Write LED command
        ST_LEDS     = 2'd2,   // Write LED & 7-seg data
        ST_BUTTON   = 2'd3;   // Read button data

    //========================================================
    // TM1638 instruction constants
    //========================================================
    localparam 
        DISPLAY_CMD_INST    = {5'h11, BRIDGNESS},
        WR_LED_CMD_INST     = 8'h40,
        START_LED_ADDR_INST = 8'hC0,
        RD_BUTTON_CMD_INST  = 8'h42;

    //========================================================
    // DIO tristate control
    //========================================================
    reg d_out;
    assign DIO = (d_out == 1'b1) ? 1'bZ : 1'b0;

    //========================================================
    // Internal registers
    //========================================================
    reg [1:0]  state;
    reg [5:0]  cnt;
    reg [7:0]  but_tam;

    reg [63:0] sub_seg;      // Shadow register for seg
    reg [7:0]  sub_led;      // Shadow register for led

    //========================================================
    // Shift interface control
    //========================================================
    reg  [7:0] shift_data;
    reg        shift_start;
    reg        shift_en;
    wire       shift_busy;

    //========================================================
    // SCLK enable generation
    //========================================================
    reg sclk_en_out;
    reg sclk_en_in;
    assign SCLK = (sclk_en_out | sclk_en_in)? clk: 1'b1;

    //========================================================
    // Main FSM (posedge clk)
    //========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            but_tam     <= 8'd0;
            button      <= 8'd0;
            cnt         <= 6'd0;
            shift_data  <= 8'd0;
            shift_start <= 1'b0;
            shift_en    <= 1'b1;
            sclk_en_in  <= 1'b0;
            sub_led     <= 8'd0;
            sub_seg     <= 64'd0;
            state       <= ST_INITIAL;
        end
        else begin
            case (state)

                //------------------------------------------------
                // Send display control command
                //------------------------------------------------
                ST_INITIAL: begin
                    shift_en <= 1'b1;
                    sub_led <= led;
                    sub_seg <= seg;
                    if (!shift_busy) begin
                        shift_data  <= DISPLAY_CMD_INST;
                        shift_start <= 1'b1;
                        if (shift_start) begin
                            shift_start <= 1'b0;
                            shift_en    <= 1'b0;
                            state       <= ST_LEDS_CMD;
                        end
                    end
                end

                //------------------------------------------------
                // Send write LED command
                //------------------------------------------------
                ST_LEDS_CMD: begin
                    shift_en <= 1'b1;
                    if (!shift_busy) begin
                        shift_data  <= WR_LED_CMD_INST;
                        shift_start <= 1'b1;
                        if (shift_start) begin
                            shift_start <= 1'b0;
                            shift_en    <= 1'b0;
                            state       <= ST_LEDS;
                        end
                    end
                end

                //------------------------------------------------
                // Write LED & 7-segment data
                //------------------------------------------------
                ST_LEDS: begin
                    shift_en <= 1'b1;
                    shift_start <= 1'b1;
                    if (!shift_busy) begin
                        cnt <= cnt + 1'b1;
                        if (cnt == 6'd0) begin
                            shift_data <= START_LED_ADDR_INST;
                        end
                        else if (cnt < 6'd17) begin
                            if (cnt[0]) begin
                                shift_data <= sub_seg[(cnt >> 1) << 3 +: 8];
                            end
                            else begin
                                shift_data <= {7'd0, sub_led[(cnt >> 1) - 1]};
                            end
                        end
                        else begin
                            shift_en <= 1'b0;
                            cnt      <= 6'd0;
                            state    <= ST_BUTTON;
                        end
                    end
                end

                //------------------------------------------------
                // Read button data
                //------------------------------------------------
                ST_BUTTON: begin
                    if (!shift_busy) begin
                        cnt <= cnt + 1'b1;

                        if (cnt == 6'd0) begin
                            shift_data  <= RD_BUTTON_CMD_INST;
                            shift_start <= 1'b1;
                            shift_en    <= 1'b1;
                        end
                        else if (cnt < 6'd4) begin
                            shift_start <= 1'b0;
                            if (cnt == 6'd3)
                                sclk_en_in <= 1'b1;
                        end
                        else begin
                            if (cnt[2:0] == 3'd4)
                                but_tam[3:0] <= {DIO, but_tam[3:1]};
                            else if (cnt[2:0] == 3'd0)
                                but_tam[7:4] <= {DIO, but_tam[7:5]};
                        end

                        if (cnt == 6'd36) begin
                            shift_en   <= 1'b0;
                            button     <= but_tam;
                            cnt        <= 6'd0;
                            sclk_en_in <= 1'b0;

                            if (led != sub_led || seg != sub_seg) begin
                                sub_led <= led;
                                sub_seg <= seg;
                                state   <= ST_LEDS_CMD;
                            end
                            else
                                state <= ST_BUTTON;
                        end
                    end
                end

                default: state <= ST_INITIAL;
            endcase
        end
    end

    //========================================================
    // Shift engine (negedge clk)
    //========================================================
    localparam 
        ST_SHIFT_IDLE  = 1'd0,
        ST_SHIFT_START = 1'd1;

    reg       shift_state;
    reg [2:0] shift_count;

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_out        <= 1'b1;
            shift_count  <= 3'd0;
            shift_state  <= ST_SHIFT_IDLE;
            CS_n         <= 1'b1;
            sclk_en_out  <= 1'b0;
        end
        else begin
            case (shift_state)

                ST_SHIFT_IDLE: begin
                    d_out       <= 1'b1;
                    sclk_en_out <= 1'b0;
                    if (!shift_en)
                        CS_n <= 1'b1;

                    if (shift_start && shift_en)
                        shift_state <= ST_SHIFT_START;
                    else
                        shift_state <= ST_SHIFT_IDLE;
                end

                ST_SHIFT_START: begin
                    CS_n         <= 1'b0;
                    sclk_en_out  <= 1'b1;
                    d_out        <= shift_data[shift_count];
                    shift_count  <= shift_count + 1'b1;

                    if (shift_count == 3'd7) begin
                        shift_count <= 3'd0;
                        shift_state <= ST_SHIFT_IDLE;
                    end
                end

                default: ;
            endcase
        end
    end

    //========================================================
    // Shift busy flag
    //========================================================
    assign shift_busy = (shift_state == ST_SHIFT_START);

endmodule
