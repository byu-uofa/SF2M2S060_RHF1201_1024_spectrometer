-- ----------------------------------------------------------------------------
--              : Copyright (C) 2019 COM DEV International. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV International prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : cmn_cntr.vhd
--              :
-- Project      : SMILE
-- Author       : Muhammad Amjad
-- Created      : Sep 18, 2019
--
-- Description  : Counts number input Ticks, I is used by several blcoks of SMILE UVI-C FPGA
--
-- SVN keywords : $Rev: 59 $
--                $Author: mamjad $
--                $Date: 2019-09-18 14:20:35 -0400 (Wed, 18 Sep 2019) $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M. Amjad           | Sep 18, 2019  |    Initial Creation
--          
-- -----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity cmn_cntr is
  generic(
    COUNTR_WIDTH         : integer:=32
    );
  port(
    --clk and reset
    i_reset                 : in  std_logic;
    i_clk                   : in  std_logic;
    
    -- PCB interface
   --pcb_m_in            : in PCB_MASTER_IN_T;
   --pcb_m_out           : out PCB_MASTER_OUT_T;
    
    --Counter Inputs
    i_cntr_en               : in std_logic;  --when high enables counter.
    i_cntr_tick             : in std_logic;  --one clock pulse will increment couner by one
    i_cntr_reset            : in std_logic;  --force the counte to zros values
         
    --Counter Outputs
    o_cntr_out              : out std_logic_vector(COUNTR_WIDTH-1 downto 0);
    o_cntr_overflow         : out std_logic  
    );
end cmn_cntr;

-- ----------------------------------------------------------------------------- 
architecture rtl of cmn_cntr is

 signal s_cntr_out          : unsigned(COUNTR_WIDTH downto 0);
 signal s_cntr_overflow     : std_logic;
   
begin
--------------------------------------------------------
-- Counter process
--------------------------------------------------------
  
cntr_proc: process (i_reset, i_clk)
begin
    if i_reset = '1' then
        s_cntr_overflow <= '0';
        s_cntr_out      <= (others => '0');
        
    elsif rising_edge(i_clk) then
        if i_cntr_en ='1' then
            if i_cntr_tick = '1' then
                s_cntr_out <= s_cntr_out + 1;
            elsif i_cntr_reset = '1' then
                s_cntr_out  <= (others => '0');
            end if;
        end if;
        
        s_cntr_overflow <= '0';
        if s_cntr_out(COUNTR_WIDTH) = '1' then
            s_cntr_overflow <= '1';
        end if;
    end if;
end process;

o_cntr_out      <= std_logic_vector(s_cntr_out(COUNTR_WIDTH-1 downto 0));
o_cntr_overflow <= s_cntr_overflow;
 
--------------------------------------------------------------------------------
end rtl;