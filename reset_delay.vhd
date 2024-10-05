-------------------------------------------------------------------------
--              : Copyright (C) 2009 COM DEV Europe Limited. All rights
--              : reserved. Use is subject to COM DEV Europe Limited's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV Europe Limited's prior written consent.
--              :
-- Revision     : 1.1
--              :
-- File name    : reset_delay.vhd
--              :
-- Library      : rcm_lib
--              :
-- Purpose      : Reset Delay Circuitry
--              :
-- Created On   : 17 August 2010
--
--              :
-- Notes        : The removal of the internal reset is synchronised
--              : to the rising edge of the clock
--              :
-- SVN keywords : $Rev$
--                $Author$
--                $Date$
-- ----------------------------------------------------------------------
-- Revision History :
-- ----------------------------------------------------------------------
--   Ver  :| Author            :| Mod. Date :|    Changes Made:
--   v1.0  | Stephane Forey    :| 08/17/2011:| Initial Release
--   v1.1  | A. Nash            | 05/02/2013 | Modified for async. set,
--         |                    |            | sync. clear
--   v1.2  | M. Amjad           | 10/08/2019 | Modified SMILE project: removed snyplify lib declaration
-- ----------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_STD.all;


--library synplify;
--use synplify.attributes.all;

-------------------------------------------------------------
-- Entity: reset_delay
-------------------------------------------------------------

entity reset_delay is
    generic (
        RESET_IN_POLARITY   : std_logic := '0';
        RESET_OUT_POLARITY  : std_logic := '1';
        DELAY               : integer := 80    -- Reset delay in clock cycles        
    );
    port (        
        clk                 : in std_logic;
        RST_in              : in std_logic;  -- External Power-On Reset        
        RST_out             : out std_logic;  -- Output internal Reset
        i_msc_soft_reset    : in std_logic
    );
end reset_delay;


-------------------------------------------------------------
-- Architecture: reset_delay
-------------------------------------------------------------

architecture rtl of reset_delay is

--------------- Signals ---------------     
signal delay_line : std_logic_vector(DELAY downto 0) := (others=>not RESET_OUT_POLARITY);
signal delay_cnt  : std_logic_vector(6 downto 0):=(others=>'0');
signal Reset_on   : std_logic := '0';
-- -------------------------------------------------------------
-- TMR Attributes
-- -------------------------------------------------------------
--    -- TMR applied to mitigate the SEU effects on reset circuit
--    attribute syn_radhardlevel of
--    rtl: architecture is "tmr";
    
begin  -- rtl   
    
    delay_line(0) <= not RESET_OUT_POLARITY;

    
    -- Reset Delay Process
    --
    reset_proc : process (clk, RST_in)
    begin
        if ( RST_in = RESET_IN_POLARITY ) then
            delay_line(DELAY downto 1) <= (others => RESET_OUT_POLARITY);
            RST_out <= RESET_OUT_POLARITY;
        elsif rising_edge(clk) then
            if(Reset_on = '0') then
               for n in DELAY downto 1 loop
                    delay_line(n) <= delay_line(n-1);
               end loop;
               RST_out <= delay_line(DELAY);
            else
               RST_out <= RESET_OUT_POLARITY;
               
            end if;
        end if;
    end process;
    
    msc_reset_dec_proc : process (clk)
    begin

        if rising_edge(clk) then
            if(i_msc_soft_reset = '1' or delay_cnt > 0 ) then
                if(delay_cnt < 80) then
                    delay_cnt <= delay_cnt + '1';
                    Reset_on <= '1';
                else
                    delay_cnt <= (others => '0');
                    Reset_on <= '0';
                end if;
            end if;
        end if;
    end process;

end rtl;

