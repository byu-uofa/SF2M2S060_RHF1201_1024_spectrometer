-- ----------------------------------------------------------------------------
--              : Copyright (C) 2019 Honeywell. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to Honeywell prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : p_swept_cmd_pkg.vhd 
--              :
-- Project      : SMILE
-- Author       : Muhammad Amjad
-- Created      : Jun 120, 2022
--
-- Description  : UVIC Commands declaration Package
--
-- SVN keywords : $Rev: $
--                $Author: $
--                $Date:  $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M Amjad            | Jun 12, 2022  |    Initial Creation, 

-- -----------------------------------------------------------------------------
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package p_swept_cmds_pkg is

-- -------------------------------------------------------------------
-- UVIC command definitions 
-- -------------------------------------------------------------------

constant CMD_NO_OP                  : std_logic_vector(7 downto 0):= x"01";     --Only generates a command a ccept response (if valid) (TBD).
constant CMD_RD_REG                 : std_logic_vector(7 downto 0):= x"02";     --Read Register
                                                                                --0xXXXX	0xnnnnnnnn	Read addressed register. (this command will never be used in operations, it is meant for development purpose only).
constant CMD_WR_REG                 : std_logic_vector(7 downto 0):= x"03";     --0xXXXX	0xnnnnXXXX	Write given value to the addressed register (this command will never be used in SMILE operations, it is development purpose only).
constant RESERVED_1                 : std_logic_vector(7 downto 0):= x"04";
constant RESERVED_2_X               : std_logic_vector(7 downto 0):= x"0F";

constant CMD_DDR4_DUMP_CH1          : std_logic_vector(7 downto 0):= x"04";  
constant CMD_DDR4_DUMP_CH2          : std_logic_vector(7 downto 0):= x"05";  
constant CMD_DDR4_DUMP_CH3          : std_logic_vector(7 downto 0):= x"06";  
constant CMD_DDR4_DUMP_CH4          : std_logic_vector(7 downto 0):= x"07";  
constant CMD_DDR4_DUMP_ALL        	: std_logic_vector(7 downto 0):= x"08";     

constant CMD_DDR4_WRITE       		: std_logic_vector(7 downto 0):= x"13";     --Prime Sensor Temp Control loop disable (0x0002)   
                                                                                


end package;
--------------------------------------------------------------------------------

package body p_swept_cmds_pkg is

    
--------------------------------------------------------------------------------
 end package body;
 --------------------------------------------------------------------------------