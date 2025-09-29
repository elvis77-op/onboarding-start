
module tt_um_uwasic_onboarding_elvis (
  // Add this inside the module block
  assign uio_oe = 8'hFF; // Set all IOs to output
  // Create wires to refer to the values of the registers
  input clk,
  input rst_n,
  input ena,
  input [7:0] uio_in,
  output [7:0] uo_out,
  output [7:0] uio_out,
  output [7:0] uio_oe,
  output [15:0] buffer,
  input [7:0] ui_in
)
  wire [7:0] en_reg_out_7_0;
  wire [7:0] en_reg_out_15_8;
  wire [7:0] en_reg_pwm_7_0;
  wire [7:0] en_reg_pwm_15_8;
  wire [7:0] pwm_duty_cycle;
  reg [15:0] buffer;
  wire ncs_posedge = ~ui_in[0] & csn;
  spi_peripheral spi_peripheral_inst (
    .ui_in(ui_in),
    .en_reg_out_7_0(en_reg_out_7_0),
    .en_reg_out_15_8(en_reg_out_15_8),
    .en_reg_pwm_7_0(en_reg_pwm_7_0),
    .en_reg_pwm_15_8(en_reg_pwm_15_8),
    .pwm_duty_cycle(pwm_duty_cycle),
  );

  // Instantiate the PWM module
  pwm_peripheral pwm_peripheral_inst (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg_out_7_0(en_reg_out_7_0),
    .en_reg_out_15_8(en_reg_out_15_8),
    .en_reg_pwm_7_0(en_reg_pwm_7_0),
    .en_reg_pwm_15_8(en_reg_pwm_15_8),
    .pwm_duty_cycle(pwm_duty_cycle),
    .out({uio_out, uo_out})
  );
  // Add uio_in and ui_in[7:3] to the list of unused signals:
  wire _unused = &{ena, ui_in[7:3], uio_in, 1'b0};   
endmodule