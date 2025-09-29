/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module spi_peripheral (
    input  wire       ui_in,
    output  wire [7:0] en_reg_out_7_0,
    output  wire [7:0] en_reg_out_15_8,
    output  wire [7:0] en_reg_pwm_7_0,
    output  wire [7:0] en_reg_pwm_15_8,
    output  wire [7:0] pwm_duty_cycle,
    output  reg  [15:0] buffer,
);
    localparam sclk = ui_in[0];
    localparam ncs = ui_in[1];
    localparam copi = ui_in[2];
        // Process SPI protocol in the clk domain
    reg [3:0] bit_counter = 4'b0;
    reg [15:0] buffer = 16'b0;
    reg sclk_prev;
    wire sclk_posedge = ~sclk_prev & sclk;
    // Update registers only after the complete transaction has finished and been validated
    always @(posedge sclk or negedge ncs) begin
        if (!ncs) begin
            if (sclk_posedge) begin
                if (bit_counter == 4'b16) begin
                    bit_counter <= 4'b0;
                    case (buffer[7:1])
                        7'h00: en_reg_out_7_0   <= buffer[15:8];
                        7'h01: en_reg_out_15_8  <= buffer[15:8];
                        7'h02: en_reg_pwm_7_0   <= buffer[15:8];
                        7'h03: en_reg_pwm_15_8  <= buffer[15:8];
                        7'h04: pwm_duty_cycle   <= buffer[15:8];
                        default: ;
                    buffer <= 16'b0;
                    endcase
                end else begin
                    buffer <= {buffer[14:0], copi};
                    bit_counter <= bit_counter + 1'b1;
                end
            end
        end else if (ncs) begin
            en_reg_out_7_0 <= 8'b0;
            en_reg_out_15_8 <= 8'b0;
            en_reg_pwm_7_0 <= 8'b0;
            en_reg_pwm_15_8 <= 8'b0;
            pwm_duty_cycle <= 8'b0;
            bit_counter <= 4'b0;
        end
        sclk_prev <= sclk;
    end

endmodule
