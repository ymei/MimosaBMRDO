-- $Id: data_mod.vhd 556 2014-02-18 15:13:29Z jschamba $
-------------------------------------------------------------------------------
-- Title      : Data Modification Module
-- Project    : HFT PXL
-------------------------------------------------------------------------------
-- File       : data_mod.vhd
-- Author     : J. Schambach
-- Company    : University of Texas
-- Created    : 2012-09-05
-- Last update: 2014-02-15
-- Platform   : Windows, Xilinx PlanAhead 14.5
-- Target     : Virtex-6 (XC6VLX240T-FF1759)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Modify the sensor data to conform to the data format defined
--              in the PXL Readout Architecture meeting. Set flags that
--              indicate which section of the data we are in. Data is  first
--              delayed to account for trigger latency.
-------------------------------------------------------------------------------
-- Copyright (c) 2012 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2012-09-05  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY data_mod IS
  GENERIC (
    HEADER_PATTERN  : std_logic_vector (15 DOWNTO 0) := x"AAAA";
    TRAILER_PATTERN : std_logic_vector (15 DOWNTO 0) := x"5678"
    );
  PORT (
    CLK           : IN  std_logic;      -- 10 MHz 32bit latch clock
    RESET         : IN  std_logic;
    DATA_IN       : IN  std_logic_vector(31 DOWNTO 0);
    CHIP_ID       : IN  std_logic_vector(5 DOWNTO 0);
    TRIGGER_DELAY : IN  integer RANGE 0 TO 31 := 4;
    --
    TRAILER_ERR   : OUT std_logic;
    DATA_OUT      : OUT std_logic_vector(31 DOWNTO 0);
    IsHEADER      : OUT std_logic;
    IsSTATED      : OUT std_logic;
    IsTRAILER     : OUT std_logic;
    IsCounter_L   : OUT std_logic;
    IsCounter_H   : OUT std_logic
    );
END data_mod;

ARCHITECTURE impl OF data_mod IS
  TYPE state_type IS (
    HeaderSt,
    FramectrSt,
    LengthSt,
    State0St,
    StateSt,
    TrailerSt
    );
  SIGNAL dataState : state_type;

  SIGNAL sDataInDelayed : std_logic_vector (32*32-1 DOWNTO 0);

  SIGNAL sDataIn    : std_logic_vector(31 DOWNTO 0);
  SIGNAL sDataOut   : std_logic_vector(31 DOWNTO 0);
  SIGNAL sState0LSB : std_logic := '1';

BEGIN
  DATA_OUT <= sDataOut;

  data_decode : PROCESS (CLK) IS
    VARIABLE stateCtr : unsigned(3 DOWNTO 0) := "0000";
    VARIABLE wordCtr  : unsigned(15 DOWNTO 0);
  BEGIN
    IF rising_edge(CLK) THEN
      -- defaults:
      IsHEADER  <= '0';
      IsSTATED  <= '0';
      IsTRAILER <= '0';
      IsCounter_L <= '0';
      IsCounter_H <= '0';

      IF RESET = '1' THEN               -- synchronous reset (active high)
	    TRAILER_ERR    <= '0';
        dataState      <= HeaderSt;
        sDataOut       <= (OTHERS => '0');
        sState0LSB     <= '1';
        stateCtr       := (OTHERS => '0');
        wordCtr        := (OTHERS => '0');
        sDataInDelayed <= (OTHERS => '0');
        
      ELSE
        -- delay the input data by the TRIGGER DELAY.
        -- DATA_OUT will be TRIGGER_DELAY+2 clocks later than DATA_IN
        sDataInDelayed(32*32-1 DOWNTO 32) <= sDataInDelayed(32*31-1 DOWNTO 0);
        sDataInDelayed(31 DOWNTO 0)       <= DATA_IN;

        -- delayed input data
        sDataIn  <= sDataInDelayed(32*(TRIGGER_DELAY+1)-1 DOWNTO 32*TRIGGER_DELAY);
        -- default: output data is unmodified input data
        sDataOut <= sDataIn;

        -- Now modify data with this state machine
        CASE dataState IS
          WHEN HeaderSt =>
            -- Try to find header pattern constant
            IF sDataIn = (HEADER_PATTERN & HEADER_PATTERN) THEN
              IsHEADER  <= '1';
              dataState <= FramectrSt;
            END IF;

          WHEN FramectrSt =>
            -- 32bit Frame Counter
            IsCounter_L <= '1';
            dataState <= LengthSt;

          WHEN LengthSt =>
            -- 16bit data length both in LSB and MSB
            sState0LSB <= '1';          -- State 0 in LSB
            wordCtr    := unsigned(sDataIn(15 DOWNTO 0));
            IsCounter_H <= '1';
            IF wordCtr = x"0000" THEN
              dataState <= TrailerSt;
            ELSE
              dataState <= State0St;
            END IF;
            
            
          WHEN State0St =>
            -- State0 included in data word
            IsSTATED <= '1';
            wordCtr  := wordCtr - 1;

            IF sState0LSB = '1' THEN
              -- data lines (MSB & LSB): State1 & State0
              sState0LSB <= sDataIn(0);
              stateCtr   := unsigned(sDataIn(3 DOWNTO 0));
              stateCtr   := stateCtr - 1;

              -- reorder data:
              sDataOut(0)            <= '0';
              sDataOut(1)            <= sDataIn(15);           -- overflow bit
              sDataOut(11 DOWNTO 2)  <= sDataIn(13 DOWNTO 4);  -- row number
              sDataOut(12)           <= '1';                   -- Row marker
              sDataOut(15 DOWNTO 13) <= CHIP_ID(2 DOWNTO 0);
              sDataOut(31 DOWNTO 29) <= CHIP_ID(5 DOWNTO 3);

              IF wordCtr = x"0000" THEN
                sState0LSB <= '1';
                dataState  <= TrailerSt;
              ELSIF stateCtr(3 DOWNTO 1) = "000" THEN
                dataState <= state0St;
              ELSE
                dataState <= StateSt;
              END IF;

            ELSE
              -- data lines (MSB & LSB): State0 & StateN
              sState0LSB <= NOT sDataIn(16);
              stateCtr   := unsigned(sDataIn(19 DOWNTO 16));

              -- reorder data:
              sDataOut(16)           <= '0';
              sDataOut(17)           <= sDataIn(31);            -- overflow bit
              sDataOut(27 DOWNTO 18) <= sDataIn(29 DOWNTO 20);  -- row number
              sDataOut(28)           <= '1';                    -- Row marker
              sDataOut(15 DOWNTO 13) <= CHIP_ID(2 DOWNTO 0);
              sDataOut(31 DOWNTO 29) <= CHIP_ID(5 DOWNTO 3);

              IF wordCtr = x"0000" THEN
                -- set column number to 1023, bits 16,17, and 28 to '0' 
                sDataOut(28 DOWNTO 16) <= "0111111111100";

                dataState <= TrailerSt;
              ELSIF stateCtr(3 DOWNTO 1) = "000" THEN
                dataState <= State0St;
              ELSE
                dataState <= StateSt;
              END IF;
            END IF;

            
          WHEN StateSt =>
            -- both MSB and LSB are not State0
            IsSTATED <= '1';

            wordCtr  := wordCtr - 1;
            stateCtr := stateCtr - 2;

            -- reorder data: just add CHIP_ID
            sDataOut(15 DOWNTO 13) <= CHIP_ID(2 DOWNTO 0);
            sDataOut(31 DOWNTO 29) <= CHIP_ID(5 DOWNTO 3);

            IF wordCtr = x"0000" THEN
              sState0LSB <= '1';
              dataState  <= TrailerSt;
            ELSIF stateCtr(3 DOWNTO 1) = "000" THEN
              dataState <= State0St;
            ELSE
              dataState <= stateSt;
            END IF;

          WHEN TrailerSt =>
            -- 32bit Trailer
            IsTRAILER <= '1';
	    IF sDataIn /= (TRAILER_PATTERN & TRAILER_PATTERN) THEN
	      TRAILER_ERR <= '1';
	    END IF;
            dataState <= HeaderSt;
            
          WHEN OTHERS =>
            -- should not happen, start at beginning
            dataState <= HeaderSt;
        END CASE;

      END IF;
      
    END IF;
  END PROCESS data_decode;
END impl;



