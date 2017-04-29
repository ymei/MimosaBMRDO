-- $Id: JTAG_tap.vhd 830 2014-10-23 21:11:49Z jschamba $
-------------------------------------------------------------------------------
-- Title      : jtag design
-- Project    : HFT PXL
-------------------------------------------------------------------------------
-- File       : jtag_tap.vhd
-- Author     : Michal S., Joachim Schambach
-- Company    : LBL, UT
-- Created    : 2013-02-08
-- Last update: 2014-10-23
-- Platform   : Windows, Xilinx ISE 13.4
-- Target     : Virtex-6 (XC6VLX240T-FF1759)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: derived from MS's original JTAG TAP state machine code
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-02-08    1.0    Michal,Jo       Created
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

-- LIBRARY UNISIM;
-- USE UNISIM.VComponents.ALL;

ENTITY JTAG_tap IS
  PORT (
    -- DAQ control interface
    CLK         : IN  std_logic;
    RST         : IN  std_logic;
    --
    START       : IN  std_logic;
    PAUSE       : OUT std_logic;
    BUSY        : OUT std_logic;
    GO          : IN  std_logic;
    --
    LAST        : IN  std_logic;
    IR_DR       : IN  std_logic_vector (1 DOWNTO 0);
    TX_DATA     : IN  std_logic_vector (15 DOWNTO 0);
    RX_DATA     : OUT std_logic_vector (15 DOWNTO 0);
    DATA_LENGTH : IN  std_logic_vector (3 DOWNTO 0);
    -- JTAG outputs
    TMS_OUT     : OUT std_logic;
    TDI_OUT     : OUT std_logic;
    TCK_OUT     : OUT std_logic;
    TDO_IN      : IN  std_logic;
    RSTB_OUT    : OUT std_logic
    );
END JTAG_tap;

ARCHITECTURE Behavioral OF JTAG_tap IS
  CONSTANT IR  : std_logic_vector(1 DOWNTO 0) := "00";
  CONSTANT DR  : std_logic_vector(1 DOWNTO 0) := "01";
  CONSTANT SRT : std_logic_vector(1 DOWNTO 0) := "10";  -- soft reset?
  CONSTANT HRT : std_logic_vector(1 DOWNTO 0) := "11";  -- hard reset?

  TYPE TAP_State_type IS (T_idle, T_idle_hi,
                          T_logic_reset, T_logic_reset_hi,
                          T_hard_reset,
                          T_init, T_init_hi,
                          T_select_DR_scan, T_select_DR_scan_hi,
                          T_capture_DR, T_capture_DR_hi,
                          T_shift_DR, T_shift_DR_hi,
                          T_exit1_DR, T_exit1_DR_hi,
                          T_pause_DR, T_pause_DR_hi,
                          T_exit2_DR, T_exit2_DR_hi,
                          T_update_DR, T_update_DR_hi,
                          T_select_IR_scan, T_select_IR_scan_hi,
                          T_capture_IR, T_capture_IR_hi,
                          T_shift_IR, T_shift_IR_hi,
                          T_exit1_IR, T_exit1_IR_hi,
                          T_pause_IR, T_pause_IR_hi,
                          T_exit2_IR, T_exit2_IR_hi,
                          T_update_IR, T_update_IR_hi
                          );
  SIGNAL state : TAP_State_type;

--  SIGNAL TX_bitCounter : std_logic_vector(3 DOWNTO 0)  := (OTHERS => '0');
  SIGNAL TX_bitCounter : integer RANGE 0 TO 15         := 0;
  SIGNAL sIR_DR_prev   : std_logic_vector(1 DOWNTO 0)  := "00";
  SIGNAL JTAG_busy     : std_logic                     := '0';
  SIGNAL sRX_data      : std_logic_vector (15 DOWNTO 0);
  SIGNAL sTX_data      : std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL sIR_DR        : std_logic_vector(1 DOWNTO 0)  := (OTHERS => '0');
--  SIGNAL sDataLength   : std_logic_vector(3 DOWNTO 0)  := (OTHERS => '0');
  SIGNAL sDataLength   : integer RANGE 0 TO 15         := 0;
  SIGNAL sTCK          : std_logic;
  SIGNAL sTDI          : std_logic;
  SIGNAL sTMS          : std_logic;

-------------------------------------------------------------------------------
BEGIN
  -- outputs:
  BUSY    <= JTAG_busy;
  RX_DATA <= sRX_data;
  TCK_OUT <= sTCK;
  TDI_OUT <= sTDI;
  TMS_OUT <= sTMS;

  -----------------------------------------------------------------------------
  -- register inputs
  IR_DR_buf_p : PROCESS (CLK)
  BEGIN
    IF rising_edge(CLK) THEN
      sIR_DR      <= IR_DR;
      sDataLength <= to_integer(unsigned(DATA_LENGTH));
    END IF;
  END PROCESS;

  -----------------------------------------------------------------------------
  -- JTAG TAP state machine
  JTAG_programmer : PROCESS (CLK)
  BEGIN
    IF rising_edge(CLK) THEN
      IF RST = '1' THEN                 -- synchronous reset (active hi)
        state         <= T_idle;
        sTCK          <= '0';
        sTMS          <= '1';
        sTDI          <= '0';
        JTAG_busy     <= '0';
        PAUSE         <= '0';
        RSTB_OUT      <= '1';
        sIR_DR_prev   <= (OTHERS => '0');
        TX_bitCounter <= 0;
        sRX_data      <= (OTHERS => '0');

      ELSE
        -- defaults
        sTDI      <= '0';
        JTAG_busy <= '1';
        PAUSE     <= '0';
        RSTB_OUT  <= '1';

        CASE state IS
-------   RUN TEST/IDLE
          WHEN T_idle =>
            sTCK <= '0';

            sIR_DR_prev   <= (OTHERS => '0');
            TX_bitCounter <= 0;

            IF START = '1' THEN
              sTMS     <= '0';
              sTX_data <= TX_DATA;
              state    <= T_idle_hi;
            ELSE
              JTAG_busy <= '0';
              sTMS      <= '0';
              state     <= T_idle;
            END IF;

          WHEN T_idle_hi =>
            sTCK  <= '1';
            state <= T_init;

-------   TEST LOGIC RESET
          WHEN T_logic_reset =>
            sTCK <= '0';
            IF TX_bitCounter = 5 THEN
              JTAG_busy <= '0';
              sTMS      <= '0';
              state     <= T_idle;
            ELSE
              sTMS          <= '1';
              TX_bitCounter <= TX_bitCounter + 1;
              state         <= T_logic_reset_hi;
            END IF;

          WHEN T_logic_reset_hi =>      -- TCK hi
            sTCK  <= '1';
            state <= T_logic_reset;

-------   Hard RESET (RSTB is low)
          WHEN T_hard_reset =>
            sTMS     <= '0';
            RSTB_OUT <= '0';
            IF TX_bitCounter < sDataLength THEN
              TX_bitCounter <= TX_bitCounter + 1;
              state         <= T_hard_reset;
            ELSE
              state <= T_idle;
            END IF;

-------   Starting..... (exiting from Run test/idle)
          WHEN T_init =>
            sTCK  <= '0';
            sTMS  <= '1';
            state <= T_init_hi;

          WHEN T_init_hi =>             -- TCK hi
            sTCK  <= '1';
            state <= T_select_DR_scan;

-------   Select DR Scan
          WHEN T_select_DR_scan =>
            sTCK <= '0';
            CASE sIR_DR IS
              WHEN IR =>
                sTMS <= '1';
              WHEN DR =>
                sTMS <= '0';
              WHEN SRT =>
                sTMS          <= '1';
                TX_bitCounter <= 0;
              WHEN OTHERS =>
                TX_bitCounter <= 0;
                sTMS          <= '0';
            END CASE;
            state <= T_select_DR_scan_hi;

          WHEN T_select_DR_scan_hi =>   -- TCK hi
            sTCK <= '1';
            CASE sIR_DR IS
              WHEN IR =>
                state <= T_select_IR_scan;
              WHEN DR =>
                state <= T_capture_DR;
              WHEN SRT =>               -- "Soft" Reset
                state <= T_logic_reset;
              WHEN OTHERS =>            -- "Hard" Reset
                state <= T_hard_reset;
            END CASE;

-------   Capture DR
          WHEN T_capture_DR =>
            sTCK  <= '0';
            sTMS  <= '0';
            state <= T_capture_DR_hi;

          WHEN T_capture_DR_hi =>       -- TCK hi
            sTCK  <= '1';
            state <= T_shift_DR;

-------   Shift DR
          WHEN T_shift_DR =>
            sTCK <= '0';

            sRX_data(15)          <= TDO_IN;
            sRX_data(14 DOWNTO 0) <= sRX_data(15 DOWNTO 1);

            sTDI     <= sTX_data(0);
            sTX_data <= '0' & sTX_data(15 DOWNTO 1);

            IF TX_bitCounter < sDataLength THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_shift_DR_hi;

          WHEN T_shift_DR_hi =>         -- TCK hi
            sTCK <= '1';
            sTDI <= sTDI;
            IF TX_bitCounter < sDataLength THEN
              TX_bitCounter <= TX_bitCounter + 1;
              state         <= T_shift_DR;
            ELSE
              TX_bitCounter <= 0;
              state         <= T_exit1_DR;
            END IF;


-------   Exit1 DR
          WHEN T_exit1_DR =>
            sTCK <= '0';

            sRX_data(15)          <= TDO_IN;
            sRX_data(14 DOWNTO 0) <= sRX_data(15 DOWNTO 1);

            sIR_DR_prev <= sIR_DR;
            IF LAST = '0' THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_exit1_DR_hi;

          WHEN T_exit1_DR_hi =>         -- TCK hi
            sTCK <= '1';

            -- realign data to be right justified
            case sDataLength is
                 when 0  => sRX_data(0 DOWNTO 0) <= sRX_data(15 DOWNTO 15-0);
                 when 1  => sRX_data(1 DOWNTO 0) <= sRX_data(15 DOWNTO 15-1);
                 when 2  => sRX_data(2 DOWNTO 0) <= sRX_data(15 DOWNTO 15-2);
                 when 3  => sRX_data(3 DOWNTO 0) <= sRX_data(15 DOWNTO 15-3);
                 when 4  => sRX_data(4 DOWNTO 0) <= sRX_data(15 DOWNTO 15-4);
                 when 5  => sRX_data(5 DOWNTO 0) <= sRX_data(15 DOWNTO 15-5);
                 when 6  => sRX_data(6 DOWNTO 0) <= sRX_data(15 DOWNTO 15-6);
                 when 7  => sRX_data(7 DOWNTO 0) <= sRX_data(15 DOWNTO 15-7);
                 when 8  => sRX_data(8 DOWNTO 0) <= sRX_data(15 DOWNTO 15-8);
                 when 9  => sRX_data(9 DOWNTO 0) <= sRX_data(15 DOWNTO 15-9);
                 when 10 => sRX_data(10 DOWNTO 0) <= sRX_data(15 DOWNTO 15-10);
                 when 11 => sRX_data(11 DOWNTO 0) <= sRX_data(15 DOWNTO 15-11);
                 when 12 => sRX_data(12 DOWNTO 0) <= sRX_data(15 DOWNTO 15-12);
                 when 13 => sRX_data(13 DOWNTO 0) <= sRX_data(15 DOWNTO 15-13);
                 when 14 => sRX_data(14 DOWNTO 0) <= sRX_data(15 DOWNTO 15-14);
                 when 15 => sRX_data(15 DOWNTO 0) <= sRX_data(15 DOWNTO 15-15);
            end case;

            IF LAST = '0' THEN
              state <= T_pause_DR;
            ELSE
              state <= T_update_DR;
            END IF;

-------   Pause DR
          WHEN T_pause_DR =>
            sTCK <= '0';

            PAUSE <= '1';
            IF GO = '0' THEN
              sTMS  <= '0';
              state <= T_pause_DR;
            ELSE
              sTX_data <= TX_DATA;
              sTMS     <= '1';
              state    <= T_pause_DR_hi;
            END IF;

          WHEN T_pause_DR_hi =>         -- TCK hi
            sTCK  <= '1';
            PAUSE <= '1';
            state <= T_exit2_DR;

-------   Exit2 DR
          WHEN T_exit2_DR =>
            sTCK <= '0';
            IF sIR_DR = sIR_DR_prev THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_exit2_DR_hi;

          WHEN T_exit2_DR_hi =>         -- TCK hi
            sTCK <= '1';
            IF sIR_DR = sIR_DR_prev THEN
              state <= T_shift_DR;
            ELSE
              state <= T_update_DR;
            END IF;

-------   Update DR
          WHEN T_update_DR =>
            sTCK <= '0';
            IF (LAST = '1') AND (sIR_DR = sIR_DR_prev) THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_update_DR_hi;

          WHEN T_update_DR_hi =>        -- TCK hi
            sTCK <= '1';
            IF (LAST = '1') AND (sIR_DR = sIR_DR_prev) THEN
              state <= T_idle;
            ELSE
              state <= T_select_DR_scan;
            END IF;

-------   Select IR scan
          WHEN T_select_IR_scan =>
            sTCK <= '0';
            IF sIR_DR = SRT THEN
              TX_bitCounter <= 0;
              sTMS          <= '1';
            ELSE
              sTMS <= '0';
            END IF;
            state <= T_select_IR_scan_hi;

          WHEN T_select_IR_scan_hi =>   -- TCK hi
            sTCK <= '1';
            IF sIR_DR = SRT THEN
              state <= T_logic_reset;
            ELSE
              state <= T_capture_IR;
            END IF;

-------   Capture IR
          WHEN T_capture_IR =>
            sTCK  <= '0';
            sTMS  <= '0';
            state <= T_capture_IR_hi;

          WHEN T_capture_IR_hi =>       -- TCK hi
            sTCK  <= '1';
            state <= T_shift_IR;

-------   Shift IR
          WHEN T_shift_IR =>
            sTCK                  <= '0';
            sRX_data(15)          <= TDO_IN;
            sRX_data(14 DOWNTO 0) <= sRX_data(15 DOWNTO 1);

            sTDI     <= sTX_data(0);
            sTX_data <= '0' & sTX_data(15 DOWNTO 1);

            IF TX_bitCounter < sDataLength THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_shift_IR_hi;

          WHEN T_shift_IR_hi =>         -- TCK hi
            sTCK <= '1';
            sTDI <= sTDI;

            IF TX_bitCounter < sDataLength THEN
              TX_bitCounter <= TX_bitCounter + 1;
              state         <= T_shift_IR;
            ELSE
              TX_bitCounter <= 0;
              state         <= T_exit1_IR;
            END IF;

-------   Exit1 IR
          WHEN T_exit1_IR =>
            sTCK <= '0';

            sRX_data(15)          <= TDO_IN;
            sRX_data(14 DOWNTO 0) <= sRX_data(15 DOWNTO 1);

            sIR_DR_prev <= sIR_DR;
            IF LAST = '0' THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_exit1_IR_hi;

          WHEN T_exit1_IR_hi =>         -- TCK hi
            sTCK <= '1';

            -- realign data to be right justified
            case sDataLength is
                 when 0  => sRX_data(0 DOWNTO 0) <= sRX_data(15 DOWNTO 15-0);
                 when 1  => sRX_data(1 DOWNTO 0) <= sRX_data(15 DOWNTO 15-1);
                 when 2  => sRX_data(2 DOWNTO 0) <= sRX_data(15 DOWNTO 15-2);
                 when 3  => sRX_data(3 DOWNTO 0) <= sRX_data(15 DOWNTO 15-3);
                 when 4  => sRX_data(4 DOWNTO 0) <= sRX_data(15 DOWNTO 15-4);
                 when 5  => sRX_data(5 DOWNTO 0) <= sRX_data(15 DOWNTO 15-5);
                 when 6  => sRX_data(6 DOWNTO 0) <= sRX_data(15 DOWNTO 15-6);
                 when 7  => sRX_data(7 DOWNTO 0) <= sRX_data(15 DOWNTO 15-7);
                 when 8  => sRX_data(8 DOWNTO 0) <= sRX_data(15 DOWNTO 15-8);
                 when 9  => sRX_data(9 DOWNTO 0) <= sRX_data(15 DOWNTO 15-9);
                 when 10 => sRX_data(10 DOWNTO 0) <= sRX_data(15 DOWNTO 15-10);
                 when 11 => sRX_data(11 DOWNTO 0) <= sRX_data(15 DOWNTO 15-11);
                 when 12 => sRX_data(12 DOWNTO 0) <= sRX_data(15 DOWNTO 15-12);
                 when 13 => sRX_data(13 DOWNTO 0) <= sRX_data(15 DOWNTO 15-13);
                 when 14 => sRX_data(14 DOWNTO 0) <= sRX_data(15 DOWNTO 15-14);
                 when 15 => sRX_data(15 DOWNTO 0) <= sRX_data(15 DOWNTO 15-15);
            end case;

            IF LAST = '0' THEN
              state <= T_pause_IR;
            ELSE
              state <= T_update_IR;
            END IF;

-------   Pause IR
          WHEN T_pause_IR =>
            sTCK <= '0';

            PAUSE <= '1';
            IF GO = '0' THEN
              sTMS  <= '0';
              state <= T_pause_IR;
            ELSE
              sTX_data <= TX_DATA;
              sTMS     <= '1';
              state    <= T_pause_IR_hi;
            END IF;

          WHEN T_pause_IR_hi =>         -- TCK hi
            sTCK  <= '1';
            PAUSE <= '1';
            state <= T_exit2_IR;

-------   Exit2 IR
          WHEN T_exit2_IR =>
            sTCK <= '0';
            IF sIR_DR = sIR_DR_prev THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_exit2_IR_hi;

          WHEN T_exit2_IR_hi =>         -- TCK hi
            sTCK <= '1';
            IF sIR_DR = sIR_DR_prev THEN
              state <= T_shift_IR;
            ELSE
              state <= T_update_IR;
            END IF;

-------   Update IR
          WHEN T_update_IR =>
            sTCK <= '0';
            IF (LAST = '1') AND (sIR_DR = sIR_DR_prev) THEN
              sTMS <= '0';
            ELSE
              sTMS <= '1';
            END IF;
            state <= T_update_IR_hi;

          WHEN T_update_IR_hi =>        -- TCK hi
            sTCK <= '1';
            IF (LAST = '1') AND (sIR_DR = sIR_DR_prev) THEN
              state <= T_idle;
            ELSE
              state <= T_select_DR_scan;
            END IF;

-------   Shouldn't happen:
          WHEN OTHERS =>
            state <= T_idle;

        END CASE;
      END IF;
    END IF;
  END PROCESS;

END Behavioral;
