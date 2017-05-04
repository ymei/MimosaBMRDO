--------------------------------------------------------------------------------
--! @file top_KC705.vhd
--! @brief MIMOSA sensor readout toplevel module for KC705 eval board.
--! @author Dong Wang
--!
--! Target Devices: Kintex-7 XC7K325T-FFG900-2
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

USE ieee.std_logic_unsigned.ALL;

ENTITY top_KC705 IS
  GENERIC(
    -- this generic controls the inclusion of the chipscope code
    -- at the bottom of this file:
    bIncludeChipscope : boolean := false);
  PORT (
    ---------------------------------------------------------------------------
    -- Board clock 200MHz and reset SW7
    ---------------------------------------------------------------------------
    SYS_CLK_P      : IN    std_logic;   --  system clock 200MHz
    SYS_CLK_N      : IN    std_logic;
    CPU_RESET      : IN    std_logic;   --  active high reset
    USER_CLK       : IN    std_logic;   --  user clock 10MHz
    CLK_10M_OUT    : OUT   std_logic;   --  clock 10MHz output
    START_IN       : IN    std_logic;   --  user start in
    STOP_IN        : IN    std_logic;   --  user stop in
    --
    ---------------------------------------------------------------------------
    -- I2C BUS
    ---------------------------------------------------------------------------
    SCL_P          : OUT   std_logic;   --  I2C SCL
    SCL_N          : OUT   std_logic;
    SDA_W_P        : OUT   std_logic;   --  I2C SDA write
    SDA_W_N        : OUT   std_logic;
    SDA_R_P        : IN    std_logic;   --  I2C SDA read
    SDA_R_N        : IN    std_logic;
    --
    ---------------------------------------------------------------------------
    -- GBE PORT
    ---------------------------------------------------------------------------
    SGMIICLK_Q0_P  : IN    std_logic;   --  SGMCLK 125Mhz
    SGMIICLK_Q0_N  : IN    std_logic;
    PHY_RESET_N    : OUT   std_logic;
    RGMII_TXD      : OUT   std_logic_vector(3 DOWNTO 0);
    RGMII_TX_CTL   : OUT   std_logic;
    RGMII_TXC      : OUT   std_logic;
    RGMII_RXD      : IN    std_logic_vector(3 DOWNTO 0);
    RGMII_RX_CTL   : IN    std_logic;
    RGMII_RXC      : IN    std_logic;
    MDIO           : INOUT std_logic;
    MDC            : OUT   std_logic;
    --
    ---------------------------------------------------------------------------
    -- Ladder signals
    ---------------------------------------------------------------------------
    -- sensor outputs (2 outputs)
    L_SENSOR_OUT_P : IN    std_logic_vector(1 DOWNTO 0);
    L_SENSOR_OUT_N : IN    std_logic_vector(1 DOWNTO 0);
    -- Ladder control signals
    L_START_P      : OUT   std_logic;
    L_START_N      : OUT   std_logic;
    L_RSTB_P       : OUT   std_logic;
    L_RSTB_N       : OUT   std_logic;
    L_JTAG_TDO_P   : IN    std_logic;
    L_JTAG_TDO_N   : IN    std_logic;
    L_JTAG_TDI_P   : OUT   std_logic;
    L_JTAG_TDI_N   : OUT   std_logic;
    L_JTAG_TMS_P   : OUT   std_logic;
    L_JTAG_TMS_N   : OUT   std_logic;
    L_JTAG_TCK_P   : OUT   std_logic;
    L_JTAG_TCK_N   : OUT   std_logic;
    L1_PM_CLK_P    : OUT   std_logic;
    L1_PM_CLK_N    : OUT   std_logic
  );
END top_KC705;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Begin of the Architecture --------------------------------------------------
-------------------------------------------------------------------------------
ARCHITECTURE behavior OF top_KC705 IS
  -----------------------------------------------------------------------------
  -- Constants
  -- CONSTANT SVNVERSION      : std_logic_vector(15 DOWNTO 0) := svnversion_from_file("revision.txt");
  -- a frame contains 1856 16bit words
  CONSTANT FRAME_SIZE      : integer                       := 1856;
  CONSTANT HEADER_PATTERN  : std_logic_vector(15 DOWNTO 0) := x"AAAA";
  CONSTANT TRAILER_PATTERN : std_logic_vector(15 DOWNTO 0) := x"5678";

  -- Components
  COMPONENT gig_eth
    PORT (
      -- asynchronous reset
      glbl_rst             : IN    std_logic;
      -- clocks
      gtx_clk              : IN    std_logic;  -- 125MHz
      ref_clk              : IN    std_logic;  -- 200MHz
      -- PHY interface
      phy_resetn           : OUT   std_logic;
      -- RGMII Interface
      ------------------
      rgmii_txd            : OUT   std_logic_vector(3 DOWNTO 0);
      rgmii_tx_ctl         : OUT   std_logic;
      rgmii_txc            : OUT   std_logic;
      rgmii_rxd            : IN    std_logic_vector(3 DOWNTO 0);
      rgmii_rx_ctl         : IN    std_logic;
      rgmii_rxc            : IN    std_logic;
      -- MDIO Interface
      -----------------
      mdio                 : INOUT std_logic;
      mdc                  : OUT   std_logic;
      -- TCP
      MAC_ADDR             : IN    std_logic_vector(47 DOWNTO 0);
      IPv4_ADDR            : IN    std_logic_vector(31 DOWNTO 0);
      IPv6_ADDR            : IN    std_logic_vector(127 DOWNTO 0);
      SUBNET_MASK          : IN    std_logic_vector(31 DOWNTO 0);
      GATEWAY_IP_ADDR      : IN    std_logic_vector(31 DOWNTO 0);
      TCP_CONNECTION_RESET : IN    std_logic;
      TX_TDATA             : IN    std_logic_vector(7 DOWNTO 0);
      TX_TVALID            : IN    std_logic;
      TX_TREADY            : OUT   std_logic;
      RX_TDATA             : OUT   std_logic_vector(7 DOWNTO 0);
      RX_TVALID            : OUT   std_logic;
      RX_TREADY            : IN    std_logic;
      -- FIFO
      TCP_USE_FIFO         : IN    std_logic;
      TX_FIFO_WRCLK        : IN    std_logic;
      TX_FIFO_Q            : IN    std_logic_vector(31 DOWNTO 0);
      TX_FIFO_WREN         : IN    std_logic;
      TX_FIFO_FULL         : OUT   std_logic;
      RX_FIFO_RDCLK        : IN    std_logic;
      RX_FIFO_Q            : OUT   std_logic_vector(31 DOWNTO 0);
      RX_FIFO_RDEN         : IN    std_logic;
      RX_FIFO_EMPTY        : OUT   std_logic
    );
  END COMPONENT;

  COMPONENT i2c_wr_bytes IS
    PORT (
      CLK      : IN  std_logic;         --  system clock 50Mhz
      RESET    : IN  std_logic;         --  active high reset
      START    : IN  std_logic;  -- the rising edge trigger a start, generate by config_reg
      MODE     : IN  std_logic_vector(1 DOWNTO 0);  -- '0' is 1 bytes read or write, '1' is 2 bytes read or write,
                                 -- '2' is 3 bytes write only , don't set to '3'
      SL_WR    : IN  std_logic;         -- '0' is write, '1' is read
      SL_ADDR  : IN  std_logic_vector(6 DOWNTO 0);  -- slave addr
      WR_ADDR  : IN  std_logic_vector(7 DOWNTO 0);  -- chip internal addr for read and write
      WR_DATA0 : IN  std_logic_vector(7 DOWNTO 0);  -- first byte data for write
      WR_DATA1 : IN  std_logic_vector(7 DOWNTO 0);  -- second byte data for write
      RD_DATA0 : OUT std_logic_vector(7 DOWNTO 0);  -- first byte readout
      RD_DATA1 : OUT std_logic_vector(7 DOWNTO 0);  -- second byte readout
      BUSY     : OUT std_logic;         -- indicates transaction in progress
      SDA_in   : IN  std_logic;         -- serial data input of i2c bus
      SDA_out  : OUT std_logic;         -- serial data output of i2c bus
      SDA_T    : OUT std_logic;         -- serial data direction of i2c bus
      SCL      : OUT std_logic          -- serial clock output of i2c bus
    );
  END COMPONENT;

  COMPONENT global_clock_reset
    PORT (
      SYS_CLK_P  : IN  std_logic;
      SYS_CLK_N  : IN  std_logic;
      FORCE_RST  : IN  std_logic;
      -- output
      GLOBAL_RST : OUT std_logic;
      SYS_CLK    : OUT std_logic;
      CLK_OUT1   : OUT std_logic;
      CLK_OUT2   : OUT std_logic;
      CLK_OUT3   : OUT std_logic;
      CLK_OUT4   : OUT std_logic
    );
  END COMPONENT;

  COMPONENT control_interface
    PORT (
      RESET           : IN  std_logic;
      CLK             : IN  std_logic;  -- system clock
      -- From FPGA to PC
      FIFO_Q          : OUT std_logic_vector(35 DOWNTO 0);  -- interface fifo data output port
      FIFO_EMPTY      : OUT std_logic;  -- interface fifo "emtpy" signal
      FIFO_RDREQ      : IN  std_logic;  -- interface fifo read request
      FIFO_RDCLK      : IN  std_logic;  -- interface fifo read clock
      -- From PC to FPGA, FWFT
      CMD_FIFO_Q      : IN  std_logic_vector(35 DOWNTO 0);  -- interface command fifo data out port
      CMD_FIFO_EMPTY  : IN  std_logic;  -- interface command fifo "emtpy" signal
      CMD_FIFO_RDREQ  : OUT std_logic;  -- interface command fifo read request
      -- Digital I/O
      CONFIG_REG      : OUT std_logic_vector(511 DOWNTO 0);  -- thirtytwo 16bit registers
      PULSE_REG       : OUT std_logic_vector(15 DOWNTO 0);  -- 16bit pulse register
      STATUS_REG      : IN  std_logic_vector(175 DOWNTO 0);  -- eleven 16bit registers
      -- Memory interface
      MEM_WE          : OUT std_logic;  -- memory write enable
      MEM_ADDR        : OUT std_logic_vector(31 DOWNTO 0);
      MEM_DIN         : OUT std_logic_vector(31 DOWNTO 0);  -- memory data input
      MEM_DOUT        : IN  std_logic_vector(31 DOWNTO 0);  -- memory data output
      -- Data FIFO interface, FWFT
      DATA_FIFO_Q     : IN  std_logic_vector(31 DOWNTO 0);
      DATA_FIFO_EMPTY : IN  std_logic;
      DATA_FIFO_RDREQ : OUT std_logic;
      DATA_FIFO_RDCLK : OUT std_logic
    );
  END COMPONENT;

  COMPONENT jtag IS
    PORT (
      CLK        : IN  std_logic;
      RST        : IN  std_logic;
      START      : IN  std_logic;
      WEN        : IN  std_logic;
      READ_DATA  : OUT std_logic_vector (31 DOWNTO 0);
      WRITE_DATA : IN  std_logic_vector (31 DOWNTO 0);
      ADDRESS    : IN  std_logic_vector (11 DOWNTO 0);
      DONE       : OUT std_logic;
      DIVIDE     : IN  std_logic_vector (3 DOWNTO 0);
      DO_RSTB    : IN  std_logic;
      TMS_OUT    : OUT std_logic;
      TDI_OUT    : OUT std_logic;
      TCK_OUT    : OUT std_logic;
      TDO_IN     : IN  std_logic;
      RSTB_OUT   : OUT std_logic
    );
  END COMPONENT jtag;

  COMPONENT sensor_deserializer IS
    GENERIC (
      FRAME_SIZE     : integer;
      HEADER_PATTERN : std_logic_vector(15 DOWNTO 0)
    );
    PORT (
      RST           : IN  std_logic;
      CTRLCLK       : IN  std_logic;
      DATACLK       : IN  std_logic;
      LATCHCLK      : IN  std_logic;
      SER_RESET     : IN  std_logic;
      LOAD_CONFIG   : IN  std_logic;
      DELAY_CONFIG0 : IN  std_logic_vector(5 DOWNTO 0);
      DELAY_CONFIG1 : IN  std_logic_vector(5 DOWNTO 0);
      SIG_IN        : IN  std_logic_vector(1 DOWNTO 0);
      SIG_PAR       : OUT std_logic_vector(31 DOWNTO 0);
      ERR           : OUT std_logic
    );
  END COMPONENT sensor_deserializer;

  COMPONENT data_mod IS
    GENERIC (
      HEADER_PATTERN  : std_logic_vector(15 DOWNTO 0);
      TRAILER_PATTERN : std_logic_vector (15 DOWNTO 0)
    );
    PORT (
      CLK           : IN  std_logic;
      RESET         : IN  std_logic;
      DATA_IN       : IN  std_logic_vector(31 DOWNTO 0);
      CHIP_ID       : IN  std_logic_vector(5 DOWNTO 0);
      TRIGGER_DELAY : IN  integer RANGE 0 TO 31 := 4;
      TRAILER_ERR   : OUT std_logic;
      DATA_OUT      : OUT std_logic_vector(31 DOWNTO 0);
      IsHEADER      : OUT std_logic;
      IsSTATED      : OUT std_logic;
      IsTRAILER     : OUT std_logic;
      IsCounter_L   : OUT std_logic;
      IsCounter_H   : OUT std_logic
    );
  END COMPONENT data_mod;

  COMPONENT fifo32to32
    PORT (
      rst        : IN  std_logic;
      wr_clk     : IN  std_logic;
      rd_clk     : IN  std_logic;
      din        : IN  std_logic_vector(31 DOWNTO 0);
      wr_en      : IN  std_logic;
      rd_en      : IN  std_logic;
      dout       : OUT std_logic_vector(31 DOWNTO 0);
      full       : OUT std_logic;
      empty      : OUT std_logic;
      prog_empty : OUT std_logic
    );
  END COMPONENT;

  COMPONENT clk_switch
    PORT (
      -- Clock in ports
      clk_in1    : IN  std_logic;
      clk_in2    : IN  std_logic;
      clk_in_sel : IN  std_logic;
      -- Clock out ports
      clk_out1   : OUT std_logic;
      clk_out2   : OUT std_logic;
      -- Status and control signals
      reset      : IN  std_logic;
      locked     : OUT std_logic
    );
  END COMPONENT;

  COMPONENT i2c_tic
    PORT (
      CLK   : IN std_logic;             --  system clock 60Mhz
      RESET : IN std_logic;             --  active high reset

      START    : OUT std_logic;  -- the rising edge trigger a start, generate by config_reg
      MODE     : OUT std_logic_vector(1 DOWNTO 0);  -- '0' is 1 bytes read or write, '1' is 2 bytes read or write,
                                 -- '2' is 3 bytes write only , don't set to '3'
      SL_WR    : OUT std_logic;         -- '0' is write, '1' is read
      SL_ADDR  : OUT std_logic_vector(6 DOWNTO 0);  -- slave addr
      WR_ADDR  : OUT std_logic_vector(7 DOWNTO 0);  -- chip internal addr for read and write
      WR_DATA0 : OUT std_logic_vector(7 DOWNTO 0);  -- first byte data for write
      WR_DATA1 : OUT std_logic_vector(7 DOWNTO 0);  -- second byte data for write
      RD_DATA0 : IN  std_logic_vector(7 DOWNTO 0);  -- first byte readout
      RD_DATA1 : IN  std_logic_vector(7 DOWNTO 0);  -- second byte readout

      COMMAND0 : IN std_logic_vector(34 DOWNTO 0);
      COMMAND1 : IN std_logic_vector(34 DOWNTO 0);
      COMMAND2 : IN std_logic_vector(34 DOWNTO 0);
      COMMAND3 : IN std_logic_vector(34 DOWNTO 0);
      COMMAND4 : IN std_logic_vector(34 DOWNTO 0);
      COMMAND5 : IN std_logic_vector(34 DOWNTO 0);

      DATA0 : OUT std_logic_vector(15 DOWNTO 0);
      DATA1 : OUT std_logic_vector(15 DOWNTO 0);
      DATA2 : OUT std_logic_vector(15 DOWNTO 0);
      DATA3 : OUT std_logic_vector(15 DOWNTO 0);
      DATA4 : OUT std_logic_vector(15 DOWNTO 0);
      DATA5 : OUT std_logic_vector(15 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT ila_0
    PORT (
      clk    : IN std_logic;
      probe0 : IN std_logic_vector(5 DOWNTO 0)
    );
  END COMPONENT;
  ---------------------------------------------<reset & clks
  SIGNAL reset       : std_logic;
  SIGNAL sys_clk     : std_logic;
  SIGNAL clk_60MHz   : std_logic;
  SIGNAL clk_160MHz  : std_logic;
  SIGNAL clk_10MHz   : std_logic;
  SIGNAL clk_125MHz  : std_logic;
  SIGNAL clk_sgmii_i : std_logic;

  SIGNAL sDelayRST   : std_logic;
  SIGNAL sDelayRST_n : std_logic;

  SIGNAL clk_in_sel    : std_logic;
  SIGNAL clk_160MHz_sw : std_logic;
  SIGNAL clk_10MHz_sw  : std_logic;
  SIGNAL USER_CLK_IN   : std_logic;
  --------------------------------------------->reset & clks

  ----------------------------------------------<gig_eth
  SIGNAL gig_eth_tx_tdata   : std_logic_vector(7 downto 0);
  SIGNAL gig_eth_tx_tvalid  : std_logic;
  SIGNAL gig_eth_tx_tready  : std_logic;
  SIGNAL gig_eth_rx_tdata   : std_logic_vector(7 downto 0);
  SIGNAL gig_eth_rx_tvalid  : std_logic;
  SIGNAL gig_eth_rx_tready  : std_logic;

  SIGNAL gig_eth_tcp_use_fifo     : std_logic;
  SIGNAL gig_eth_tx_fifo_wrclk    : std_logic;
  SIGNAL gig_eth_tx_fifo_q        : std_logic_vector(31 downto 0);
  SIGNAL gig_eth_tx_fifo_wren     : std_logic;
  SIGNAL gig_eth_tx_fifo_full     : std_logic;
  SIGNAL gig_eth_rx_fifo_rdclk    : std_logic;
  SIGNAL gig_eth_rx_fifo_q        : std_logic_vector(31 downto 0);
  SIGNAL gig_eth_rx_fifo_rden     : std_logic;
  SIGNAL gig_eth_rx_fifo_empty    : std_logic;
  ---------------------------------------------->gig_eth

  ----------------------------------------------<control interface
  SIGNAL control_fifo_q        : std_logic_vector(35 downto 0);
  SIGNAL control_fifo_empty    : std_logic;
  SIGNAL control_fifo_rdreq    : std_logic;
  SIGNAL control_fifo_rdclk    : std_logic;
  SIGNAL cmd_fifo_q            : std_logic_vector(35 downto 0);
  SIGNAL cmd_fifo_empty        : std_logic;
  SIGNAL cmd_fifo_rdreq        : std_logic;
  SIGNAL config_reg            : std_logic_vector(511 downto 0);
  SIGNAL pulse_reg             : std_logic_vector(15 downto 0);
  SIGNAL status_reg            : std_logic_vector(175 downto 0);
  SIGNAL user_data_fifo_dout   : std_logic_vector(31 downto 0);
  SIGNAL user_data_fifo_empty  : std_logic;
  SIGNAL user_data_fifo_rden   : std_logic;
  SIGNAL user_data_fifo_rdclk  : std_logic;
  ---------------------------------------------->control interface

  ----------------------------------------------<i2c interface
  SIGNAL i2c_ena            : std_logic;
  SIGNAL i2c_addr           : std_logic_vector(6 DOWNTO 0);
  SIGNAL i2c_rw             : std_logic;
  SIGNAL i2c_sda_r          : std_logic;
  SIGNAL i2c_sda_w          : std_logic;
  SIGNAL i2c_scl            : std_logic;
  SIGNAL i2c_mode           : std_logic_vector(1 DOWNTO 0);
  SIGNAL i2c_wr_addr        : std_logic_vector(7 DOWNTO 0);
  SIGNAL i2c_wr_data0       : std_logic_vector(7 DOWNTO 0);
  SIGNAL i2c_wr_data1       : std_logic_vector(7 DOWNTO 0);
  SIGNAL i2c_rd_data0       : std_logic_vector(7 DOWNTO 0);
  SIGNAL i2c_rd_data1       : std_logic_vector(7 DOWNTO 0);
  SIGNAL i2c_command        : std_logic_vector((34+35*5) DOWNTO 0);
  SIGNAL i2c_data0          : std_logic_vector(15 DOWNTO 0);
  SIGNAL i2c_data1          : std_logic_vector(15 DOWNTO 0);
  SIGNAL i2c_data2          : std_logic_vector(15 DOWNTO 0);
  SIGNAL i2c_data3          : std_logic_vector(15 DOWNTO 0);
  SIGNAL i2c_data4          : std_logic_vector(15 DOWNTO 0);
  SIGNAL i2c_data5          : std_logic_vector(15 DOWNTO 0);
  ---------------------------------------------->i2c interface

  ----------------------------------------------<Jtag control
  SIGNAL sMemWe         : std_logic;
  SIGNAL sMemAddr       : std_logic_vector(31 DOWNTO 0);
  SIGNAL sMemDin        : std_logic_vector(31 DOWNTO 0);
  SIGNAL sMemDout       : std_logic_vector(31 DOWNTO 0);
  SIGNAL sJtagStart     : std_logic;
  SIGNAL sJtagDone      : std_logic;
  SIGNAL sJtagDivide    : std_logic_vector(3 DOWNTO 0);
  SIGNAL sDoRSTB        : std_logic;
  SIGNAL L_RSTB         : std_logic;
  SIGNAL L_JTAG_TMS     : std_logic;
  SIGNAL L_JTAG_TDI     : std_logic;
  SIGNAL L_JTAG_TCK     : std_logic;
  SIGNAL L_JTAG_TDO     : std_logic;
  ---------------------------------------------->Jtag control

  ----------------------------------------------<deserialize
  SIGNAL sLoadDelay      : std_logic;
  SIGNAL sDelayConfig    : std_logic_vector (5 DOWNTO 0);
  SIGNAL sSensorOut      : std_logic_vector (1 DOWNTO 0);
  SIGNAL sSensorPar      : std_logic_vector (31 DOWNTO 0);
  SIGNAL sSerdesErr      : std_logic;
  SIGNAL iTriggerDelay   : integer RANGE 0 TO 31    := 0;
  SIGNAL sSensorParMod   : std_logic_vector (31 DOWNTO 0);
  SIGNAL IsHEADER        : std_logic;
  SIGNAL IsSTATED        : std_logic;
  SIGNAL IsTRAILER       : std_logic;
  SIGNAL IsCounter_L     : std_logic;
  SIGNAL IsCounter_H     : std_logic;
  ---------------------------------------------->deserialize

  ----------------------------------------------<start control
  SIGNAL sChipStart      : std_logic;
  SIGNAL sSerReset       : std_logic;
  SIGNAL sCtrStart       : std_logic;
  SIGNAL sFifoWrEn       : std_logic;

  TYPE chStState_type IS (CS0, CS1, CS2);
  SIGNAL chStState : chStState_type;
  ---------------------------------------------->start control

  SIGNAL fifo_full_check : std_logic;
  SIGNAL frame_counter   : unsigned(61 DOWNTO 0);
  SIGNAL din_fifo        : std_logic_vector (31 DOWNTO 0);
  SIGNAL sign_tag        : std_logic_vector (1 DOWNTO 0);
  SIGNAL start_sign : std_logic;
  SIGNAL stop_sign : std_logic;
-------------------------------------------------------------------------------
-- ****************************************************************************
-- Start of the implementation ------------------------------------------------
-- ****************************************************************************
-------------------------------------------------------------------------------
BEGIN

-------------------------------------------------------------------------------
-- Generate all the clocks needed for the design
-------------------------------------------------------------------------------
  -- global_clock_reset instance
  clockg_inst : global_clock_reset
    PORT MAP (
      SYS_CLK_P  => SYS_CLK_P,
      SYS_CLK_N  => SYS_CLK_N,
      FORCE_RST  => CPU_RESET,
      -- output
      GLOBAL_RST => reset,      --active High
      SYS_CLK    => sys_clk,    --200MHz
      CLK_OUT1   => clk_160MHz,
      CLK_OUT2   => clk_10MHz,
      CLK_OUT3   => clk_60MHz,
      CLK_OUT4   => OPEN
      );
   -- clk switch between different input
   BUFG_10M_inst : BUFG
   port map (
      O => USER_CLK_IN, -- 1-bit output: Clock output
      I => USER_CLK  -- 1-bit input: Clock input
   );

   clk_switch_inst : clk_switch
     PORT MAP (
       -- Clock in ports
       clk_in1 => clk_10MHz,
       clk_in2 => USER_CLK_IN,
       clk_in_sel => clk_in_sel,
       -- Clock out ports
       clk_out1 => clk_160MHz_sw,
       clk_out2 => clk_10MHz_sw,
       -- Status and control signals
       reset => reset,
       locked => OPEN
       );
   CLK_10M_OUT <= clk_10MHz_sw;
  --generate clk_125MHz for SGMIICLK
  IBUFDS_GTE2_inst : IBUFDS_GTE2
    generic map (
      CLKCM_CFG    => TRUE,    -- Refer to Transceiver User Guide
      CLKRCV_TRST  => TRUE,  -- Refer to Transceiver User Guide
      CLKSWING_CFG => "11"  -- Refer to Transceiver User Guide
      )
    port map (
      O     => clk_sgmii_i,         -- 1-bit output: Refer to Transceiver User Guide
      ODIV2 => OPEN, -- 1-bit output: Refer to Transceiver User Guide
      CEB   => '0',     -- 1-bit input: Refer to Transceiver User Guide
      I     => SGMIICLK_Q0_P,         -- 1-bit input: Refer to Transceiver User Guide
      IB    => SGMIICLK_Q0_N        -- 1-bit input: Refer to Transceiver User Guide
      );
  BUFG_inst : BUFG
    port map (
      O => clk_125MHz, -- 1-bit output: Clock output
      I => clk_sgmii_i  -- 1-bit input: Clock input
      );

-------------------------------------------------------------------------------
-- Generate GBE module for the design
-------------------------------------------------------------------------------
  -- gig_eth instance
  gig_eth_inst : gig_eth
    PORT MAP  (
      -- asynchronous reset
      glbl_rst           => reset,
      -- clocks
      gtx_clk            => clk_125MHz,
      ref_clk            => sys_clk,
      -- PHY interface
      phy_resetn         => PHY_RESET_N,
      -- RGMII Interface
      ------------------
      rgmii_txd          => RGMII_TXD,
      rgmii_tx_ctl       => RGMII_TX_CTL,
      rgmii_txc          => RGMII_TXC,
      rgmii_rxd          => RGMII_RXD,
      rgmii_rx_ctl       => RGMII_RX_CTL,
      rgmii_rxc          => RGMII_RXC,
      -- MDIO Interface
      -----------------
      mdio               => MDIO,
      mdc                => MDC,
      -- TCP
      MAC_ADDR                 => x"000a3502a758",
      IPv4_ADDR                => x"c0a80203",
      IPv6_ADDR                =>(OTHERS => '0'),
      SUBNET_MASK              => x"ffffff00",
      GATEWAY_IP_ADDR          => x"c0a80201",
      TCP_CONNECTION_RESET     => '0',
      TX_TDATA                 => gig_eth_tx_tdata,
      TX_TVALID                => gig_eth_tx_tvalid,
      TX_TREADY                => gig_eth_tx_tready,
      RX_TDATA                 => gig_eth_rx_tdata,
      RX_TVALID                => gig_eth_rx_tvalid,
      RX_TREADY                => gig_eth_rx_tready,
      -- FIFO
      TCP_USE_FIFO             => gig_eth_tcp_use_fifo,
      TX_FIFO_WRCLK            => gig_eth_tx_fifo_wrclk,
      TX_FIFO_Q                => gig_eth_tx_fifo_q,
      TX_FIFO_WREN             => gig_eth_tx_fifo_wren,
      TX_FIFO_FULL             => gig_eth_tx_fifo_full,
      RX_FIFO_RDCLK            => gig_eth_rx_fifo_rdclk,
      RX_FIFO_Q                => gig_eth_rx_fifo_q,
      RX_FIFO_RDEN             => gig_eth_rx_fifo_rden,
      RX_FIFO_EMPTY            => gig_eth_rx_fifo_empty
      );
  -- loopback
  gig_eth_tx_tdata      <= gig_eth_rx_tdata;
  gig_eth_tx_tvalid     <= gig_eth_rx_tvalid;
  gig_eth_rx_tready     <= gig_eth_tx_tready;
  -- tcp fifo config
  gig_eth_tcp_use_fifo  <= '1';
  gig_eth_tx_fifo_wrclk <= clk_125MHz;
  gig_eth_tx_fifo_q     <= control_fifo_q(31 downto 0);
  gig_eth_tx_fifo_wren  <= (NOT control_fifo_empty) and (NOT gig_eth_tx_fifo_full);
  gig_eth_rx_fifo_rdclk <= clk_60MHz;
  gig_eth_rx_fifo_rden  <= cmd_fifo_rdreq;

-------------------------------------------------------------------------------
-- Generate control interface module for the design
-------------------------------------------------------------------------------
  -- control_interface instance
  control_interface_inst : control_interface
    PORT MAP  (
      RESET           => reset,
      CLK             => clk_60MHz,
      -- From FPGA to PC
      FIFO_Q          => control_fifo_q,  -- interface fifo data output port
      FIFO_EMPTY      => control_fifo_empty,    -- interface fifo "emtpy" signal
      FIFO_RDREQ      => control_fifo_rdreq,    -- interface fifo read request
      FIFO_RDCLK      => control_fifo_rdclk,    -- interface fifo read clock
      -- From PC to FPGA, FWFT
      CMD_FIFO_Q      => cmd_fifo_q,  -- interface command fifo data out port
      CMD_FIFO_EMPTY  => cmd_fifo_empty,    -- interface command fifo "emtpy" signal
      CMD_FIFO_RDREQ  => cmd_fifo_rdreq,    -- interface command fifo read request
      -- Digital I/O
      CONFIG_REG      => config_reg, -- thirtytwo 16bit registers
      PULSE_REG       => pulse_reg,  -- 16bit pulse register
      STATUS_REG      => status_reg, -- eleven 16bit registers
      -- Memory interface
      MEM_WE          => sMemWe,
      MEM_ADDR        => sMemAddr,
      MEM_DIN         => sMemDin,
      MEM_DOUT        => sMemDout,
      -- Data FIFO interface, FWFT
      DATA_FIFO_Q     => user_data_fifo_dout,
      DATA_FIFO_EMPTY => user_data_fifo_empty,
      DATA_FIFO_RDREQ => user_data_fifo_rden,
      DATA_FIFO_RDCLK => user_data_fifo_rdclk
      );
  -- port connection
  control_fifo_rdreq   <= gig_eth_tx_fifo_wren;
  control_fifo_rdclk   <= gig_eth_tx_fifo_wrclk;
  cmd_fifo_q           <= "0000" & gig_eth_rx_fifo_q;
  cmd_fifo_empty       <= gig_eth_rx_fifo_empty;
  -- pulse_reg, config_reg, status_reg
  -- i2c_mode      <= config_reg(1 downto 0);      -- config_reg 0*16
  -- i2c_rw        <= config_reg(2);
  -- i2c_addr      <= config_reg(14 downto 8);
  -- i2c_wr_addr   <= config_reg(23 downto 16);    -- config_reg 1*16
  -- i2c_wr_data0  <= config_reg(31 downto 24);
  -- i2c_wr_data1  <= config_reg(39 downto 32);    -- config_reg 2*16
     
  i2c_command(208 downto 207)      <= config_reg(1 downto 0);      -- config_reg 0*16
  i2c_command(206)                 <= config_reg(2);
  i2c_command(205 downto 199)      <= config_reg(14 downto 8);
  i2c_command(198 downto 191)      <= config_reg(23 downto 16);    -- config_reg 1*16
  i2c_command(190 downto 183)      <= config_reg(31 downto 24);
  i2c_command(182 downto 175)      <= config_reg(39 downto 32);    -- config_reg 2*16
  sJtagDivide   <= config_reg(51 downto 48);                       -- config_reg 3*16
  sDelayConfig  <= config_reg(69 downto 64);                       -- config_reg 4*16                                               
  iTriggerDelay <= to_integer(unsigned(config_reg(84 DOWNTO 80))); -- config_reg 5*16
  clk_in_sel    <= config_reg(96);                                 -- config_reg 6*16
  i2c_command((4*35+34) downto 0)   <= config_reg(286 downto 112); -- config_reg 7*16

  -- status_reg(7 downto 0)   <= i2c_rd_data0;                   --status_reg 0*16
  -- status_reg(15 downto 8)  <= i2c_rd_data1;
  status_reg(15 downto 0)   <= i2c_data5(7 downto 0) & i2c_data5(15 downto 8); --status_reg 0*16
  status_reg(16)           <= sJtagDone;                                       --status_reg 1*16
  status_reg(17)           <= sSerdesErr;

  sLoadDelay  <= pulse_reg(0);                        -- pulse reg 0
  sCtrStart   <= pulse_reg(1);                        -- pulse reg 1
  -- jtag control signal
  sDoRSTB     <= pulse_reg(2);                        -- pulse reg 2
  sJtagStart  <= pulse_reg(3);                        -- pulse reg 3
  -- i2c_ena     <= pulse_reg(4);                        -- pulse reg 4
  i2c_command(209) <= pulse_reg(4);                   -- pulse reg 4
-------------------------------------------------------------------------------
-- Generate I2C interface module for the design
-------------------------------------------------------------------------------
  -- i2c_tic control interface
  i2c_tic_inst : i2c_tic
    PORT MAP (
      CLK      => clk_60MHz,          --  system clock 50Mhz
      RESET    => reset,           --  active high reset
      START    => i2c_ena,          -- the rising edge trigger a start
      MODE     => i2c_mode,           -- '0' is 2 bytes read or write, '1' is 3 bytes read or write
      SL_WR    => i2c_rw,           -- '0' is write, '1' is read
      SL_ADDR  => i2c_addr, -- slave addr
      WR_ADDR  => i2c_wr_addr,  -- chip internal addr for read and write
      WR_DATA0 => i2c_wr_data0,  -- 1 byte data for write
      WR_DATA1 => i2c_wr_data1,  -- 2 byte data for write
      RD_DATA0 => i2c_rd_data0, -- first byte readout
      RD_DATA1 => i2c_rd_data1,  -- second byte readout

      COMMAND0 => i2c_command((34+35*0) DOWNTO (0+35*0)),
      COMMAND1 => i2c_command((34+35*1) DOWNTO (0+35*1)),
      COMMAND2 => i2c_command((34+35*2) DOWNTO (0+35*2)),
      COMMAND3 => i2c_command((34+35*3) DOWNTO (0+35*3)),
      COMMAND4 => i2c_command((34+35*4) DOWNTO (0+35*4)),
      COMMAND5 => i2c_command((34+35*5) DOWNTO (0+35*5)),

      DATA0    => i2c_data0,
      DATA1    => i2c_data1,
      DATA2    => i2c_data2,
      DATA3    => i2c_data3,
      DATA4    => i2c_data4,
      DATA5    => i2c_data5
      );
  -- i2c_master instance
  i2c_master_inst : i2c_wr_bytes
    PORT MAP  (
      CLK      => clk_60MHz,          --  system clock 50Mhz
      RESET    => reset,           --  active high reset
      START    => i2c_ena,          -- the rising edge trigger a start, generate by pulse_reg
      MODE     => i2c_mode,           -- '0' is 2 bytes read or write, '1' is 3 bytes read or write
      SL_WR    => i2c_rw,           -- '0' is write, '1' is read
      SL_ADDR  => i2c_addr, -- slave addr
      WR_ADDR  => i2c_wr_addr,  -- chip internal addr for read and write
      WR_DATA0 => i2c_wr_data0,  -- 1 byte data for write
      WR_DATA1 => i2c_wr_data1,  -- 2 byte data for write
      RD_DATA0 => i2c_rd_data0, -- first byte readout
      RD_DATA1 => i2c_rd_data1,  -- second byte readout
      BUSY     => OPEN,           -- indicates transaction in progress
      SDA_in   => i2c_sda_r,          -- serial data input of i2c bus
      SDA_out  => i2c_sda_w,           -- serial data output of i2c bus
      SDA_T    => OPEN,         -- serial data direction of i2c bus
      SCL      => i2c_scl           -- serial clock output of i2c bus
      );
  -- single-end to differential
  IBUFDS_inst : IBUFDS
    generic map (
      DIFF_TERM => TRUE, -- Differential Termination
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "LVDS_25")
    port map (
      O => i2c_sda_r,  -- Buffer output
      I => SDA_R_P,  -- Diff_p buffer input (connect directly to top-level port)
      IB => SDA_R_N -- Diff_n buffer input (connect directly to top-level port)
      );
  OBUFDS_inst_0 : OBUFDS
    generic map (
      IOSTANDARD => "LVDS_25", -- Specify the output I/O standard
      SLEW => "SLOW")          -- Specify the output slew rate
    port map (
      O => SCL_P,     -- Diff_p output (connect directly to top-level port)
      OB => SCL_N,   -- Diff_n output (connect directly to top-level port)
      I => i2c_scl      -- Buffer input
      );
  OBUFDS_inst_1 : OBUFDS
    generic map (
      IOSTANDARD => "LVDS_25", -- Specify the output I/O standard
      SLEW => "SLOW")          -- Specify the output slew rate
    port map (
      O => SDA_W_P,     -- Diff_p output (connect directly to top-level port)
      OB => SDA_W_N,   -- Diff_n output (connect directly to top-level port)
      I => i2c_sda_w      -- Buffer input
      );

-------------------------------------------------------------------------------
-- JTAG module for MIMOSA Control
-------------------------------------------------------------------------------
  -- L_RSTB,L_JTAG_TMS,L_JTAG_TDI,L_JTAG_TCK output
   L_RSTB_ladder : OBUFDS
     GENERIC MAP (
       IOSTANDARD => "LVDS_25")
     PORT MAP (
       O  => L_RSTB_P,
       OB => L_RSTB_N,
       I  => L_RSTB
       );
   L_JTAG_TMS_ladder : OBUFDS
     GENERIC MAP (
       IOSTANDARD => "LVDS_25")
     PORT MAP (
       O  => L_JTAG_TMS_P,
       OB => L_JTAG_TMS_N,
       I  => L_JTAG_TMS
       );
   L_JTAG_TDI_ladder : OBUFDS
     GENERIC MAP (
       IOSTANDARD => "LVDS_25")
     PORT MAP (
       O  => L_JTAG_TDI_P,
       OB => L_JTAG_TDI_N,
       I  => L_JTAG_TDI
       );
   L_JTAG_TCK_ladder : OBUFDS
     GENERIC MAP (
       IOSTANDARD => "LVDS_25")
     PORT MAP (
       O  => L_JTAG_TCK_P,
       OB => L_JTAG_TCK_N,
       I  => L_JTAG_TCK
       );
   -- L_JTAG_TDO input
   L_JTAG_TDO_ladder : IBUFDS
     GENERIC MAP (
       IOSTANDARD => "LVDS_25")
     PORT MAP (
       O  => L_JTAG_TDO,
       I  => L_JTAG_TDO_P,
       IB => L_JTAG_TDO_N
       );
  -- jtag instance
  jtag_insti : jtag
    PORT MAP (
      CLK        => clk_60MHz,  --  system clock 50Mhz
      RST        => reset,      --  active high
      --control interface
      START      => sJtagStart,
      WEN        => sMemWe,
      READ_DATA  => sMemDout,
      WRITE_DATA => sMemDin,
      ADDRESS    => sMemAddr(11 DOWNTO 0),
      DONE       => sJtagDone,
      DIVIDE     => sJtagDivide,
      DO_RSTB    => sDoRSTB,
      -- JTAG interface
      TMS_OUT    => L_JTAG_TMS,
      TDI_OUT    => L_JTAG_TDI,
      TCK_OUT    => L_JTAG_TCK,
      TDO_IN     => L_JTAG_TDO,
      RSTB_OUT   => L_RSTB
      );

-------------------------------------------------------------------------------
-- deserialize & PXL data format
-------------------------------------------------------------------------------
  -- 160MHz clock to ladder
  clk_buff : OBUFTDS
    GENERIC MAP (
      IOSTANDARD => "LVDS_25")
    PORT MAP (
      O  => L1_PM_CLK_P,
      OB => L1_PM_CLK_N,
      I  => clk_160MHz_sw,
      T  => '0'               -- active low enable
      );
  -- sensor outputs
  in_L_S_O : IBUFDS
    GENERIC MAP (
      DIFF_TERM => TRUE, -- Differential Termination
      IBUF_LOW_PWR => FALSE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "LVDS_25")
    PORT MAP (
      O  => sSensorOut(0),
      I  => L_SENSOR_OUT_P(0),
      IB => L_SENSOR_OUT_N(0)
      );
  in_L_S_1 : IBUFDS
    GENERIC MAP (
      DIFF_TERM => TRUE, -- Differential Termination
      IBUF_LOW_PWR => FALSE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "LVDS_25")
    PORT MAP (
      O  => sSensorOut(1),
      I  => L_SENSOR_OUT_P(1),
      IB => L_SENSOR_OUT_N(1)
      );
  -- IODELAY control
  delayctrl_inst : IDELAYCTRL
  PORT MAP (
    RDY    => sDelayRST_n,  -- inverted to have active high when not ready
    REFCLK => sys_clk,
    RST    => reset
    );

  sDelayRST <= (NOT sDelayRST_n) OR reset;

  -- First deserialize sensor outputs and combine into 32bit words
  sdes_insti : sensor_deserializer
    GENERIC MAP (
      FRAME_SIZE     => FRAME_SIZE,
      HEADER_PATTERN => HEADER_PATTERN
      )
    PORT MAP (
      RST           => sDelayRST,
      CTRLCLK       => clk_60MHz,
      DATACLK       => clk_160MHz_sw,
      LATCHCLK      => clk_10MHz_sw,
      SER_RESET     => sSerReset,
      LOAD_CONFIG   => sLoadDelay,
      DELAY_CONFIG0 => sDelayConfig(5 DOWNTO 0),
      DELAY_CONFIG1 => sDelayConfig(5 DOWNTO 0),
      SIG_IN        => sSensorOut(1 DOWNTO 0),
      SIG_PAR       => sSensorPar(31 DOWNTO 0),
      ERR           => sSerdesErr
      );

  -- Next, modify 32bit words to adhere to PXL data format
  data_mod_i : data_mod
    GENERIC MAP (
      HEADER_PATTERN  => HEADER_PATTERN,
      TRAILER_PATTERN => TRAILER_PATTERN
      )
    PORT MAP (
      CLK           => clk_10MHz_sw,
      RESET         => sSerdesErr,
      DATA_IN       => sSensorPar(31 DOWNTO 0),
      CHIP_ID       => std_logic_vector(to_unsigned(1, 6)),
      TRIGGER_DELAY => iTriggerDelay,
      TRAILER_ERR   => OPEN,
      DATA_OUT      => sSensorParMod(31 DOWNTO 0),
      IsHEADER      => IsHEADER,
      IsSTATED      => IsSTATED,
      IsTRAILER     => IsTRAILER,
      IsCounter_L   => IsCounter_L,
      IsCounter_H   => IsCounter_H
      );

-------------------------------------------------------------------------------
-- start signal generate and fifo data write control
-------------------------------------------------------------------------------
  -- Start output
  start_ladder : OBUFDS
    GENERIC MAP (
      IOSTANDARD => "LVDS_25")
    PORT MAP (
      O  => L_START_P,
      OB => L_START_N,
      I  => sChipStart
      );
  -- generate a 750ns CHIP_START signal
  chipStartTimer : PROCESS (clk_160MHz_sw) IS
    VARIABLE startCtr      : integer RANGE 0 TO 16000        := 0;
  BEGIN
    IF rising_edge(clk_160MHz_sw) THEN
      IF reset = '1' THEN          -- synchronous reset (active high)
        sChipStart             <= '0';
        sSerReset              <= '1';
        startCtr               := 0;
        chStState              <= CS0;
        sFifoWrEn              <= '0';
      ELSE
        -- defaults:
        sChipStart             <= '0';
        sSerReset              <= '0';

        CASE chStState IS
          WHEN CS0 =>
            -- trigger CHIP_START from Pulse register
            IF (sCtrStart = '1') THEN
              startCtr := 0;
              chStState  <= CS1;
            END IF;
          WHEN CS1 =>
            -- Pixel 0 is read out 324 clk160s after the leading edge of CHIP_START.
            -- the ChipStart pulse is 120 clk160s long
            startCtr               := startCtr + 1;
            sChipStart             <= '1';
            sSerReset              <= '1';
            sFifoWrEn <= '0';
            IF startCtr = 120 THEN      -- 750ns (500ns < ChipSTART < 1us)
              chStState <= CS2;
--              sFifoWrEn <= '1';
            END IF;
          WHEN CS2 =>
            -- data store after 100us
            startCtr               := startCtr + 1;
            sChipStart             <= '0';
            sSerReset              <= '0';
            IF startCtr = 16000 THEN      -- 750ns (500ns < ChipSTART < 1us)
                chStState <= CS0;
                sFifoWrEn <= '1';
            END IF;
          WHEN OTHERS =>
            chStState <= CS0;
        END CASE;
      END IF;
    END IF;
  END PROCESS chipStartTimer;

-------------------------------------------------------------------------------
-- FIFO block for data buffer
-------------------------------------------------------------------------------
 PROCESS (clk_160MHz_sw) IS
 BEGIN
  IF rising_edge(clk_160MHz_sw) THEN
    IF START_IN = '1' THEN          -- synchronous reset (active high)
      start_sign <= '1';
    ELSIF IsCounter_L = '1' THEN
      start_sign <= '0';
    END IF;
  END IF;
 END PROCESS;

 PROCESS (clk_160MHz_sw) IS
  BEGIN
   IF rising_edge(clk_160MHz_sw) THEN
     IF STOP_IN = '1' THEN          -- synchronous reset (active high)
       stop_sign <= '1';
     ELSIF IsCounter_L = '1' THEN
       stop_sign <= '0';
     END IF;
   END IF;
  END PROCESS;

 PROCESS (clk_10MHz_sw) IS
 BEGIN
   IF rising_edge(clk_10MHz_sw) THEN
     IF sFifoWrEn = '1' THEN          -- synchronous reset (active high)
       IF IsHEADER = '1' THEN
         frame_counter <= frame_counter + 1;
         sign_tag <= start_sign & stop_sign;
       END IF;
     ELSE
       frame_counter <= (others => '0');
     END IF;
   END IF;
 END PROCESS;

 din_fifo <= (sign_tag & i2c_data3(9 downto 0) & std_logic_vector(frame_counter(19 downto 0))) when IsCounter_L = '1' else
             (i2c_data0(15 downto 6) & i2c_data1(15 downto 6) & i2c_data2(13 downto 2))        when IsCounter_H = '1' else
             sSensorParMod(7 downto 0)&sSensorParMod(15 downto 8)&sSensorParMod(23 downto 16)&sSensorParMod(31 downto 24);
  -- fifo instance
  fifo32to32_inst : fifo32to32
    PORT MAP (
      rst    => sChipStart,
      wr_clk => clk_10MHz_sw,
      rd_clk => user_data_fifo_rdclk,
      din    => din_fifo,
      wr_en  => sFifoWrEn and (IsHEADER or IsSTATED or IsTRAILER or IsCounter_L or IsCounter_H),
      rd_en  => user_data_fifo_rden,
      dout   => user_data_fifo_dout,
      full   => fifo_full_check,
      empty  => OPEN,
      prog_empty => user_data_fifo_empty
    );

-------------------------------------------------------------------------------
-- ila block for debug
-------------------------------------------------------------------------------

  dbg_cores : IF bIncludeChipscope GENERATE
    ila_0_inst : ila_0
      PORT MAP (
        clk    => clk_60MHz,
        probe0 => i2c_sda_w & i2c_sda_r & i2c_scl & i2c_mode & i2c_ena
      );
  END GENERATE dbg_cores;

END behavior;
