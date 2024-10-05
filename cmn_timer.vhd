-- ----------------------------------------------------------------------------
--              : Copyright (C) 2019 COM DEV International. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV International prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : cmn_timer.vhd
--              :
-- Project      : SMILE 
-- Author       : Muhammad Amjad
-- Created      : Aug 26, 2019
--
-- Description  : commnad block, genertes several time ticks for use by other blocks
--              : eg. 1usec, 10 uSec 100 uSec and 1 mSec ticks
--
-- SVN keywords : $Rev: 47 $
--                $Author: mamjad $
--                $Date: 2019-09-04 16:17:01 -0400 (Wed, 04 Sep 2019) $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M. Amjad           | Aug 26, 2019  |    Initial Creation, imported code form RCM project
--     20221018  
-- -----------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.p_swept_pkg.all;


entity cmn_timer is
    generic (CLK_FREQ_MHZ : integer:=100
        );
    port (
         clk          : in  std_logic;
         rst          : in  std_logic;
         strobes      : out strobe_t
        );
end entity cmn_timer;


architecture rtl of cmn_timer is
attribute syn_preserve : boolean;
attribute syn_preserve of rtl: architecture is true;
 ---------------------------------------------------------------------
 -- CONSTANTS DECLARATION
 ---------------------------------------------------------------------
 constant TIME_1US_CNT    : integer := CLK_FREQ_MHZ;
 constant VAL_100US_COUNT : integer := 99;
 constant VAL_1MS_COUNT   : integer := 999;
 constant VAL_10MS_COUNT  : integer := 9999;
 constant VAL_100MS_COUNT : integer := 99999;
 constant VAL_1SEC_COUNT  : integer := 999999;

 ---------------------------------------------------------------------
 -- SIGNALS DECLARATION
 ---------------------------------------------------------------------
 signal counter_1us      : integer range 0 to (TIME_1US_CNT - 1);
 signal counter_100us    : integer range 0 to VAL_100US_COUNT;
 signal counter_1ms      : integer range 0 to VAL_1MS_COUNT  ;
 signal counter_10ms     : integer range 0 to VAL_10MS_COUNT ;
 signal counter_100ms    : integer range 0 to VAL_100MS_COUNT;
 signal counter_1sec     : integer range 0 to VAL_1SEC_COUNT ;

begin


----------------------------------------------------------
-- 1us strobe generation.
----------------------------------------------------------
 timer_1us : process (clk,rst)
 begin
    if (rst = '1') then
        strobes.strobe_1us <= '0';
        counter_1us <= 0;
    elsif rising_edge(clk) then
        strobes.strobe_1us <= '0';

        if (counter_1us = (TIME_1US_CNT - 1)) then
            counter_1us <= 0;
            strobes.strobe_1us  <= '1';
        else
            counter_1us <= counter_1us + 1;
        end if;

    end if;
 end process timer_1us;
-- Assign strobe output for 1us timer.
-- strobes.strobe_1us <= '1' when (counter_1us = (TIME_1US_CNT - 1)) else '0';

----------------------------------------------------------
-- 100us strobe generation.
----------------------------------------------------------
 timer_100us : process (clk,rst)
 begin
    if (rst = '1') then
        strobes.strobe_100us <= '0';
        counter_100us <= 0;
    elsif rising_edge(clk) then
        strobes.strobe_100us <= '0';

        if (counter_1us = (TIME_1US_CNT - 1)) then
            if (counter_100us = VAL_100US_COUNT) then
                counter_100us <= 0;
                strobes.strobe_100us <= '1';
            else
                counter_100us <= counter_100us + 1;
            end if;
        end if;
    end if;
 end process timer_100us;
-- Assign strobe output for 100us timer.
-- strobes.strobe_100us <= '1' when ((counter_100us = VAL_100US_COUNT) AND
                        -- (counter_1us = (TIME_1US_CNT - 1)))  else '0';

----------------------------------------------------------
-- 1ms strobe generation.
----------------------------------------------------------
 timer_1ms : process (clk,rst)
 begin
    if (rst = '1') then
        strobes.strobe_1ms <= '0';
        counter_1ms <= 0;
    elsif rising_edge(clk) then
        strobes.strobe_1ms <= '0';

        if (counter_1us = (TIME_1US_CNT - 1)) then
            if (counter_1ms = VAL_1MS_COUNT) then
                counter_1ms <= 0;
                strobes.strobe_1ms <= '1';
            else
                counter_1ms <= counter_1ms + 1;
            end if;
        end if;
    end if;
 end process timer_1ms;
-- Assign strobe output for 1ms timer.
-- strobes.strobe_1ms <= '1' when ((counter_1ms = VAL_1MS_COUNT) AND
                        -- (counter_1us = (TIME_1US_CNT - 1)))  else '0';

----------------------------------------------------------
-- 10ms strobe generation.
----------------------------------------------------------
 timer_10ms : process (clk,rst)
 begin
    if (rst = '1') then
        counter_10ms <= 0;
        strobes.strobe_10ms <= '0';
    elsif rising_edge(clk) then
        strobes.strobe_10ms <= '0';

        if (counter_1us = (TIME_1US_CNT - 1)) then
            if (counter_10ms = VAL_10MS_COUNT) then
               counter_10ms <= 0;
                strobes.strobe_10ms <= '1';
            else
               counter_10ms <= counter_10ms + 1;
            end if;
        end if;

    end if;
 end process timer_10ms;
-- Assign strobe output for 10ms timer.
-- strobes.strobe_10ms <= '1' when ((counter_10ms = VAL_10MS_COUNT) AND
                        -- (counter_1us = (TIME_1US_CNT - 1)))  else '0';

----------------------------------------------------------
-- 100ms strobe generation.
----------------------------------------------------------
 timer_100ms : process (clk,rst)
 begin
    if (rst = '1') then
        counter_100ms <= 0;
        strobes.strobe_100ms <= '0';       
    elsif rising_edge(clk) then
        strobes.strobe_100ms <= '0';

        if (counter_1us = (TIME_1US_CNT - 1)) then
            if (counter_100ms = VAL_100MS_COUNT) then
                counter_100ms <= 0;
                strobes.strobe_100ms <= '1';
            else
                counter_100ms <= counter_100ms + 1;
            end if;
        end if;

    end if;
 end process timer_100ms;
   -- Assign strobe output for 100ms timer.
   -- strobes.strobe_100ms <= '1' when ((counter_100ms = VAL_100MS_COUNT) AND
                           -- (counter_1us = (TIME_1US_CNT - 1)))  else '0';

----------------------------------------------------------
-- 1sec strobe generation.
----------------------------------------------------------
 timer_1sec : process (clk,rst)
 begin
  if (rst = '1') then
      strobes.strobe_1sec <= '0';
      counter_1sec <= 0;

  elsif rising_edge(clk) then
      strobes.strobe_1sec <= '0';

      if (counter_1us = (TIME_1US_CNT - 1)) then
          if (counter_1sec = VAL_1SEC_COUNT) then
              counter_1sec <= 0;
              strobes.strobe_1sec <= '1';
          else
              counter_1sec <= counter_1sec + 1;
          end if;
      end if;

  end if;
 end process timer_1sec;
   -- Assign strobe output for 1sec timer.
   -- strobes.strobe_1sec <= '1' when ((counter_1sec = VAL_1SEC_COUNT) AND
                           -- (counter_1us = (TIME_1US_CNT - 1)))  else '0';

end architecture;