-- $Id: jtag.vhd 830 2014-10-23 21:11:49Z jschamba $
-------------------------------------------------------------------------------
-- Title      : jtag design
-- Project    : HFT PXL
-------------------------------------------------------------------------------
-- File       : jtag.vhd
-- Author     : Xiangming Sun, Joachim Schambach
-- Company    : LBL
-- Created    : 2012-08-1
-- Last update: 2014-10-23
-- Platform   : Windows, Xilinx ISE 13.4
-- Target     : Virtex-6 (XC6VLX240T-FF1759)
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: this module has two memories inside, input and output memory.
--              input memory gets data via 'write_data' ,'address' and 'WEN'
--              then this data is processed to jtag interface, the return data is
--              stored in output memory which can be read through 'read_data',
--              and 'address'
-------------------------------------------------------------------------------
-- Copyright (c) 2012
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-08-1    1.0      Xiangming, Jo   Created
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY UNISIM;
USE UNISIM.VComponents.ALL;

--  Entity Declaration
ENTITY jtag IS
  PORT (
    CLK        : IN  std_logic;         -- system clock (50MHz?)
    RST        : IN  std_logic;         -- active high
    --control interface
    START      : IN  std_logic;         -- start JTAG programming
    WEN        : IN  std_logic;         -- input memory WRITE
    READ_DATA  : OUT std_logic_vector (31 DOWNTO 0);  -- output memory I/F
    WRITE_DATA : IN  std_logic_vector (31 DOWNTO 0);  -- input memory I/F
    ADDRESS    : IN  std_logic_vector (11 DOWNTO 0);  -- input/output memory address
    DONE       : OUT std_logic;         -- JTAG finished
    DIVIDE     : IN  std_logic_vector (3 DOWNTO 0);  -- one 'TCK' clock has 2^(DIVIDE+2) 'CLK'
    DO_RSTB    : IN  std_logic;  -- assert together with START to do JTAG RSTB
    -- JTAG interface
    TMS_OUT    : OUT std_logic;
    TDI_OUT    : OUT std_logic;
    TCK_OUT    : OUT std_logic;
    TDO_IN     : IN  std_logic;
    RSTB_OUT   : OUT std_logic
    );
END jtag;

-------------------------------------------------------------------------------
ARCHITECTURE Behavioral OF jtag IS
  TYPE state_type IS (wait_for_start,
                      execute_RSTB,
                      get_data,
                      start_jtag_machine,
                      check_result);
  SIGNAL state : state_type;

  SIGNAL input_mem_address  : unsigned(11 DOWNTO 0)         := (OTHERS => '0');
  SIGNAL output_mem_address : std_logic_vector(11 DOWNTO 0) := (OTHERS => '0');
  SIGNAL IR_DR              : std_logic_vector(1 DOWNTO 0)  := (OTHERS => '0');
  SIGNAL output_mem_in      : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL input_mem_out      : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
  SIGNAL data_buffered      : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');

  SIGNAL last        : std_logic                    := '0';
  SIGNAL TX_data     : std_logic_vector(15 DOWNTO 0);
  SIGNAL RX_data     : std_logic_vector(15 DOWNTO 0);
  SIGNAL data_length : std_logic_vector(3 DOWNTO 0) := (OTHERS => '0');

  SIGNAL outputMem_WEN : std_logic_vector(0 DOWNTO 0)  := (OTHERS => '0');
  SIGNAL inputMem_WEN  : std_logic_vector(0 DOWNTO 0)  := (OTHERS => '0');
  SIGNAL inputMem_data : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');

  SIGNAL clock_divider : unsigned(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL JTAG_pause    : std_logic             := '0';
  SIGNAL JTAG_busy     : std_logic             := '0';
  SIGNAL JTAG_go       : std_logic             := '0';
  SIGNAL JTAG_start    : std_logic             := '0';

  SIGNAL divided_clk : std_logic := '0';

  ATTRIBUTE clock_signal                : string;
  ATTRIBUTE clock_signal OF divided_clk : SIGNAL IS "yes";

  SIGNAL delay_cnt : integer RANGE 0 TO 7    := 0;
  SIGNAL iWordCnt  : integer RANGE 0 TO 4095 := 0;

  SIGNAL input_address_zero : boolean := false;

  COMPONENT JTAG_tap
    PORT (
      CLK         : IN  std_logic;
      RST         : IN  std_logic;
      START       : IN  std_logic;
      GO          : IN  std_logic;
      LAST        : IN  std_logic;
      IR_DR       : IN  std_logic_vector(1 DOWNTO 0);
      TX_DATA     : IN  std_logic_vector(15 DOWNTO 0);
      RX_DATA     : OUT std_logic_vector(15 DOWNTO 0);
      DATA_LENGTH : IN  std_logic_vector(3 DOWNTO 0);
      --
      TDO_IN      : IN  std_logic;
      PAUSE       : OUT std_logic;
      BUSY        : OUT std_logic;
      TMS_OUT     : OUT std_logic;
      TDI_OUT     : OUT std_logic;
      TCK_OUT     : OUT std_logic;
      RSTB_OUT    : OUT std_logic
      );
  END COMPONENT;

  COMPONENT spram32x4096
    PORT (
      clka  : IN  std_logic;
      wea   : IN  std_logic_vector(0 DOWNTO 0);
      addra : IN  std_logic_vector(11 DOWNTO 0);
      dina  : IN  std_logic_vector(31 DOWNTO 0);
      douta : OUT std_logic_vector(31 DOWNTO 0));
  END COMPONENT;


BEGIN
  PROCESS (CLK)
  BEGIN
    IF rising_edge(CLK) THEN
      IF RST = '1' THEN
        clock_divider <= (OTHERS => '0');
        divided_clk   <= '0';
      ELSE
        -- generate clock for the JTAG module
        clock_divider <= clock_divider + 1;
        divided_clk   <= clock_divider(to_integer(unsigned(DIVIDE)));
      END IF;
    END IF;
  END PROCESS;

  -----------------------------------------------------------------------------
  dataFeederSM : PROCESS (CLK)
  BEGIN
    IF rising_edge(CLK) THEN
      IF RST = '1' THEN -- syncronous reset
        outputMem_WEN(0) <= '0';
        delay_cnt        <= 0;
        JTAG_start       <= '0';
        JTAG_go          <= '0';
        delay_cnt        <= 0;          -- reset delay counter
        outputMem_WEN(0) <= '0';
        state            <= wait_for_start;

      ELSE
        CASE state IS
--        //////////////////////
          WHEN wait_for_start =>
            JTAG_start       <= '0';
            JTAG_go          <= '0';
            delay_cnt        <= 0;      -- reset delay counter
            outputMem_WEN(0) <= '0';
            iWordCnt         <= 0;

            IF (DO_RSTB = '1') AND (START = '1') AND
              (JTAG_busy = '0') AND (JTAG_pause = '0') THEN
              DONE              <= '0';
              input_mem_address <= (OTHERS => '0');  -- reset memory address
              inputMem_WEN(0)   <= '0';

              state <= execute_RSTB;
            ELSIF (START = '1') AND (JTAG_busy = '0') AND (JTAG_pause = '0') THEN
              DONE              <= '0';
              input_mem_address <= (OTHERS => '0');  -- reset memory address
              inputMem_WEN(0)   <= '0';

              state <= get_data;
            ELSE
              DONE              <= '1';
              -- write to input memory
              inputMem_WEN(0)   <= WEN;
              input_mem_address <= unsigned(ADDRESS);
              inputMem_data     <= WRITE_DATA;
            END IF;

--        ////////////////
          WHEN execute_RSTB =>
            JTAG_start  <= '0';
            JTAG_go     <= '0';
            last        <= '0';
            data_length <= x"f";
            IR_DR       <= "11";
            TX_data     <= (OTHERS => '0');

            input_address_zero <= true;

            state <= start_jtag_machine;

--        ////////////////
          WHEN get_data =>
            JTAG_start <= '0';
            JTAG_go    <= '0';
            delay_cnt  <= delay_cnt + 1;

            IF delay_cnt = 3 THEN       -- first buffer current input memory
              data_buffered <= input_mem_out(31 DOWNTO 0);
            ELSIF delay_cnt = 5 THEN    -- now decode it
              IF iWordCnt = 2500 THEN
                -- something bad happend, stop it
                last <= '1';
              ELSE
                last     <= data_buffered(31) AND data_buffered(30);
                iWordCnt <= iWordCnt + 1;
              END IF;
              data_length <= data_buffered(27 DOWNTO 24);
              IR_DR       <= data_buffered(29 DOWNTO 28);
              TX_data     <= data_buffered(15 DOWNTO 0);

              input_address_zero <= (to_integer(input_mem_address) = 0);

              state <= start_jtag_machine;
            END IF;

--        //////////////////////////
          WHEN start_jtag_machine =>
            IF input_address_zero THEN
              JTAG_go <= '0';
              IF JTAG_busy = '1' THEN
                JTAG_start <= '0';
                state      <= check_result;
              ELSE
                JTAG_start <= '1';
              END IF;
            ELSE
              JTAG_start <= '0';
              IF JTAG_pause = '1' THEN
                JTAG_go <= '1';
              ELSIF JTAG_go = '1' THEN
                JTAG_go <= '0';
                state   <= check_result;
              ELSE
                JTAG_go <= JTAG_go;
              END IF;
            END IF;

--        ////////////////////
          WHEN check_result =>
            output_mem_in(31 DOWNTO 16) <= data_buffered(31 DOWNTO 16);
            output_mem_in(15 DOWNTO 0)  <= RX_data;

            IF outputMem_WEN(0) = '0' THEN
              outputMem_WEN(0) <= '1';
            ELSIF JTAG_busy = '0' THEN
              outputMem_WEN(0) <= '0';
              state            <= wait_for_start;
            ELSIF JTAG_pause = '1' THEN
              outputMem_WEN(0)  <= '0';
              delay_cnt         <= 0;
              input_mem_address <= input_mem_address + 1;
              state             <= get_data;
            END IF;

        END CASE;
      END IF;
    END IF;
  END PROCESS;

  -----------------------------------------------------------------------------
  input_memory_inst : spram32x4096
    PORT MAP (
      clka  => CLK,
      dina  => inputMem_data,
      addra => std_logic_vector(input_mem_address),
      wea   => inputMem_WEN,
      douta => input_mem_out
      );

  output_mem_address <= std_logic_vector(input_mem_address) WHEN JTAG_busy = '1'
                        ELSE ADDRESS;

  output_memory_inst : spram32x4096
    PORT MAP (
      clka  => CLK,
      dina  => output_mem_in,
      addra => output_mem_address,
      wea   => outputMem_WEN,
      douta => READ_DATA
      );

  inst_JTAG_tap : JTAG_tap
    PORT MAP (
      CLK         => divided_clk,
      RST         => RST,
      START       => JTAG_start,
      PAUSE       => JTAG_pause,
      BUSY        => JTAG_busy,
      GO          => JTAG_go,
      LAST        => last,
      IR_DR       => IR_DR,
      TX_DATA     => TX_data,
      RX_DATA     => RX_data,
      DATA_LENGTH => data_length,
      TMS_OUT     => TMS_OUT,
      TDI_OUT     => TDI_OUT,
      TCK_OUT     => TCK_OUT,
      TDO_IN      => TDO_IN,
      RSTB_OUT    => RSTB_OUT
      );

END Behavioral;
