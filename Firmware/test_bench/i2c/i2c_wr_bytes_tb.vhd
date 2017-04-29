-------------------------------------------------------------------------------
-- Title      : I2C Master Testbench
-- Project    : MIMOSA readout
-------------------------------------------------------------------------------
-- File       : i2c_wr_bytes_tb.vhd
-- Author     : Dong Wang
-- Company    : Cerntral China Normal University
-- Created    : 2016-11-30
-- Last update:
-- Platform   : Linux, Xilinx Vivado 2015.4.2
-- Target     : KC705
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: I2C master testbench
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author        Description
-- 2016-11-30  1.0      Dong Wang     Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY i2c_wr_bytes_tb IS
END i2c_wr_bytes_tb;

ARCHITECTURE behavior OF i2c_wr_bytes_tb IS
  -- Component Declaration for the Unit Under Test (UUT)
  COMPONENT i2c_wr_bytes
  PORT (
    CLK      : IN  std_logic;           --  system clock 50Mhz
    RESET    : IN  std_logic;           --  active high reset
    START    : IN  std_logic;           -- the rising edge trigger a start, generate by config_reg
    MODE     : IN  std_logic;           -- '0' is 2 bytes read or write, '1' is 3 bytes read or write
    SL_WR    : IN  std_logic;           -- '0' is write, '1' is read
    SL_ADDR  : IN  std_logic_vector(6 DOWNTO 0);  -- slave addr
    WR_ADDR  : IN  std_logic_vector(7 DOWNTO 0);  -- chip internal addr for read and write
    WR_DATA  : IN  std_logic_vector(7 DOWNTO 0);  -- 1 byte data for write
    RD_DATA0 : OUT std_logic_vector(7 DOWNTO 0);  -- first byte readout
    RD_DATA1 : OUT std_logic_vector(7 DOWNTO 0);  -- second byte readout
    BUSY     : OUT std_logic;           -- indicates transaction in progress
    SDA_in   : IN  std_logic;           -- serial data input of i2c bus
    SDA_out  : OUT std_logic;           -- serial data output of i2c bus
    SDA_T    : OUT std_logic;           -- serial data direction of i2c bus
    SCL      : OUT std_logic            -- serial clock output of i2c bus
    );
  END COMPONENT;

  --Inputs
  SIGNAL CLK       : std_logic                    := '0';
  SIGNAL RESET     : std_logic                    := '0';
  SIGNAL START     : std_logic                    := '0';
  SIGNAL MODE      : std_logic                    := '0';
  SIGNAL SL_WR     : std_logic                    := '0';
  SIGNAL SL_ADDR   : std_logic_vector(6 DOWNTO 0) := (OTHERS => '0');
  SIGNAL WR_ADDR   : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL WR_DATA   : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL SDA_in    : std_logic                    := '0';

  --Outputs
  SIGNAL BUSY      : std_logic;
  SIGNAL SDA_out   : std_logic;
  SIGNAL SDA_T     : std_logic;
  SIGNAL SCL       : std_logic;
  SIGNAL RD_DATA0  : std_logic_vector(7 DOWNTO 0);
  SIGNAL RD_DATA1  : std_logic_vector(7 DOWNTO 0);



  -- Clock period definitions
  CONSTANT CLK_period : time := 16.7 ns;

BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut : i2c_wr_bytes
    PORT MAP (
      CLK      => CLK,
      RESET    => RESET,
      START    => START,
      MODE     => MODE,
      SL_WR    => SL_WR,
      SL_ADDR  => SL_ADDR,
      WR_ADDR  => WR_ADDR,
      WR_DATA  => WR_DATA,
      RD_DATA0 => RD_DATA0,
      RD_DATA1 => RD_DATA1,
      BUSY     => BUSY,
      SDA_in   => SDA_in,
      SDA_out  => SDA_out,
      SDA_T    => SDA_T,
      SCL      => SCL
      );

  -- Clock process definitions
  CLK_process : PROCESS
  BEGIN
    CLK <= '0';
    WAIT FOR CLK_period/2;
    CLK <= '1';
    WAIT FOR CLK_period/2;
  END PROCESS;


  -- Stimulus process
  stim_proc : PROCESS
  BEGIN
    -- initial values:
    SL_ADDR    <= "0100010";
    WR_ADDR    <= "00000010";
    WR_DATA    <= "00000000";
    START   <= '0';
    MODE    <= '0';
    SL_WR   <= '1';
    SDA_in  <= '1';

    -- hold reset state for 100 ns.
    WAIT FOR 1000 ns;
    RESET <= '1';
    WAIT FOR 100 ns;
    RESET <= '0';
    
    -- stimulate START
    WAIT FOR 1000 ns;
    START   <= '1';
    WAIT FOR 50 ns;
    START   <= '0';
    
    WAIT;
  END PROCESS;

END;
