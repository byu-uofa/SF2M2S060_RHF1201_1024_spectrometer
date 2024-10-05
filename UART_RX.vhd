-- ----------------------------------------------------------------------------
--              : Copyright (C) 2018 COM DEV International. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV International prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : uart_rx.vhd
--              :
-- Project      : UVI ROE 
-- Author       : Muhammad Amjad
-- Created      : Apr 16, 2018
--
-- Description  : -- This file contains the UART Receiver.  This receiver is able to
--                  receive 8 bits of serial data, one start bit, one stop bit,
--                  and optional parity bit.  When receive is complete o_rx_dv will be
--                  driven high for one clock cycle.
-- 
--                  Set Generic g_CLKS_PER_BIT as follows:
--                  g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
--                  Example: 10 MHz Clock, 115200 baud UART
--                  (10000000)/(115200) = 87
--
--
-- SVN keywords : $Rev: 350 $
--                $Author: mamjad $
--                $Date: 2020-05-25 15:30:29 -0400 (Mon, 25 May 2020) $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M Amjad            | Apr 16, 2018  |    Initial Creation
--   v0.2  | M Amjad            | May 12, 2018  |    Added even parity bit in Rx byte and a parity verification state
-- -----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity UART_RX is
  generic (
    g_CLKS_PER_BIT  : integer := 868;    -- 100MHz clocks per bit for 115200 Baud rate
    g_PARIY         : integer := 2;      -- Parity (Valid Values: 0=No Parity, 1=Odd Parity, 2=Even parity)
    g_STOP_BITS     : integer := 1       -- Number of stop bits (valid values are 1 or 2)
    );
  port (
    i_reset         : in  std_logic;
    i_clk           : in  std_logic;
    i_rx_serial     : in  std_logic;
    o_rx_dv         : out std_logic;
    o_rx_byte       : out std_logic_vector(7 downto 0);
    o_rx_parity_err : out std_logic
    );
end UART_RX;
 
architecture rtl of UART_RX is
 
  type t_sm_main_state_type is (ST_IDLE, ST_RX_START_BIT, ST_RX_DATA_BITS,
                     ST_RX_PARITY_BIT, ST_RX_STOP_BIT, ST_RX_PARITY_CHK, ST_CLEAN_UP);
  signal sm_uart_rx_state   : t_sm_main_state_type;
 
  signal s_rx_data_d1       : std_logic := '0';
  signal s_rx_data          : std_logic := '0';
  constant C_PARITY_CTRL    : integer range 0 to 2 := g_PARIY;
  signal s_clk_count        : integer range 0 to G_CLKS_PER_BIT-1 := 0;
  signal s_bit_index        : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal s_rx_byte          : std_logic_vector(7 downto 0) := (others => '0');
  signal s_rx_dv            : std_logic := '0';
  signal s_parity_cnt       : unsigned(3 downto 0);
  signal s_rx_parity_err    : std_logic;
 -- -----------------------------------------------------------------------------  
begin
 
-- Purpose: Double-register the incoming data.
-- This allows it to be used in the UART RX Clock Domain.
-- (It removes problems caused by metastabiliy)
sample_proc : process (i_reset, i_clk)
begin
    if i_reset = '1' then
        s_rx_data_d1 <= '1';
        s_rx_data   <= '1';
    elsif rising_edge(i_clk) then
        s_rx_data_d1 <= i_rx_serial;
        s_rx_data   <= s_rx_data_d1;
    end if;
end process sample_proc;
   
 
-- Purpose: Control RX state machine
uart_rx_proc : process (i_reset, i_clk)
begin
    if i_reset = '1' then
        s_rx_dv     <= '0';
        s_clk_count <= 0;
        s_bit_index <= 0;
        s_parity_cnt        <= (others => '0');
        s_rx_parity_err     <= '0';
        s_rx_byte <= (others => '0');
        sm_uart_rx_state <= ST_IDLE;

    elsif rising_edge(i_Clk) then
        
        s_rx_parity_err <= '0';
       
        case sm_uart_rx_state is
 
            when ST_IDLE =>
                s_rx_dv         <= '0';
                s_clk_count     <= 0;
                s_bit_index     <= 0;
                s_parity_cnt    <= (others => '0');
                if s_rx_data = '0' then       -- Start bit detected
                    sm_uart_rx_state <= ST_RX_START_BIT;
                else
                    sm_uart_rx_state <= ST_IDLE;
                end if;
 
            -- Check middle of start bit to make sure it's still low
            when ST_RX_START_BIT =>
                if s_clk_count = (g_CLKS_PER_BIT-1)/2 then
                    if s_rx_data = '0' then
                        s_clk_count <= 0;  -- reset counter since we found the middle
                        sm_uart_rx_state   <= ST_RX_DATA_BITS;

                    else
                        sm_uart_rx_state   <= ST_IDLE;
                    end if;
                else
                    s_clk_count <= s_clk_count + 1;
                    sm_uart_rx_state   <= ST_RX_START_BIT;
                end if;
            
            -- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
            when ST_RX_DATA_BITS =>
                if s_clk_count < g_CLKS_PER_BIT-1 then
                    s_clk_count <= s_clk_count + 1;
                    sm_uart_rx_state   <= ST_RX_DATA_BITS;
                else
                    s_clk_count            <= 0;
                    s_rx_byte(s_bit_index) <= s_rx_data;
                    if s_rx_data = '1' then 
                        s_parity_cnt <= s_parity_cnt + 1;
                    end if;
                    -- Check if we have sent out all bits
                    if s_bit_index < 7 then
                        s_bit_index <= s_bit_index + 1;
                        sm_uart_rx_state   <= ST_RX_DATA_BITS;

                    else
                        s_bit_index <= 0;
                        if C_PARITY_CTRL = 0 then  --no parity case
                            sm_uart_rx_state   <= ST_RX_STOP_BIT;
                        else
                            sm_uart_rx_state   <= ST_RX_PARITY_BIT;

                        end if;
                    end if;
                end if;

            -- Receive Stop bit.  Stop bit = 1
            when ST_RX_PARITY_BIT =>
                -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                if s_clk_count < g_CLKS_PER_BIT-1 then
                    s_clk_count <= s_clk_count + 1;
                    --sm_uart_rx_state   <= ST_RX_STOP_BIT;
                else
                    if s_rx_data = '1' then
                        s_parity_cnt    <= s_parity_cnt + 1;
                    end if;
                    s_clk_count     <= 0;
                    sm_uart_rx_state   <= ST_RX_STOP_BIT;

                end if;
    
            -- Receive Stop bit.  Stop bit = 1
            when ST_RX_STOP_BIT =>
                -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                if s_clk_count < g_CLKS_PER_BIT-1 then
                    s_clk_count <= s_clk_count + 1;
                    sm_uart_rx_state   <= ST_RX_STOP_BIT;
                    
                else
    
                    --s_rx_dv     <= '1';
                    s_clk_count <= 0;
                    if C_PARITY_CTRL > 0 then
                        sm_uart_rx_state   <= ST_RX_PARITY_CHK;

                    else
                        sm_uart_rx_state   <= ST_CLEAN_UP;
                    end if;
                end if;
            
            when ST_RX_PARITY_CHK => 
                if C_PARITY_CTRL = 2 then --evern parity
                    if s_parity_cnt(0) = '0' then  --Evern parity
                        s_rx_dv     <= '1';
                        s_rx_parity_err  <= '0';
                    else
                        s_rx_parity_err  <= '1';
                    end if;
                elsif C_PARITY_CTRL = 1 then    --Odd partiy case
                    if s_parity_cnt(0) = '0' then  
                        s_rx_dv     <= '1';
                        s_rx_parity_err  <= '1';
                    else
                        s_rx_parity_err  <= '0';
                    end if;
                end if;
                
                sm_uart_rx_state   <= ST_CLEAN_UP;
                
            -- Stay here 1 clock
            when ST_CLEAN_UP =>
                sm_uart_rx_state <= ST_IDLE;
                s_rx_dv   <= '0';
  
            when others =>
                sm_uart_rx_state <= ST_IDLE;
 
      end case;
    end if;
end process uart_rx_proc;
 
o_rx_dv             <= s_rx_dv;
o_rx_byte           <= s_rx_byte;
o_rx_parity_err     <= s_rx_parity_err;
   
end rtl;