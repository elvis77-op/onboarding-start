module spi_peripheral (
    input  wire [7:0]  ui_in,
    input  wire       clk,  // system clock
    input wire       rst_n, // reset_n - low to reset
    output  reg [7:0] en_reg_out_7_0, // Output register
    output  reg [7:0] en_reg_out_15_8,
    output  reg [7:0] en_reg_pwm_7_0,
    output  reg [7:0] en_reg_pwm_15_8,
    output  reg [7:0] pwm_duty_cycle
);
    wire sclk = ui_in[0];
    wire ncs  = ui_in[2];
    wire copi = ui_in[1];

    reg [15:0] buffer;
    reg [4:0] bit_counter; 

    reg sclk_dly1, sclk_dly2, ncs_sync1, ncs_sync2, copi_sync1, copi_sync2;
    always @(posedge clk) begin
        sclk_dly1 <= sclk;
        sclk_dly2 <= sclk_dly1;
        copi_sync1 <= copi;
        ncs_sync1 <= ncs;
        ncs_sync2 <= ncs_sync1;
        copi_sync2 <= copi_sync1;
    end

    wire sclk_posedge = (~sclk_dly2) & sclk_dly1;
    wire ncs_posedge  = (~ncs_sync2) & ncs_sync1;
    wire ncs_negedge  = ncs_sync2 & (~ncs_sync1);

    reg transaction_ready; // Indicates that a transaction is ready to be processed
    reg transaction_processed; // Indicates that the transaction has been processed
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transaction_ready <= 1'b0;
        end else if (ncs_sync2 == 1'b0) begin
        end else begin
            if (ncs_negedge) begin
                transaction_ready <= 1'b1;
            end else if (transaction_processed) begin
                transaction_ready <= 1'b0;
            end
        end
    end


    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0 <= 8'h00;
            en_reg_out_15_8 <= 8'h00;
            en_reg_pwm_7_0 <= 8'h00;
            en_reg_pwm_15_8 <= 8'h00;
            pwm_duty_cycle <= 8'h00;
            buffer <= 16'd0;
            bit_counter <= 5'd0;
            transaction_processed <= 1'b0;
        end else if(transaction_ready && !transaction_processed) begin
            if (ncs_sync1 == 1'b0) begin
                if (sclk_posedge) begin
                    if (bit_counter < 5'd16) begin
                        buffer <= {buffer[14:0], copi_sync2};
                        bit_counter <= bit_counter + 5'd1;
                    end
                end
            end
            if (bit_counter == 5'd16 && buffer[15] == 1'b1) begin
            $display("[%0t] SPI transaction complete: buffer = %b (addr = %h, data = %h)", 
             $time, buffer, buffer[14:8], buffer[7:0]);
                case (buffer[14:8])
                    7'h00: en_reg_out_7_0 <= buffer[7:0];
                    7'h01: en_reg_out_15_8 <= buffer[7:0];
                    7'h02: en_reg_pwm_7_0 <= buffer[7:0];
                    7'h03: en_reg_pwm_15_8 <= buffer[7:0];
                    7'h04: pwm_duty_cycle <= buffer[7:0];
                    default: ;
                endcase
                transaction_processed <= 1'b1;
            end
        end else if (!transaction_ready && transaction_processed) begin
            buffer <= 16'd0;
            bit_counter <= 5'd0;
            transaction_processed <= 1'b0;
        end
    end

endmodule
