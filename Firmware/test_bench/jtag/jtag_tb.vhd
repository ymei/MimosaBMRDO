-- $Id: jtag_tb.vhd 386 2013-09-25 18:10:28Z jschamba $
-------------------------------------------------------------------------------
-- Title      : JTAG Interface Testbench
-- Project    : HFT PXL
-------------------------------------------------------------------------------
-- File       : jtag_tb.vhd
-- Author     : Joachim Schambach
-- Company    : University of Texas 
-- Created    : 2013-02-08
-- Last update: 2013-09-25
-- Platform   : Windows, Xilinx ISE 13.4, ISIM
-- Target     : Virtex-6 (XC6VLX240T-FF1759)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Testbench for jtag.vhd
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-02-08  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY jtag_tb IS
END jtag_tb;

ARCHITECTURE behavior OF jtag_tb IS

  -- Component Declaration for the Unit Under Test (UUT)
  
  COMPONENT jtag
    PORT (
      CLK        : IN  std_logic;
      RST        : IN  std_logic;
      START      : IN  std_logic;
      WEN        : IN  std_logic;
      READ_DATA  : OUT std_logic_vector(31 DOWNTO 0);
      WRITE_DATA : IN  std_logic_vector(31 DOWNTO 0);
      ADDRESS    : IN  std_logic_vector(11 DOWNTO 0);
      DONE       : OUT std_logic;
      DIVIDE     : IN  std_logic_vector(3 DOWNTO 0);
      DO_RSTB    : IN  std_logic;
      TMS_OUT    : OUT std_logic;
      TDI_OUT    : OUT std_logic;
      TCK_OUT    : OUT std_logic;
      TDO_IN     : IN  std_logic;
      RSTB_OUT   : OUT std_logic
      );
  END COMPONENT;


  --Inputs
  SIGNAL CLK        : std_logic                     := '0';
  SIGNAL RST        : std_logic                     := '0';
  SIGNAL START      : std_logic                     := '0';
  SIGNAL DO_RSTB : std_logic := '0';
  SIGNAL WEN        : std_logic                     := '0';
  SIGNAL WRITE_DATA : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL ADDRESS    : std_logic_vector(11 DOWNTO 0) := (OTHERS => '0');
  SIGNAL DIVIDE     : std_logic_vector(3 DOWNTO 0)  := (OTHERS => '0');
  SIGNAL TDO_IN     : std_logic                     := '0';

  --Outputs
  SIGNAL READ_DATA : std_logic_vector(31 DOWNTO 0);
  SIGNAL DONE      : std_logic;
  SIGNAL TMS_OUT   : std_logic;
  SIGNAL TDI_OUT   : std_logic;
  SIGNAL TCK_OUT   : std_logic;
  SIGNAL RSTB_OUT  : std_logic;

  -- Clock period definitions
  CONSTANT CLK_PERIOD : time := 20 ns;
  
BEGIN

  -- Instantiate the Unit Under Test (UUT)
  uut : jtag PORT MAP (
    CLK        => CLK,
    RST        => RST,
    START      => START,
    WEN        => WEN,
    READ_DATA  => READ_DATA,
    WRITE_DATA => WRITE_DATA,
    ADDRESS    => ADDRESS,
    DONE       => DONE,
    DIVIDE     => DIVIDE,
    DO_RSTB    => DO_RSTB,
    TMS_OUT    => TMS_OUT,
    TDI_OUT    => TDI_OUT,
    TCK_OUT    => TCK_OUT,
    TDO_IN     => TDO_IN,
    RSTB_OUT   => RSTB_OUT
    );

  -- Clock process definitions
  -- 50 MHz main clock
  CLK <= NOT CLK AFTER CLK_PERIOD/2;

  TDO_IN <= transport TDI_OUT after 1 us;

  -- Stimulus process
  stim_proc : PROCESS
  BEGIN
    WAIT FOR 50 ns;
    -- hold reset state for 100 ns.
    RST <= '1';
    WAIT FOR 100 ns;
    RST <= '0';

    -- defaults:
    DIVIDE     <= "0010";               -- JTAG clk = CLK/8
 --   TDO_IN     <= '0';
    WEN        <= '0';
    START      <= '0';
    DO_RSTB    <= '0';
    WRITE_DATA <= (OTHERS => '0');
    ADDRESS    <= (OTHERS => '0');

    WAIT FOR 100ns;

--    WAIT FOR CLK_PERIOD*10;

    -- insert stimulus here 
    WAIT UNTIL (rising_edge(CLK));

-------------------------------------------------------------------------------
-- codes to load for ChipID:
-- 0x0400000E - IR, 5 bits,dev_id instruction
-- 0x1F003101 - DR, 16 bits, 0x3101
-- 0xDF005048 - DR, last word, 16 bits 0x5048

    WRITE_DATA <= x"0400000E";
    WEN        <= '1';
    WAIT FOR CLK_PERIOD;

    ADDRESS    <= ADDRESS + 1;
    WRITE_DATA <= x"1F003101";
    WAIT FOR CLK_PERIOD;

    ADDRESS    <= ADDRESS + 1;
    WRITE_DATA <= x"DF005048";
    WAIT FOR CLK_PERIOD;

    WRITE_DATA <= (OTHERS => '0');
    ADDRESS    <= (OTHERS => '0');
    WEN        <= '0';
    WAIT FOR CLK_PERIOD*2;

    START <= '1';
    WAIT FOR CLK_PERIOD;

    START <= '0';

    WAIT;
  END PROCESS;

END;
