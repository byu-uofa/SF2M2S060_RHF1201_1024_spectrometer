----------------------------------------------------------------------
-- Created by SmartDesign Wed Nov 29 15:18:57 2023
-- Version: 2023.1 2023.1.0.6
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Component Description (Tcl) 
----------------------------------------------------------------------
--# Exporting Component Description of ASYNC_FIFO_8X32 to TCL
--# Family: SmartFusion2
--# Part Number: M2S060-1FG484I
--# Create and Configure the core component ASYNC_FIFO_8X32
--create_and_configure_core -core_vlnv {Actel:DirectCore:COREFIFO:3.0.101} -component_name {ASYNC_FIFO_8X32} -params {\
--"AE_STATIC_EN:false"  \
--"AEVAL:4"  \
--"AF_STATIC_EN:true"  \
--"AFVAL:30"  \
--"CTRL_TYPE:1"  \
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
--"RDEPTH:32"  \
--"RE_POLARITY:0"  \
--"READ_DVALID:false"  \
--"RWIDTH:8"  \
--"SYNC:1"  \
--"SYNC_RESET:0"  \
--"UNDERFLOW_EN:false"  \
--"WDEPTH:32"  \
--"WE_POLARITY:0"  \
--"WRCNT_EN:false"  \
--"WRITE_ACK:false"  \
--"WWIDTH:8"   }
--# Exporting Component Description of ASYNC_FIFO_8X32 to TCL done

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
-- ASYNC_FIFO_8X32 entity declaration
----------------------------------------------------------------------
entity TB_TX_FIFO is
    -- Port list
    port(
        -- Inputs
        CLK     : in  std_logic;
        DATA    : in  std_logic_vector(7 downto 0);
        RE      : in  std_logic;
        RESET_N : in  std_logic;
        WE      : in  std_logic;
        -- Outputs
        AFULL   : out std_logic;
        EMPTY   : out std_logic;
        FULL    : out std_logic;
        Q       : out std_logic_vector(7 downto 0)
        );
end entity TB_TX_FIFO;
----------------------------------------------------------------------
-- ASYNC_FIFO_8X32 architecture body
----------------------------------------------------------------------
architecture RTL of TB_TX_FIFO is
----------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------
-- ASYNC_FIFO_8X32_ASYNC_FIFO_8X32_0_COREFIFO   -   Actel:DirectCore:COREFIFO:3.0.101
component ASYNC_FIFO_8X32_ASYNC_FIFO_8X32_0_COREFIFO
    generic( 
        AE_STATIC_EN : integer := 0 ;
        AEVAL        : integer := 4 ;
        AF_STATIC_EN : integer := 1 ;
        AFVAL        : integer := 30 ;
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
        RDEPTH       : integer := 32 ;
        RE_POLARITY  : integer := 0 ;
        READ_DVALID  : integer := 0 ;
        RWIDTH       : integer := 8 ;
        SYNC         : integer := 1 ;
        SYNC_RESET   : integer := 0 ;
        UNDERFLOW_EN : integer := 0 ;
        WDEPTH       : integer := 32 ;
        WE_POLARITY  : integer := 0 ;
        WRCNT_EN     : integer := 0 ;
        WRITE_ACK    : integer := 0 ;
        WWIDTH       : integer := 8 
        );
    -- Port list
    port(
        -- Inputs
        CLK        : in  std_logic;
        DATA       : in  std_logic_vector(7 downto 0);
        MEMRD      : in  std_logic_vector(7 downto 0);
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
        MEMRADDR   : out std_logic_vector(4 downto 0);
        MEMRE      : out std_logic;
        MEMWADDR   : out std_logic_vector(4 downto 0);
        MEMWD      : out std_logic_vector(7 downto 0);
        MEMWE      : out std_logic;
        OVERFLOW   : out std_logic;
        Q          : out std_logic_vector(7 downto 0);
        RDCNT      : out std_logic_vector(5 downto 0);
        SB_CORRECT : out std_logic;
        UNDERFLOW  : out std_logic;
        WACK       : out std_logic;
        WRCNT      : out std_logic_vector(5 downto 0)
        );
end component;

COMPONENT g4_dp_ext_mem
      GENERIC (
         -- Memory parameters
         RAM_RW                         :  integer := 8;    
         RAM_WW                         :  integer := 8;    
         RAM_WD                         :  integer := 5;    
         RAM_RD                         :  integer := 5;    
         RAM_ADDRESS_END                :  integer := 32;    
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
    
     signal ext_waddr : std_logic_vector(4 downto 0) ;
     signal ext_raddr : std_logic_vector(4 downto 0)  ;
     signal ext_data  : std_logic_vector(7 downto 0) ;
     signal ext_rd    : std_logic_vector(7 downto 0) ;
     signal ext_we : std_logic;
     signal ext_re : std_logic;
     signal wclk           	: std_logic := '0';	
     signal rclk           	: std_logic := '0';	

begin
----------------------------------------------------------------------
-- Constant assignments
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Component instances
----------------------------------------------------------------------
-- ASYNC_FIFO_8X32_0   -   Actel:DirectCore:COREFIFO:3.0.101
ASYNC_FIFO_8X32_0 : ASYNC_FIFO_8X32_ASYNC_FIFO_8X32_0_COREFIFO
    generic map( 
        AE_STATIC_EN => ( 0 ),
        AEVAL        => ( 4 ),
        AF_STATIC_EN => ( 1 ),
        AFVAL        => ( 30 ),
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
        RDEPTH       => ( 32 ),
        RE_POLARITY  => ( 0 ),
        READ_DVALID  => ( 0 ),
        RWIDTH       => ( 8 ),
        SYNC         => ( 1 ),
        SYNC_RESET   => ( 0 ),
        UNDERFLOW_EN => ( 0 ),
        WDEPTH       => ( 32 ),
        WE_POLARITY  => ( 0 ),
        WRCNT_EN     => ( 0 ),
        WRITE_ACK    => ( 0 ),
        WWIDTH       => ( 8 )
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
        MEMRD      => ext_rd,
        -- Outputs
        FULL       => FULL,
        EMPTY      => EMPTY,
        AFULL      => AFULL,
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
         RAM_ADDRESS_END => 32,
         RAM_WD => 5,
         RESET_POLARITY => 0,
         RAM_WW => 8,
         READ_CLK => 1,
         RAM_RD => 5,
         RAM_RW => 8,
         WRITE_CLK => 1,
         READ_ENABLE => 0,
         PREFETCH => 1,
         FWFT    => 0,
         SYNC => 0)
      PORT MAP (
         clk => CLK,
         wclk => CLK,
         rclk => CLK,
         rst_n => RESET_N,
         waddr => ext_waddr,
         raddr => ext_raddr,
         data => ext_data,
         we => ext_we,
         re => ext_re,
         q => ext_rd);  
        

end RTL;
