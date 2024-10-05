----------------------------------------------------------------------
-- Created by SmartDesign Wed Nov 29 12:40:35 2023
-- Version: 2023.1 2023.1.0.6
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Component Description (Tcl) 
----------------------------------------------------------------------
--# Exporting Component Description of adc_data_fifo to TCL
--# Family: SmartFusion2
--# Part Number: M2S060-1FG484I
--# Create and Configure the core component adc_data_fifo
--create_and_configure_core -core_vlnv {Actel:DirectCore:COREFIFO:3.0.101} -component_name {adc_data_fifo} -params {\
--"AE_STATIC_EN:false"  \
--"AEVAL:4"  \
--"AF_STATIC_EN:false"  \
--"AFVAL:1020"  \
--"CTRL_TYPE:2"  \
--"DIE_SIZE:20"  \
--"ECC:0"  \
--"ESTOP:true"  \
--"FSTOP:true"  \
--"FWFT:false"  \
--"NUM_STAGES:2"  \
--"OVERFLOW_EN:false"  \
--"PIPE:1"  \
--"PREFETCH:true"  \
--"RAM_OPT:0"  \
--"RDCNT_EN:false"  \
--"RDEPTH:500"  \
--"RE_POLARITY:0"  \
--"READ_DVALID:false"  \
--"RWIDTH:12"  \
--"SYNC:1"  \
--"SYNC_RESET:0"  \
--"UNDERFLOW_EN:false"  \
--"WDEPTH:500"  \
--"WE_POLARITY:0"  \
--"WRCNT_EN:false"  \
--"WRITE_ACK:false"  \
--"WWIDTH:12"   }
--# Exporting Component Description of adc_data_fifo to TCL done

----------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library smartfusion2;
use smartfusion2.all;
library COREFIFO_LIB;
use COREFIFO_LIB.all;
----------------------------------------------------------------------
-- adc_data_fifo entity declaration
----------------------------------------------------------------------
entity TB_adc_data_fifo is
    -- Port list
    port(
        -- Inputs
        CLK     : in  std_logic;
        DATA    : in  std_logic_vector(11 downto 0);
        RE      : in  std_logic;
        RESET_N : in  std_logic;
        WE      : in  std_logic;
        -- Outputs
        EMPTY   : out std_logic;
        FULL    : out std_logic;
        Q       : out std_logic_vector(11 downto 0)
        );
end TB_adc_data_fifo;
----------------------------------------------------------------------
-- adc_data_fifo architecture body
----------------------------------------------------------------------
architecture RTL of TB_adc_data_fifo is
----------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------
-- adc_data_fifo_adc_data_fifo_0_COREFIFO   -   Actel:DirectCore:COREFIFO:3.0.101
component adc_data_fifo_adc_data_fifo_0_COREFIFO
    generic( 
        AE_STATIC_EN : integer := 0 ;
        AEVAL        : integer := 4 ;
        AF_STATIC_EN : integer := 0 ;
        AFVAL        : integer := 1020 ;
        CTRL_TYPE    : integer := 1 ;
        DIE_SIZE     : integer := 20 ;
        ECC          : integer := 0 ;
        ESTOP        : integer := 1 ;
        FAMILY       : integer := 19 ;
        FSTOP        : integer := 1 ;
        FWFT         : integer := 0 ;
        NUM_STAGES   : integer := 2 ;
        OVERFLOW_EN  : integer := 0 ;
        PIPE         : integer := 1 ;
        PREFETCH     : integer := 1 ;
        RAM_OPT      : integer := 0 ;
        RDCNT_EN     : integer := 0 ;
        RDEPTH       : integer := 1024 ;
        RE_POLARITY  : integer := 0 ;
        READ_DVALID  : integer := 0 ;
        RWIDTH       : integer := 12 ;
        SYNC         : integer := 1 ;
        SYNC_RESET   : integer := 0 ;
        UNDERFLOW_EN : integer := 0 ;
        WDEPTH       : integer := 1024 ;
        WE_POLARITY  : integer := 0 ;
        WRCNT_EN     : integer := 0 ;
        WRITE_ACK    : integer := 0 ;
        WWIDTH       : integer := 12 
        );
    -- Port list
    port(
        -- Inputs
        CLK        : in  std_logic;
        DATA       : in  std_logic_vector(11 downto 0);
        MEMRD      : in  std_logic_vector(11 downto 0);
        RCLOCK     : in  std_logic;
        RE         : in  std_logic;
        RESET_N    : in  std_logic;
        RRESET_N   : in  std_logic;
        WCLOCK     : in  std_logic;
        WE         : in  std_logic;
        WRESET_N   : in  std_logic;
        -- Outputs
        AEMPTY     : out std_logic;
        AFULL      : out std_logic;
        DB_DETECT  : out std_logic;
        DVLD       : out std_logic;
        EMPTY      : out std_logic;
        FULL       : out std_logic;
        MEMRADDR   : out std_logic_vector(9 downto 0);
        MEMRE      : out std_logic;
        MEMWADDR   : out std_logic_vector(9 downto 0);
        MEMWD      : out std_logic_vector(11 downto 0);
        MEMWE      : out std_logic;
        OVERFLOW   : out std_logic;
        Q          : out std_logic_vector(11 downto 0);
        RDCNT      : out std_logic_vector(10 downto 0);
        SB_CORRECT : out std_logic;
        UNDERFLOW  : out std_logic;
        WACK       : out std_logic;
        WRCNT      : out std_logic_vector(10 downto 0)
        );
end component;

COMPONENT g4_dp_ext_mem
      GENERIC (
         -- Memory parameters
         RAM_RW                         :  integer := 12;    
         RAM_WW                         :  integer := 12;    
         RAM_WD                         :  integer := 10;    
         RAM_RD                         :  integer := 10;    
         RAM_ADDRESS_END                :  integer := 1024;    
         WRITE_CLK                      :  integer := 1;    
         READ_CLK                       :  integer := 1;    
         SYNC                           :  integer := 1;    
         PREFETCH                       :  integer := 1;    
         FWFT                           :  integer := 0;    
         WRITE_ENABLE                   :  integer := 0;    
         READ_ENABLE                    :  integer := 0;    
         RESET_POLARITY                 :  integer := 0);    
      PORT (
         -- local inputs

         clk                     : IN std_logic;   
         wclk                    : IN std_logic;   
         rclk                    : IN std_logic;   
         rst_n                   : IN std_logic;   
         -- local inputs - memory functional bus

         waddr                   : IN std_logic_vector(RAM_WD - 1 DOWNTO 0);   
         raddr                   : IN std_logic_vector(RAM_RD - 1 DOWNTO 0);   
         data                    : IN std_logic_vector(RAM_WW - 1 DOWNTO 0);   
         we                      : IN std_logic;   
         re                      : IN std_logic;   
         --OUTPUTS
         q                       : OUT std_logic_vector(RAM_RW - 1 DOWNTO 0));
   END COMPONENT;



signal ext_waddr        : std_logic_vector(9 downto 0) ;
signal ext_raddr        : std_logic_vector(9 downto 0)  ;
signal ext_data         : std_logic_vector(11 downto 0) ;
signal ext_rd           : std_logic_vector(11 downto 0) ;
signal ext_we           : std_logic;
signal ext_re           : std_logic;
signal wclk           	: std_logic := '0';	
signal rclk           	: std_logic := '0';	


begin

----------------------------------------------------------------------
-- Component instances
----------------------------------------------------------------------
-- adc_data_fifo_0   -   Actel:DirectCore:COREFIFO:3.0.101
adc_data_fifo_0 : adc_data_fifo_adc_data_fifo_0_COREFIFO
    generic map( 
        AE_STATIC_EN => ( 0 ),
        AEVAL        => ( 4 ),
        AF_STATIC_EN => ( 0 ),
        AFVAL        => ( 1020 ),
        CTRL_TYPE    => ( 1 ),
        DIE_SIZE     => ( 20 ),
        ECC          => ( 0 ),
        ESTOP        => ( 1 ),
        FAMILY       => ( 19 ),
        FSTOP        => ( 1 ),
        FWFT         => ( 0 ),
        NUM_STAGES   => ( 2 ),
        OVERFLOW_EN  => ( 0 ),
        PIPE         => ( 1 ),
        PREFETCH     => ( 1 ),
        RAM_OPT      => ( 0 ),
        RDCNT_EN     => ( 0 ),
        RDEPTH       => ( 1024 ),
        RE_POLARITY  => ( 0 ),
        READ_DVALID  => ( 0 ),
        RWIDTH       => ( 12 ),
        SYNC         => ( 1 ),
        SYNC_RESET   => ( 0 ),
        UNDERFLOW_EN => ( 0 ),
        WDEPTH       => ( 1024 ),
        WE_POLARITY  => ( 0 ),
        WRCNT_EN     => ( 0 ),
        WRITE_ACK    => ( 0 ),
        WWIDTH       => ( 12 )
        )
    port map( 
        -- Inputs
        CLK        => CLK,
        WCLOCK     => CLK, -- tied to '0' from definition
        RCLOCK     => CLK, -- tied to '0' from definition
        RESET_N    => RESET_N,
        WRESET_N   => RESET_N, -- tied to '0' from definition
        RRESET_N   => RESET_N, -- tied to '0' from definition
        WE         => WE,
        RE         => RE,
        DATA       => DATA,
        MEMRD      => ext_rd, -- tied to X"0" from definition
        -- Outputs
        FULL       => FULL,
        EMPTY      => EMPTY,
        AFULL      => OPEN,
        AEMPTY     => OPEN,
        OVERFLOW   => OPEN,
        UNDERFLOW  => OPEN,
        WACK       => OPEN,
        DVLD       => OPEN,
        MEMWE      => ext_we,
        MEMRE      => ext_re,
        SB_CORRECT => OPEN,
        DB_DETECT  => OPEN,
        Q          => Q,
        WRCNT      => OPEN,
        RDCNT      => OPEN,
        MEMWADDR   => ext_waddr,
        MEMRADDR   => ext_raddr,
        MEMWD      => ext_data 
        );
        
      ext_mem : g4_dp_ext_mem 
      GENERIC MAP (
         WRITE_ENABLE => 0,
         RAM_ADDRESS_END => 1024,
         RAM_WD => 10,
         RESET_POLARITY => 0,
         RAM_WW => 12,
         READ_CLK => 1,
         RAM_RD => 10,
         RAM_RW => 12,
         WRITE_CLK => 1,
         READ_ENABLE => 0,
         PREFETCH => 1,
         FWFT    => 0,
         SYNC => 0)
      PORT MAP (
         clk => clk,
         wclk => wclk,
         rclk => rclk,
         rst_n => reset_n,
         waddr => ext_waddr,
         raddr => ext_raddr,
         data => ext_data,
         we => ext_we,
         re => ext_re,
         q => ext_rd);   
         
end RTL;
