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

    reg transaction_ready; // Indicates that a transaction is ready to be processed
    reg transaction_processed; // Indicates that the transaction has been processed
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transaction_ready <= 1'b0;
        end else if (ncs_sync2 == 1'b0) begin
        end else begin
            if (ncs_posedge) begin
                transaction_ready <= 1'b1;
            end else if (transaction_processed) begin
                transaction_ready <= 1'b0;
            end
        end
    end


    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0_r <= 8'h00;
            en_reg_out_15_8_r <= 8'h00;
            en_reg_pwm_7_0_r <= 8'h00;
            en_reg_pwm_15_8_r <= 8'h00;
            pwm_duty_cycle_r <= 8'h00;
            buffer <= 16'd0;
            bit_counter <= 5'd0;
        end else begin
            if (!ncs) begin
                if (sclk_posedge) begin
                    if(transaction_ready && !transaction_processed) begin 
                        if (bit_counter == 5'd16) begin
                            case (buffer[14:8])
                                7'h00: en_reg_out_7_0_r <= buffer[7:0];
                                7'h01: en_reg_out_15_8_r <= buffer[7:0];
                                7'h02: en_reg_pwm_7_0_r <= buffer[7:0];
                                7'h03: en_reg_pwm_15_8_r <= buffer[7:0];
                                7'h04: pwm_duty_cycle_r <= buffer[7:0];
                                default: ;
                            endcase
                            transaction_processed <= 1'b1;
                        end else begin
                            buffer <= {buffer[14:0], copi};
                            bit_counter <= bit_counter + 5'd1;
                        end
                    end
                end
            end else if (!transaction_ready && transaction_processed) begin
                buffer <= 16'd0;
                bit_counter <= 5'd0;
                transaction_processed <= 1'b0;
            end
        end
    end

endmodule
