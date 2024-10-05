-- ----------------------------------------------------------------------------
--              : Copyright (C) 2019 Honeywell. and University of Alberta All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to Honeywell and University of Alberta prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : p_swept_pkg.vhd 
--              :
-- Project      : P_SWEPT
-- Author       : Muhammad Amjad
-- Created      : Jun 12, 2019
--
-- Description  : P-SWEPT FPGA Package
--
-- SVN keywords : $Rev: 368 $
--                $Author: mamjad $
--                $Date: 2020-11-05 22:56:30 -0500 (Thu, 05 Nov 2020) $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M Amjad            | Jun 12, 2022  |    Initial Creation
--   v0.2  | B Yu            | July 5, 2022    |     More registers creation and initial value configuations
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------------------
-- Package: p_swept_fpga_pkg
--------------------------------------------------------------------------------

package p_swept_pkg is


 -- Timer strobes record
type strobe_t is record
     strobe_1us       : std_logic;
     strobe_100us     : std_logic;
     strobe_1ms       : std_logic;
     strobe_10ms      : std_logic;
     strobe_100ms     : std_logic;
     strobe_1sec      : std_logic;
end record strobe_t;

-- -- --------------------------------------------------------------------------
-- -- DECLARATION for Control bus 
-- -- --------------------------------------------------------------------------
  constant PCB_REG_WIDTH           : integer := 32;
  constant PCB_ADDR_WIDTH          : integer := 16;
  --constant PCB_PSEL_WIDTH          : integer := 13;  -- = max number of peripherals (one device per line)
  --constant PCB_PERIPH_ID_WIDTH     : integer := 4;  -- = LOG2(PCB_PSEL_WIDTH)
  
    
    function one_hot_to_binary (one_Hot : std_logic_vector ;
                                size    : natural ) return std_logic_vector;

    
    function or_reduce(data :in std_logic_vector) return  std_logic;
    function xor_reduce(word : in std_logic_vector) return std_logic;
    
    --type T_PCB_PEPH_ID_TYP  is array (natural range <> ) of std_logic_vector(PCB_PERIPH_ID_WIDTH-1 downto 0);   
    type T_PCB_ADDR_TYP     is array (natural range <> ) of std_logic_vector(PCB_ADDR_WIDTH-1 downto 0);
    type T_PCB_DATA_TYP     is array (natural range <> ) of std_logic_vector(PCB_REG_WIDTH-1 downto 0);
    --type T_TLM_PKT_TYP      is array (natural range <> ) of std_logic_vector(7 downto 0);
-- -----------------------------------------------------------------------------
-- Original definitions on periph_ctrl_bus_pkg with new values
-- -----------------------------------------------------------------------------
  constant C_CMD_PKT_LENGTH                 : integer := 10;  --bytes
  constant C_UART_FSM_WDOG_CNT_MAX          : integer := 3;   
  
  constant C_GOOD_PKT_CNTR_WIDTH            : integer := 16;
  constant C_ERROR_PKT_CNTR_WIDTH           : integer := 8;
  constant C_ELAPSE_TIME_CNTR_WIDTH         : integer := 32;
  constant C_PINPULLER_TIME_CNTR_WIDTH      : integer := 20; -- max 5min=300000 mse(or 0x493E0 msec)
  constant C_TOTAL_EXPOSURE_CNTR_WIDTH      : integer := 16;
  constant C_SERIES_EXPOSURE_CNTR_WIDTH     : integer := 16;
  constant C_CURRENT_EXPOSURE_CNTR_WIDTH    : integer := 16;
  constant C_CURRENT_GROUP_NUM_CNTR_WIDTH   : integer := 16;
  constant C_TOTAL_FRM_DROP_CNTR_WIDTH      : integer := 32;
  constant C_IMAGING_SKIP_FRM_CNTR_WIDTH    : integer := 16;
  constant C_UART_RX_PARITY_ERR_CNTR_WIDTH  : integer := 16;
  
  ---- Type definitions
  subtype PCB_REG_T is std_logic_vector(PCB_REG_WIDTH-1 downto 0);
  --subtype PCB_ADDR_T is std_logic_vector(PCB_ADDR_WIDTH-1 downto 0);
 -- subtype PCB_PSEL_T is std_logic_vector(PCB_PSEL_WIDTH-1 downto 0);
  type CTRL_REGS_T is array (0 to 23) of PCB_REG_T;

  type T_DDR4_BURST_DATA_TYPE is array (0 to 7) of std_logic_vector(31 downto 0);
  type T_DDR4_BURST_FRM_PTR_TYPE  is array (0 to 7) of std_logic_vector(7 downto 0);
  -- Common bus signals routed from the master to all slaves
  --type PCB_COMMON_T is record
  --    pce        : std_logic;
  --    pwr_data   : PCB_REG_T;
  --    paddr      : PCB_ADDR_T;
  --    pwr_n      : std_logic; -- to set read('1') or write('0') operation
  --end record;    
  
  --type PCB_SLAVE_IN_T is record
  --    common     : PCB_COMMON_T;
  --    psel       : std_logic;
  --end record;

  --type PCB_SLAVE_OUT_T is record
  --    prd_data   : PCB_REG_T;
  --    pint       : std_logic;
  --end record;

  --type PCB_MASTER_OUT_T is record
  --    common     : PCB_COMMON_T;
  --    psel       : PCB_PSEL_T;
  --end record;
  --
  --type PCB_MASTER_IN_T is record
  --    prd_data   : CTRL_REGS_T(0 to PCB_PSEL_WIDTH-1);
  --    pint       : PCB_PSEL_T;
  --end record;
      

      
  -- -----------------------------------------------------------------------------
  -- UVIC Peripheral Bus IDs
  -- -----------------------------------------------------------------------------
 --constant MASTERFSM_PID          : integer := 0;
 --constant STAR1000_PID           : integer := 1;
 --constant MEM_CTRLR_IF_PID       : integer := 2;
 --constant BOD_LOGIC_PID          : integer := 3;
 --constant TEMP_CTRLR_PID         : integer := 4;
 --constant EXPO_CTRL_PID          : integer := 5;
 --constant BINNING_CTRL_PID       : integer := 6;
 --constant SCI_PKT_GEN_PID        : integer := 7;
 --constant SYNC_IF_CTRL_PID       : integer := 8;
 --constant SYS_MON_PID            : integer := 9;
 --constant TLM_PKT_GEN_PID        : integer := 10;
 --constant PINPULLER_PID          : integer := 11;
 --constant DDR2_CTRLR_PID         : integer := 12;
 constant 	NibbleSize				: integer := 4;
-- -----------------------------------------------------------------------------
-- CONSTANTS DECLARATION for IMAGE FRAMES
-- -----------------------------------------------------------------------------  
 --constant BIT_START_OF_LN       : integer:= 24;
 --constant BIT_END_OF_LN         : integer:= 25;
 --constant BIT_START_OF_FRM      : integer:= 26;
 --constant BIT_END_OF_FRM        : integer:= 27;
 --constant BIT_CAL_FRM           : integer:= 28;
-- -----------------------------------------------------------------------------
--Top level registrs of Mastter FSM
-- -----------------------------------------------------------------------------
constant P_SWEPT_FPGA_BUILD_VER_REG        	: integer := 0;
constant P_SWEPT_FPGA_BUILD_DAY_REG        	: integer := 1;
constant P_SWEPT_FPGA_BUILD_MONTH_REG      	: integer := 2;
constant P_SWEPT_FPGA_BUILD_YEAR_REG       	: integer := 3;
constant P_SWEPT_FPGA_THRESHOLD_CH1_REG		: integer := 4;
constant P_SWEPT_FPGA_THRESHOLD_CH2_REG		: integer := 5;
constant P_SWEPT_FPGA_THRESHOLD_CH3_REG		: integer := 6;
constant P_SWEPT_FPGA_THRESHOLD_CH4_REG		: integer := 7;
constant P_SWEPT_DUMP_ALL_REG       	    : integer := 8;
constant P_SWEPT_CMD_REJECT_CNTR_REG        : integer := 9;
constant P_SWEPT_URX_PARITY_ERR_CNTR_REG    : integer := 10;
constant P_SWEPT_DUMP_CH1_REG   	        : integer := 11;
constant P_SWEPT_DUMP_CH2_REG   	        : integer := 12;
constant P_SWEPT_PEAK_THD_REG   	        : integer := 13;
constant P_SWEPT_PEAK_THD_POS_REG   	    : integer := 14;
constant P_SWEPT_DR1_REG   	                : integer := 15;
constant P_SWEPT_DR2_REG   	                : integer := 16;
constant P_SWEPT_DR3_REG   	                : integer := 17;
constant P_SWEPT_DR4_REG   	                : integer := 18;
constant P_SWEPT_DUMP_PEAK1_REG   	        : integer := 19;
constant P_SWEPT_DUMP_PEAK2_REG   	        : integer := 20;
constant P_SWEPT_RESET                      : integer := 21;
constant RADICAL_MTIME_PRESET_VALUE         : integer := 22;
constant RADICAL_MTIME_START_CTRL_REG       : integer := 23;

-- -----------------------------------------------------------------------------
-- CONSTANTS DECLARATION for STAR1000 module
-- -----------------------------------------------------------------------------
 
 constant STAR1000_ADDR_WIDTH     : integer := 10;
 constant UVI_ROE_REG_WIDTH       : integer := 16;
 --

 subtype  BITS_BIN_CTRL_RANGE  is integer range 1 downto 0;
 subtype  BITS_DATA_REDUC_RANGE is integer range 4 downto 0;
 subtype  BITS_BIN_STAT_REG_RANGE is integer range 3 downto 0;
 

 
 --
 constant MASTER_FSM_DEFAULT_REG_VALUES    : CTRL_REGS_T :=(
                                                                          x"00000000",    --  P_SWEPT_FPGA_BUILD_VER_REG     
                                                                          x"00000000",    --  P_SWEPT_FPGA_BUILD_DAY_REG     
                                                                          x"00000000",    --  P_SWEPT_FPGA_BUILD_MONTH_REG   
                                                                          x"00000000",    --  P_SWEPT_FPGA_BUILD_YEAR_REG    
                                                                          x"00000000",    --  P_SWEPT_FPGA_THRESHOLD_CH1_REG	
																		  x"00000000",    --  P_SWEPT_FPGA_THRESHOLD_CH2_REG	
																		  x"00000000",    --  P_SWEPT_FPGA_THRESHOLD_CH3_REG	
																		  x"00000000",    --  P_SWEPT_FPGA_THRESHOLD_CH4_REG	   
																		  x"00000000",    --  P_SWEPT_DUMP_ALL_REG       	
                                                                          x"00000000",    --  P_SWEPT_CMD_REJECT_CNTR_REG         
																		  x"00000000",    --  P_SWEPT_URX_PARITY_ERR_CNTR_REG
																		  x"00000000",    --  P_SWEPT_DUMP_CH1_REG   	    
                                                                          x"00000000",    --  P_SWEPT_DUMP_CH2_REG   	     	    
                                                                          x"000007FA",    --  P_SWEPT_PEAK_THD_REG   	    
                                                                          x"000007FA",    --  P_SWEPT_PEAK_THD_POS_REG   	
                                                                          x"00000000",    --  P_SWEPT_DR1_REG   	            
                                                                          x"00000000",    --  P_SWEPT_DR2_REG   	            
                                                                          x"00000000",    --  P_SWEPT_DR3_REG   	            
                                                                          x"00000000",    --  P_SWEPT_DR4_REG   	                  
                                                                          x"00000000",    --  P_SWEPT_DUMP_PEAK1_REG   	    
                                                                          x"00000000",    --  P_SWEPT_DUMP_PEAK2_REG   	    
                                                                          x"00000000",    --  P_SWEPT_RESET                  
                                                                          x"000003E8",    --  RADICAL_MTIME_PRESET_VALUE    default value = 10s => A        
                                                                          x"00000000"     --  RADICAL_MTIME_START_CTRL_REG                                                         
                                                                        ); /* synthesis preserve=1*/
                                    
-- -------------------------------------------------------------
-- CONSTANTS DECLARATION for UART IF module
-- -------------------------------------------------------------
                             
 constant C_UART_CLKS_PER_BIT        : integer:=271; --UART baud rate 115.2kbps @ clock=31MHz. need 620us to receive a byte
 constant C_UART_CLKS_PER_BIT_SIM    : integer:=27;  --UART baud rate 1.152Mbps @ clock=3.1MHz. need 62us to send a byte out         
 
 
end package;

package body p_swept_pkg is

    function one_hot_to_binary (one_hot : std_logic_vector ;
                                size    : natural
        ) return std_logic_vector is
        variable vec : std_logic_vector(size-1 downto 0);
        begin
          vec := (others => '0');
          for i in one_hot'range loop
              if one_hot(i) = '1' then
                vec := vec or std_logic_vector(to_unsigned(i,size));
            end if;
          end loop;
          return vec;
        end function;  
    --
    function or_reduce(data :in std_logic_vector) return  std_logic is
        variable Temp : std_logic:= '0';
        begin  
        for i in Data'range loop
         Temp := Temp or Data(i);
        end loop;
        return Temp;
    end function or_reduce;
    --
    function xor_reduce(word : in std_logic_vector) return std_logic is
        variable temp : std_logic := '0';
        begin
            for i in word'range loop
                temp := temp xor word(i);
            end loop;
            return temp;
    end function xor_reduce;
    
    
 end package body;