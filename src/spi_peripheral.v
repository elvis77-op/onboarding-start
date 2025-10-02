module spi_peripheral (
    input  wire [7:0]  ui_in,
    input  wire       clk,  // system clock
    input wire       rst_n, // reset_n - low to reset
    output  wire [7:0] en_reg_out_7_0, // Output register
    output  wire [7:0] en_reg_out_15_8,
    output  wire [7:0] en_reg_pwm_7_0,
    output  wire [7:0] en_reg_pwm_15_8,
    output  wire [7:0] pwm_duty_cycle
);
    reg [7:0] en_reg_out_7_0_r;
    assign en_reg_out_7_0 = en_reg_out_7_0_r;
    reg [7:0] en_reg_out_15_8_r;
    assign en_reg_out_15_8 = en_reg_out_15_8_r;
    reg [7:0] en_reg_pwm_7_0_r;
    assign en_reg_pwm_7_0 = en_reg_pwm_7_0_r;
    reg [7:0] en_reg_pwm_15_8_r;
    assign en_reg_pwm_15_8 = en_reg_pwm_15_8_r;
    reg [7:0] pwm_duty_cycle_r;
    assign pwm_duty_cycle = pwm_duty_cycle_r;

    wire sclk = ui_in[0];
    wire ncs  = ui_in[2];
    wire copi = ui_in[1];

    reg [15:0] buffer;
    reg [4:0] bit_counter; 

    reg sclk_dly1, sclk_dly2, ncs_sync1, ncs_sync2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_dly1 <= 1'b0;
            sclk_dly2 <= 1'b0;
            ncs_sync1 <= 1'b1; 
            ncs_sync2 <= 1'b1;
        end else begin
            sclk_dly1 <= sclk;
            sclk_dly2 <= sclk_dly1;
            ncs_sync1 <= ncs;
            ncs_sync2 <= ncs_sync1;
        end
    end

    wire sclk_posedge = (~sclk_dly2) & sclk_dly1;
    wire ncs_posedge  = (~ncs_sync2) & ncs_sync1;
    wire ncs_negedge  = ncs_sync2 & (~ncs_sync1);

    // ----------------------------------------------------------
    // Shift in bits on SCLK rising edge ONLY while nCS is low (active)
    // Note on bit-order:
    //   Current implementation shifts left and appends new sample into LSB:
    //     buffer <= {buffer[14:0], copi};
    //   After receiving sequential bits b0..b15 (b0 first), final buffer will be:
    //     buffer[15] = b0, buffer[14] = b1, ..., buffer[0] = b15
    //   Thus buffer[15:8] holds the first byte received and buffer[7:0] holds the second byte.
    //   Ensure that the SPI master sends bytes in the same order you expect.
    // ----------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 5'd0;
            buffer <= 16'd0;
        end else begin
            // Only sample SCLK while chip-select is active (nCS low)
            if ((ncs_sync2 == 1'b0) && sclk_posedge && (bit_counter < 5'd16)) begin
                buffer <= {copi, buffer[15:1]};
                bit_counter <= bit_counter + 1'b1;
            end
            // If chip-select goes high before we complete 16 bits, just reset (abort)
            if (ncs_posedge && (bit_counter != 5'd16)) begin
                // abort incomplete transaction
                bit_counter <= 5'd0;
                buffer <= 16'd0;
            end
        end
    end


    reg transaction_valid; // optional flag if you want to indicate a valid transaction happened
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0_r <= 8'b0;
            en_reg_out_15_8_r <= 8'b0;
            en_reg_pwm_7_0_r <= 8'b0;
            en_reg_pwm_15_8_r <= 8'b0;
            pwm_duty_cycle_r <= 8'b0;
            transaction_valid <= 1'b0;
            buffer <= 16'd0;
            bit_counter <= 5'd0;
        end else begin
            if (ncs_posedge) begin
                if (bit_counter == 5'd16) begin
                    case (buffer[7:1])
                        7'h00: en_reg_out_7_0_r <= buffer[15:8];
                        7'h01: en_reg_out_15_8_r <= buffer[15:8];
                        7'h02: en_reg_pwm_7_0_r <= buffer[15:8];
                        7'h03: en_reg_pwm_15_8_r <= buffer[15:8];
                        7'h04: pwm_duty_cycle_r <= buffer[15:8];
                        default: ;
                    endcase
                    transaction_valid <= 1'b1;
                end else begin
                    // incomplete/invalid transaction -> ignore
                    transaction_valid <= 1'b0;
                end
                buffer <= 16'd0;
                bit_counter <= 5'd0;
            end
        end
    end

endmodule
