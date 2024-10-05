-- ----------------------------------------------------------------------------
--              : Copyright (C) 2018 COM DEV International. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV International prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : uart_tx.vhd
--              :
-- Project      : UVI ROE 
-- Author       : Muhammad Amjad
-- Created      : Apr 16, 2018
--
-- Description  : -- This file contains the UART Transmitter.  This transmitter is able
--                  to transmit 8 bits of serial data, one start bit, one stop bit,
--                  and optional parity bit.  When transmit is complete o_TX_Done will be
--                  driven high for one clock cycle.When receive is complete o_rx_dv will be
--                  driven high for one clock cycle.
--
--                  Set Generic g_CLKS_PER_BIT as follows:
--                  g_CLKS_PER_BIT = (Frequency of i_Clk)/(Frequency of UART)
--                  Example: 10 MHz Clock, 115200 baud UART
--                  (10000000)/(115200) = 87
--
-- SVN keywords : $Rev: 350 $
--                $Author: mamjad $
--                $Date: 2020-05-25 15:30:29 -0400 (Mon, 25 May 2020) $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M Amjad            | Apr 16, 2018  |    Initial Creation            
--   v0.2  | M Amjad            | May 12, 2018  |    Added even parity bit in the Tx byte
-- -----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity UART_TX is
  generic (
    g_CLKS_PER_BIT  : integer := 868;    -- 100MHz 868 clocks per bit for 115200 Baud rate
    g_PARIY         : integer := 2;      -- Parity (Valid Values: 0=No Parity, 1=Odd Parity, 2=Even parity)
    g_STOP_BITS     : integer := 1       -- Number of stop bits (valid values are 1 or 2)
    );
  port (
    i_Reset        : in  std_logic;
    i_Clk          : in  std_logic;
    i_TX_DV_TLM    : in  std_logic;
    i_tx_byte_tlm  : in  std_logic_vector(7 downto 0);
    i_TX_DV_CMD    : in  std_logic;
    i_tx_byte_cmd  : in  std_logic_vector(7 downto 0);

    --i_TX_DV        : in  std_logic;
    --i_TX_Byte      : in  std_logic_vector(7 downto 0);
    o_TX_Active    : out std_logic;
    o_TX_Serial    : out std_logic;
    o_TX_Done      : out std_logic
    );
end UART_TX;
 
 
architecture rtl of UART_TX is
 
  type t_sm_main_state_type is (ST_IDLE, ST_TX_START_BIT, ST_TX_DATA_BITS,
                     ST_TX_PARITY_BIT, ST_TX_STOP_BIT, ST_CLEAN_UP);
  signal sm_main_state : t_sm_main_state_type;
  constant C_PARITY_CTRL    : integer range 0 to 2 := g_PARIY;
  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0;  -- 8 Bits Total
  signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_TX_Done   : std_logic := '0';
  signal s_parity_cnt: unsigned(3 downto 0);
  
begin
 
-- Purpose: to send out data in format: 1 Start bit, 8 Data bits, and 1 Stop bit   
  p_UART_TX : process (i_Reset, i_Clk)
  begin
    if i_Reset = '1' then
      o_TX_Active <= '0';
      o_TX_Serial <= '1'; -- Drive Line High for Idle
      r_TX_Done <= '0';
      r_Clk_Count <= 0;
      r_Bit_Index <= 0;
      r_TX_Data <= (others => '0');
      sm_main_state <= ST_IDLE;
      
    elsif rising_edge(i_Clk) then
         
        case sm_main_state is
 
            when ST_IDLE =>
                o_TX_Active <= '0';
                o_TX_Serial <= '1'; -- Drive Line High for Idle
                r_TX_Done <= '0';
                r_Clk_Count <= 0;
                r_Bit_Index <= 0;
                s_parity_cnt <= (others => '0');
 
                if i_TX_DV_TLM = '1' then
                    r_TX_Data <= i_tx_byte_tlm;
                    if i_tx_byte_tlm(0) = '1' then
                        s_parity_cnt  <= s_parity_cnt + 1;
                    end if;
                    sm_main_state <= ST_TX_START_BIT;
                elsif i_TX_DV_CMD = '1' then
                    r_TX_Data <= i_tx_byte_cmd;
                    if i_tx_byte_cmd(0) = '1' then
                        s_parity_cnt  <= s_parity_cnt + 1;
                    end if;

                    sm_main_state <= ST_TX_START_BIT;     
                else
                    sm_main_state <= ST_IDLE;
                end if;
 
            -- Send out Start Bit. Start bit = 0
            when ST_TX_START_BIT =>
                o_TX_Active <= '1';
                o_TX_Serial <= '0';
 
                -- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
                if r_Clk_Count < g_CLKS_PER_BIT-1 then
                    r_Clk_Count <= r_Clk_Count + 1;
                    sm_main_state   <= ST_TX_START_BIT;
                else
                    r_Clk_Count <= 0;
                    sm_main_state   <= ST_TX_DATA_BITS;
                end if;
 
            -- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish
            when ST_TX_DATA_BITS =>
                o_TX_Serial <= r_TX_Data(r_Bit_Index);
           
                if r_Clk_Count < g_CLKS_PER_BIT-1 then
                    r_Clk_Count <= r_Clk_Count + 1;
                    sm_main_state   <= ST_TX_DATA_BITS;
                else
                    r_Clk_Count <= 0;
                    -- Check if we have sent out all bits
                    if r_Bit_Index < 7 then
                        r_Bit_Index <= r_Bit_Index + 1;
              
                        if r_TX_Data(r_Bit_Index+1) = '1' then
                            s_parity_cnt <= s_parity_cnt + 1;
                        end if;
                        sm_main_state   <= ST_TX_DATA_BITS;
                    else
                        r_Bit_Index <= 0;
                        if C_PARITY_CTRL /= 0 then  
                            sm_main_state   <= ST_TX_PARITY_BIT;
                        else
                            sm_main_state   <= ST_TX_STOP_BIT;
                        end if;
                    end if;
                end if;
 
            when ST_TX_PARITY_BIT =>
                if C_PARITY_CTRL = 2 then  
                    if s_parity_cnt(0) = '0' then  --even parity
                        o_TX_Serial <= '0';
                    else
                        o_TX_Serial <= '1';
                    end if;
                else 
                    if s_parity_cnt(0) = '0' then  --Odd parity
                        o_TX_Serial <= '1';
                    else
                        o_TX_Serial <= '0';
                    end if;
                end if;
                
                if r_Clk_Count < g_CLKS_PER_BIT-1 then
                    r_Clk_Count <= r_Clk_Count + 1; 
                else
                    r_Clk_Count <= 0;
                    sm_main_state   <= ST_TX_STOP_BIT;
                end if;

                -- Send out Stop bit.  Stop bit = 1
            when ST_TX_STOP_BIT =>
                o_TX_Serial <= '1';
 
                -- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
                if r_Clk_Count < g_CLKS_PER_BIT-1 then
                    r_Clk_Count <= r_Clk_Count + 1;
                    sm_main_state   <= ST_TX_STOP_BIT;
                else
                    r_TX_Done   <= '0';
                    r_Clk_Count <= 0;
                    sm_main_state   <= ST_CLEAN_UP;
                end if;
 
                   
            -- Stay here 1 clock
            when ST_CLEAN_UP =>
                o_TX_Active <= '0';

                r_TX_Done   <= '1';
                sm_main_state   <= ST_IDLE;
           
             
            when others =>
                sm_main_state <= ST_IDLE;
 
      end case;
    end if;
  end process p_UART_TX;
 
  o_TX_Done <= r_TX_Done;
   
end rtl;