/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module spi_peripheral (
    input  wire [7:0]  ui_in,
    input  wire       clk,  // system clock
    input wire       rst_n, // reset_n - low to reset
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
    reg [4:0] bit_counter = 5'b0;
    reg sclk_dly1, sclk_dly2, ncs_sync1, ncs_sync2;
    always @(posedge clk) begin
        sclk_dly1 <= sclk;
        sclk_dly2 <= sclk_dly1;
    end
    always @(posedge clk) begin
        ncs_sync1 <= ncs;
        ncs_sync2 <= ncs_sync1;
    end
    wire sclk_posedge = ~sclk_dly2 & sclk_dly1;
    wire ncs_posedge = ~ncs_sync2 & ncs_sync1;
    reg transaction_ready = 1'b0;
    reg transaction_processed = 1'b0;
    // Update registers only after the complete transaction has finished and been validated
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transaction_ready <= 1'b0;
        end else if (ncs_sync2 == 1'b0) begin
        end else begin
            // When nCS goes high (transaction ends), validate the complete transaction
            if (ncs_posedge) begin
                transaction_ready <= 1'b1;
            end else if (transaction_processed) begin
                // Clear ready flag once processed
                transaction_ready <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 5'b0;
            buffer <= 16'b0;
            en_reg_out_7_0_r <= 8'b0;
            en_reg_out_15_8_r <= 8'b0;
            en_reg_pwm_7_0_r <= 8'b0;
            en_reg_pwm_15_8_r <= 8'b0;
            pwm_duty_cycle_r <= 8'b0;
            transaction_processed <= 1'b0;
        end else begin
            if (sclk_posedge && (bit_counter < 5'd16)) begin
                buffer <= {buffer[14:0], copi};
                bit_counter <= bit_counter + 1'b1;
            end

            if (bit_counter == 5'd16) begin
                case (buffer[7:1])
                    7'h00: en_reg_out_7_0_r <= buffer[15:8];
                    7'h01: en_reg_out_15_8_r <= buffer[15:8];
                    7'h02: en_reg_pwm_7_0_r <= buffer[15:8];
                    7'h03: en_reg_pwm_15_8_r <= buffer[15:8];
                    7'h04: pwm_duty_cycle_r <= buffer[15:8];
                    default: ;
                endcase
                transaction_processed <= 1'b1; 
                bit_counter <= 5'b0; 
                buffer <= 16'b0;
            end else if (!transaction_ready && transaction_processed) begin
                transaction_processed <= 1'b0;
                bit_counter <= 5'b0; 
                buffer <= 16'b0;
            end
        end
    end
endmodule
