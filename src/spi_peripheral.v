/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module spi_peripheral (
    input  wire [7:0]  ui_in,
    input  wire       clk,  // system clock
    output  wire [7:0] en_reg_out_7_0,
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
    wire ncs = ui_in[2];
    wire copi = ui_in[1];
    reg [15:0] buffer = 16'b0;
        // Process SPI protocol in the clk domain
    reg [4:0] bit_counter = 5'b0;
    reg sclk_dly1, sclk_dly2;
    always @(posedge clk) begin
        sclk_dly1 <= sclk;
        sclk_dly2 <= sclk_dly1;
    end
    wire sclk_posedge = ~sclk_dly2 & sclk_dly1;
    // Update registers only after the complete transaction has finished and been validated
    always @(posedge sclk or posedge ncs) begin
        if (!ncs) begin
            if (sclk_posedge) begin
                buffer <= {buffer[14:0], copi};
                bit_counter <= bit_counter + 1'b1;
            end
        end else begin
            if (bit_counter == 5'd16) begin 
                case (buffer[7:1])
                    7'h00: en_reg_out_7_0_r   <= buffer[15:8];
                    7'h01: en_reg_out_15_8_r  <= buffer[15:8];
                    7'h02: en_reg_pwm_7_0_r   <= buffer[15:8];
                    7'h03: en_reg_pwm_15_8_r  <= buffer[15:8];
                    7'h04: pwm_duty_cycle_r   <= buffer[15:8];
                    default: ;
                endcase
            end
            bit_counter <= 5'b0;
            buffer <= 16'b0;
        end
    end

endmodule
