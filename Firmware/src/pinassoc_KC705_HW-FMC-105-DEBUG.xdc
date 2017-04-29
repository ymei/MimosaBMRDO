# -------------------Ladder signal------------------
# LA00
set_property PACKAGE_PIN C25      [get_ports L1_PM_CLK_P]
set_property IOSTANDARD  LVDS_25  [get_ports L1_PM_CLK_P]
set_property PACKAGE_PIN B25      [get_ports L1_PM_CLK_N]
set_property IOSTANDARD  LVDS_25  [get_ports L1_PM_CLK_N]
# LA11
set_property PACKAGE_PIN G27      [get_ports L_SENSOR_OUT_P[0]]
set_property IOSTANDARD  LVDS_25  [get_ports L_SENSOR_OUT_P[0]]
set_property PACKAGE_PIN F27      [get_ports L_SENSOR_OUT_N[0]]
set_property IOSTANDARD  LVDS_25  [get_ports L_SENSOR_OUT_N[0]]
# LA12
set_property PACKAGE_PIN C29      [get_ports L_SENSOR_OUT_P[1]]
set_property IOSTANDARD  LVDS_25  [get_ports L_SENSOR_OUT_P[1]]
set_property PACKAGE_PIN B29      [get_ports L_SENSOR_OUT_N[1]]
set_property IOSTANDARD  LVDS_25  [get_ports L_SENSOR_OUT_N[1]]
# LA13
set_property PACKAGE_PIN A25      [get_ports L_START_P]
set_property IOSTANDARD  LVDS_25  [get_ports L_START_P]
set_property PACKAGE_PIN A26      [get_ports L_START_N]
set_property IOSTANDARD  LVDS_25  [get_ports L_START_N]
# LA09
set_property PACKAGE_PIN B30      [get_ports L_RSTB_P]
set_property IOSTANDARD  LVDS_25  [get_ports L_RSTB_P]
set_property PACKAGE_PIN A30      [get_ports L_RSTB_N]
set_property IOSTANDARD  LVDS_25  [get_ports L_RSTB_N]
# LA06
set_property PACKAGE_PIN H30      [get_ports L_JTAG_TDO_P]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TDO_P]
set_property PACKAGE_PIN G30      [get_ports L_JTAG_TDO_N]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TDO_N]
# LA07
set_property PACKAGE_PIN E28      [get_ports L_JTAG_TDI_P]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TDI_P]
set_property PACKAGE_PIN D28      [get_ports L_JTAG_TDI_N]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TDI_N]
# LA10
set_property PACKAGE_PIN D29      [get_ports L_JTAG_TMS_P]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TMS_P]
set_property PACKAGE_PIN C30      [get_ports L_JTAG_TMS_N]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TMS_N]
# LA08
set_property PACKAGE_PIN E29      [get_ports L_JTAG_TCK_P]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TCK_P]
set_property PACKAGE_PIN E30      [get_ports L_JTAG_TCK_N]
set_property IOSTANDARD  LVDS_25  [get_ports L_JTAG_TCK_N]

# -------------------I2C BUS------------------------
# LA04
set_property PACKAGE_PIN G28      [get_ports SCL_P]
set_property IOSTANDARD  LVDS_25  [get_ports SCL_P]
set_property PACKAGE_PIN F28      [get_ports SCL_N]
set_property IOSTANDARD  LVDS_25  [get_ports SCL_N]
# LA05
set_property PACKAGE_PIN G29      [get_ports SDA_W_P]
set_property IOSTANDARD  LVDS_25  [get_ports SDA_W_P]
set_property PACKAGE_PIN F30      [get_ports SDA_W_N]
set_property IOSTANDARD  LVDS_25  [get_ports SDA_W_N]
# LA03
set_property PACKAGE_PIN H26      [get_ports SDA_R_P]
set_property IOSTANDARD  LVDS_25  [get_ports SDA_R_P]
set_property PACKAGE_PIN H27      [get_ports SDA_R_N]
set_property IOSTANDARD  LVDS_25  [get_ports SDA_R_N]

# -------10Mhz clk_in and out   START and STOP IN-----------
# J9
set_property PACKAGE_PIN D17      [get_ports USER_CLK]
set_property IOSTANDARD  LVCMOS25  [get_ports USER_CLK]
# J10
set_property PACKAGE_PIN D18      [get_ports CLK_10M_OUT]
set_property IOSTANDARD  LVCMOS25  [get_ports CLK_10M_OUT]
# J13
set_property PACKAGE_PIN Y23      [get_ports START_IN]
set_property IOSTANDARD  LVCMOS25  [get_ports START_IN]
# J14
set_property PACKAGE_PIN Y24      [get_ports STOP_IN]
set_property IOSTANDARD  LVCMOS25  [get_ports STOP_IN]

# -----------------set IODELAY CTRL location-------
set_property LOC IDELAYCTRL_X0Y4 [get_cells delayctrl_inst]
