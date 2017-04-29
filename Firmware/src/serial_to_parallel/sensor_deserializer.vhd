-- $Id: sensor_deserializer.vhd 506 2014-01-20 14:39:02Z jschamba $
-------------------------------------------------------------------------------
-- Title      : HFT PXL RDO board Sensor Deserializer
-- Project    : HFT PXL
-------------------------------------------------------------------------------
-- File       : sensor_deserializer
-- Author     : Joachim Schambach (jschamba@physics.utexas.edu)
-- Company    : University of Texas at Austin
-- Created    : 2013-07-16
-- Last update: 2014-01-14
-- Platform   : Windows, Xilinx PlanAhead 14.5
-- Target     : Virtex-6 (XC6VLX240T-FF1759)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Use IODELAY with loadable delay config to adjust the
--              individual sensor outputs. Then use DDR to latch the delayed
--              signal at 0 and 180 degrees. DELAY_CONFIG(5) chooses between
--              these two phases. Use a 16bit shift register to
--              assemble into 16bit words. Try to find header pattern in
--              shift register. If not found, return error.
--              Finally sync parallel data and ERR to LATCHCLK.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-07-16  1.0      jschamba        Created
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

--  Entity Declaration
ENTITY sensor_deserializer IS
  GENERIC (
    -- a frame contains 1856 16bit words = 3712 8bit half words
    FRAME_SIZE     : integer                       := 3712;
    HEADER_PATTERN : std_logic_vector(15 DOWNTO 0) := x"0F0F"
    );
  PORT (
    RST           : IN  std_logic;      -- global reset
    CTRLCLK       : IN  std_logic;      --  50 MHz
    DATACLK       : IN  std_logic;      -- 160 MHz
    LATCHCLK      : IN  std_logic;      --  10 MHz
    SER_RESET     : IN  std_logic;      -- ISERDES reset
    LOAD_CONFIG   : IN  std_logic;      -- load delay configurations
    DELAY_CONFIG0 : IN  std_logic_vector (5 DOWNTO 0);  -- tap value sensor signal 0
    DELAY_CONFIG1 : IN  std_logic_vector (5 DOWNTO 0);  -- tap value sensor signal 1
    SIG_IN        : IN  std_logic_vector (1 DOWNTO 0);  -- input signals from sensor
    -- parallel data and latch clock (10MHz)
    SIG_PAR       : OUT std_logic_vector (31 DOWNTO 0);
    -- test
    --TAP_OUT       : OUT std_logic_vector (9 DOWNTO 0);
    --status 
    ERR           : OUT std_logic
    );
END sensor_deserializer;

-------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF sensor_deserializer IS
  SIGNAL sOuttap0     : std_logic_vector(4 DOWNTO 0);
  SIGNAL sOuttap1     : std_logic_vector(4 DOWNTO 0);
  SIGNAL sIodelay_rst : std_logic;
  SIGNAL sDataClk     : std_logic;
  SIGNAL sISerdes0_q  : std_logic_vector (15 DOWNTO 0);
  SIGNAL sISerdes1_q  : std_logic_vector (15 DOWNTO 0);
  SIGNAL sShifted0    : std_logic_vector(15 DOWNTO 0);
  SIGNAL sShifted1    : std_logic_vector(15 DOWNTO 0);
  SIGNAL shiftRst     : std_logic;
  SIGNAL sErr         : std_logic;
  SIGNAL sData_delay  : std_logic_vector(1 DOWNTO 0);
  SIGNAL sData_ddr_q1 : std_logic_vector(1 DOWNTO 0);
  SIGNAL sData_ddr_q2 : std_logic_vector(1 DOWNTO 0);

  TYPE shiftState_type IS (S0, S1, S2, S3);
  SIGNAL shiftState : shiftState_type;

--  ATTRIBUTE IOB                              : string;
--  ATTRIBUTE IODELAY_GROUP                    : string;
--  ATTRIBUTE IODELAY_GROUP OF iodelaye1_inst0 : LABEL IS IOD_GROUP;
--  ATTRIBUTE IODELAY_GROUP OF iodelaye1_inst1 : LABEL IS IOD_GROUP;

BEGIN
  --TAP_OUT <= sOuttap1 & sOuttap0;

  sIodelay_rst <= RST OR LOAD_CONFIG;   -- IODELAY reset also loads count value
  sDataClk     <= DATACLK;

  -- Signal 0 Delay
  iodelaye1_inst0 : IODELAYE1
    GENERIC MAP (
      CINVCTRL_SEL          => false,   -- TRUE, FALSE
      DELAY_SRC             => "I",     -- I, IO, O, CLKIN, DATAIN
      HIGH_PERFORMANCE_MODE => true,    -- TRUE, FALSE
      IDELAY_TYPE           => "VAR_LOADABLE",  -- FIXED, DEFAULT, VARIABLE, or VAR_LOADABLE
      IDELAY_VALUE          => 0,       -- 0 to 31
      ODELAY_TYPE           => "FIXED",  -- Has to be set to FIXED when IODELAYE1 is configured for Input 
      ODELAY_VALUE          => 0,  -- Set to 0 as IODELAYE1 is configured for Input
      REFCLK_FREQUENCY      => 200.0,
      SIGNAL_PATTERN        => "DATA"   -- CLOCK, DATA
      )
    PORT MAP (
      DATAOUT     => sData_delay(0),
      DATAIN      => '0',               -- Data from FPGA logic
      C           => CTRLCLK,           -- CLK,
      CE          => '0',               -- DELAY_DATA_CE, don't change delay
      INC         => '0',               -- DELAY_DATA_INC,
      IDATAIN     => SIG_IN(0),         -- Driven by IOB
      ODATAIN     => '0',
      RST         => sIodelay_rst,      -- '1' loads CNTVALUEIN as delay
      T           => '1',               -- defined as input
      CNTVALUEIN  => DELAY_CONFIG0(4 DOWNTO 0),  -- DELAY_TAP_IN,
      CNTVALUEOUT => sOuttap0,          -- DELAY_TAP_OUT,
      CLKIN       => '0',
      CINVCTRL    => '0'
      );

  -- Signal 0 latch in a DDR. The 2 outputs are sampled at 180 deg phase difference
  -- This latches the data in the IOB, so timing should be fixed
  IDDR_inst0 : IDDR
    GENERIC MAP (
      DDR_CLK_EDGE => "SAME_EDGE",  -- "OPPOSITE_EDGE", "SAME_EDGE", or "SAME_EDGE_PIPELINED"
      INIT_Q1      => '0',              -- Initial value of Q1: '0' or '1'
      INIT_Q2      => '0',              -- Initial value of Q2: '0' or '1'
      SRTYPE       => "ASYNC")          -- Set/Reset type: "SYNC" or "ASYNC"
    PORT MAP (
      Q1 => sData_ddr_q1(0),        -- 1-bit output for positive edge of clock
      Q2 => sData_ddr_q2(0),        -- 1-bit output for negative edge of clock
      C  => sDataClk,                   -- 1-bit clock input
      CE => '1',                        -- 1-bit clock enable input
      D  => sData_delay(0),             -- 1-bit DDR data input
      R  => '0',                        -- 1-bit reset
      S  => '0'                         -- 1-bit set
      );

  -- Signal 1 Delay
  iodelaye1_inst1 : IODELAYE1
    GENERIC MAP (
      CINVCTRL_SEL          => false,   -- TRUE, FALSE
      DELAY_SRC             => "I",     -- I, IO, O, CLKIN, DATAIN
      HIGH_PERFORMANCE_MODE => true,    -- TRUE, FALSE
      IDELAY_TYPE           => "VAR_LOADABLE",  -- FIXED, DEFAULT, VARIABLE, or VAR_LOADABLE
      IDELAY_VALUE          => 0,       -- 0 to 31
      ODELAY_TYPE           => "FIXED",  -- Has to be set to FIXED when IODELAYE1 is configured for Input 
      ODELAY_VALUE          => 0,  -- Set to 0 as IODELAYE1 is configured for Input
      REFCLK_FREQUENCY      => 200.0,
      SIGNAL_PATTERN        => "DATA"   -- CLOCK, DATA
      )
    PORT MAP (
      DATAOUT     => sData_delay(1),
      DATAIN      => '0',               -- Data from FPGA logic
      C           => CTRLCLK,           -- CLK,
      CE          => '0',               -- DELAY_DATA_CE, don't change delay
      INC         => '0',               -- DELAY_DATA_INC,
      IDATAIN     => SIG_IN(1),         -- Driven by IOB
      ODATAIN     => '0',
      RST         => sIodelay_rst,      -- '1' loads CNTVALUEIN as delay
      T           => '1',               -- defined as input
      CNTVALUEIN  => DELAY_CONFIG1(4 DOWNTO 0),  -- DELAY_TAP_IN,
      CNTVALUEOUT => sOuttap1,          -- DELAY_TAP_OUT,
      CLKIN       => '0',
      CINVCTRL    => '0'
      );

  -- Signal 1 latch in a DDR. The 2 outputs are sampled at 180 deg phase difference 
  -- This latches the data in the IOB, so timing should be fixed
  IDDR_inst1 : IDDR
    GENERIC MAP (
      DDR_CLK_EDGE => "SAME_EDGE",  -- "OPPOSITE_EDGE", "SAME_EDGE", or "SAME_EDGE_PIPELINED"
      INIT_Q1      => '0',              -- Initial value of Q1: '0' or '1'
      INIT_Q2      => '0',              -- Initial value of Q2: '0' or '1'
      SRTYPE       => "ASYNC")          -- Set/Reset type: "SYNC" or "ASYNC"
    PORT MAP (
      Q1 => sData_ddr_q1(1),        -- 1-bit output for positive edge of clock
      Q2 => sData_ddr_q2(1),        -- 1-bit output for negative edge of clock
      C  => sDataClk,                   -- 1-bit clock input
      CE => '1',                        -- 1-bit clock enable input
      D  => sData_delay(1),             -- 1-bit DDR data input
      R  => '0',                        -- 1-bit reset
      S  => '0'                         -- 1-bit set
      );


  -- use a shift register to deserialize data into 16bit parallel data
  -- then use a state machine to determine the correct bit position
  -- make sure we see header every frame
  shiftSM : PROCESS (sDataClk, shiftRst) IS
    VARIABLE iShiftCtr : integer RANGE 0 TO 15        := 0;
    VARIABLE iframeCtr : integer RANGE 0 TO 4095      := 0;
  BEGIN
    IF rising_edge(sDataClk) THEN
      shiftRst <= SER_RESET OR sIodelay_rst;

      IF shiftRst = '1' THEN            -- synchronous reset (active high)
        sISerdes0_q <= (OTHERS => '0');
        sISerdes1_q <= (OTHERS => '0');
        sShifted0   <= (OTHERS => '0');
        sShifted1   <= (OTHERS => '0');
        iShiftCtr   := 0;
        iFrameCtr   := 0;
        sErr        <= '1';
        shiftState  <= S0;

      ELSE
        -- choose clock edge for signal 0
        IF DELAY_CONFIG0(5) = '0' THEN
          sISerdes0_q(15) <= sData_ddr_q1(0);
        ELSE
          sISerdes0_q(15) <= sData_ddr_q2(0);
        END IF;

        -- choose clock edge for signal 1
        IF DELAY_CONFIG1(5) = '0' THEN
          sISerdes1_q(15) <= sData_ddr_q1(1);
        ELSE
          sISerdes1_q(15) <= sData_ddr_q2(1);
        END IF;

        -- Two 16bit shift registers
        sISerdes0_q(14 DOWNTO 0) <= sISerdes0_q(15 DOWNTO 1);
        sISerdes1_q(14 DOWNTO 0) <= sISerdes1_q(15 DOWNTO 1);

        -- latch parallel 16bit data
        IF iShiftCtr = 0 THEN
          sShifted0 <= sISerdes0_q;
          sShifted1 <= sISerdes1_q;
        END IF;


        -- state machine for determining correct bit slip
        CASE shiftState IS
--        /////// initialize; start in error
          WHEN S0 =>
            sErr       <= '1';
            iShiftCtr  := 0;
            iFrameCtr  := 0;
            shiftState <= S1;

--        /////// try to find header
          WHEN S1 =>
            sErr <= '1';
            IF (sISerdes0_q = HEADER_PATTERN) AND (sISerdes1_q = HEADER_PATTERN) THEN
              iShiftCtr  := 1;
              shiftState <= S2;
            END IF;

--        /////// found header, no longer in error; check for header every frame
          WHEN S2 =>
            sErr <= '0';

            -- every 16 bits
            IF iShiftCtr = 15 THEN
              iShiftCtr := 0;           -- wrap shift counter

              -- check for header pattern every FRAME_SIZE words
              IF (iFrameCtr = FRAME_SIZE) AND
                (sShifted0 = HEADER_PATTERN) AND (sShifted1 = HEADER_PATTERN)
              THEN
                -- header found in next frame; ok
                iFrameCtr := 1;
              ELSIF iFrameCtr = FRAME_SIZE THEN
                -- lost header; go to error state
                shiftState <= S3;
              ELSIF (iFrameCtr = 2) AND (sShifted0 /= sShifted1) THEN
                -- datalength in the two lines is not the same
                shiftState <= S3;
              ELSE
                iFrameCtr := iFrameCtr + 1;
              END IF;
            ELSE
              iShiftCtr := iShiftCtr + 1;
            END IF;

--        /////// lost header; in error again
          WHEN S3 =>
            sErr <= '1';

--        /////// should never happen
          WHEN OTHERS =>
            shiftState <= S0;
        END CASE;
        
      END IF;
    END IF;
  END PROCESS shiftSM;

  -- output parallel data and error on rising edge of latch clock
  latch_proc : PROCESS (LATCHCLK) IS
  BEGIN
    IF falling_edge(LATCHCLK) THEN
      SIG_PAR <= sShifted1 & sShifted0;
      ERR     <= sErr;
    END IF;
  END PROCESS latch_proc;

END Behavioral;
