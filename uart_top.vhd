
-- ----------------------------------------------------------------------------
--              : Copyright (C) 2018 COM DEV International. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV International prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : UART_top.vhd
--              :
-- Project      : SMILE 
-- Author       : Muhammad Amjad
-- Created      : Jul 6, 2019
--
-- Description  : Instantiate UART Tx and Rx componenrts, rlated glue logic
--
-- SVN keywords : $Rev: 350 $
--                $Author: mamjad $
--                $Date: 2020-05-25 15:30:29 -0400 (Mon, 25 May 2020) $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M Amjad            | Jul 06, 2019  |    Initial Creation
--          
-- -----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

 
entity uart_top is
    generic (
        g_CLKS_PER_BIT          : integer := 868;  --use c_CLKS_PER_BIT = 868 for 115.2Kbaud at 100 MHz and 1736 at 200 MHz Clk, use c_CLKS_PER_BIT = 87 for simulaton (see note on line 125)
        g_SIM                   : boolean := FALSE;
        
        DataVecSize_g   :integer := 56;
        WdVecSize_g     :integer := 16;
        ByteSize_g      :integer := 8;
        NibbleSize_g    :integer := 4;
        Clk100Period_g  :time    := 10 ns;  -- 100MHz
        ResetDelay_g    :time    := 50 ns
        );
    port(
        --clk and reset
        i_reset                     : in  std_logic;
        i_clk                       : in  std_logic;
        i_strobe_100ms              : in  std_logic;
        i_ddr4_clk                  : in  std_logic;
               
        --UART Tx interface
        i_tx_byte_tlm               : in std_logic_vector(7 downto 0);
        i_tx_dv_tlm                 : in std_logic;    
        i_tx_byte_cmd               : in std_logic_vector(7 downto 0);
        i_TX_DV_CMD                 : in std_logic;  
        o_tx_fifo_full_cmd          : out std_logic; 
        
        --UART Rx interface
        o_rx_pkt_avail              : out std_logic;
        i_rx_byte_rd_req            : in std_logic;
        o_rx_byte_rd_dv             : out std_logic;
        o_rx_byte_rd_data           : out std_logic_vector(7 downto 0);
        o_rx_fifo_empty             : out std_logic;
        o_rx_parity_err             : out std_logic;
        
        o_tx_fifo_almost_full_tlm   : out std_logic;                  -- used in the DDRBurst module  
        o_tx_done                   : out std_logic;
           
        --serail interface 
        i_rx_serial                 : in  std_logic;
        o_tx_serial                 : out std_logic;
        
        --statistics
        o_cmd_pkt_drop_tick         : out std_logic;  --one clock period pulse for stat counter 
        --debug port
        dbg_port                    : out std_logic_vector(20 downto 0)
        --dbg_port_2                : out std_logic_vector(20 downto 0)
        );
end uart_top;

-- ----------------------------------------------------------------------------- 
architecture rtl of uart_top is
attribute syn_preserve : boolean;
attribute syn_preserve of rtl: architecture is true;
--signal declarations

type uart_txctrl_state_type_cmd is ( ST_TXCTRL_IDLE, ST_TXFIFO_READ, ST_WAIT_TXDONE);
type uart_txctrl_state_type_tlm is ( ST_TXCTRL_IDLE, ST_TXFIFO_READ, ST_WAIT_TXDONE);
                              
 signal sm_uart_txctrl_state_cmd     : uart_txctrl_state_type_cmd;
 signal sm_uart_txctrl_state_tlm     : uart_txctrl_state_type_tlm;

 signal rx_dv              : std_logic;
 signal rx_byte            : std_logic_vector(7 downto 0);
 signal s_rx_byte_rd_data  : std_logic_vector (7 downto 0);
 signal s_rx_byte_rd_dv   : std_logic;
 signal rx_fifo_full       : std_logic;
 signal rx_fifo_empty      : std_logic;
 signal rx_fifo_char_cnt   : std_logic_vector(5 downto 0);
 
 signal tx_active               : std_logic;
 signal tx_done                 : std_logic;

 signal tx_dv_tlm               : std_logic;
 signal tx_byte_tlm             : std_logic_vector(7 downto 0);
 signal tx_fifo_empty_tlm       : std_logic;
 signal tx_fifo_full_tlm        : std_logic;
 signal tx_fifo_almost_full_tlm : std_logic;
 signal tx_fifo_rd_req_tlm      : std_logic;  
 
 signal tx_dv_cmd               : std_logic;
 signal tx_byte_cmd             : std_logic_vector(7 downto 0);
 signal tx_fifo_empty_cmd       : std_logic;
 signal tx_fifo_full_cmd        : std_logic;
 signal tx_fifo_almost_full_cmd : std_logic;
 signal tx_fifo_rd_req_cmd      : std_logic;  
 signal tx_fifo_char_cnt_cmd    : std_logic_vector(5 downto 0); 

 signal s_rx_fifo_flush         : std_logic;
 signal s_rx_byte_gap_100ms_cnt : integer range 0 to 15;
 signal s_rx_fifo_reset         : std_logic;
 signal s_rx_pkt_avail          : std_logic;
 signal MEM_RD                  : std_logic_vector(7 downto 0);
 signal i_clk_reverse           : std_logic;
 signal WACK_MON                : std_logic;       
 signal i_reset_re              : std_logic;   
 signal rd_cnt_app              : std_logic_vector ( 5 downto 0 );
 signal MEMRD_app               : std_logic_vector(7 downto 0);

 
 type t_flush_ctrl_state_type is (ST_IDLE, ST_MONITORIG);
 signal sm_flush_ctrl_state : t_flush_ctrl_state_type;
 
component TB_CHAR_FIFO_8x32
   Port ( 
     CLK         : in std_logic;
     DATA        : in std_logic_vector ( 7 downto 0 );
     RE          : in std_logic;
     RESET_N     : in std_logic;
     WE          : in std_logic;
     AFULL       : out std_logic;
     EMPTY       : out std_logic;
     FULL        : out std_logic;

     MEMRADDR    : out std_logic_vector ( 4 downto 0 );
     MEMRE       : out std_logic;
     MEMWADDR    : out std_logic_vector ( 4 downto 0 );
     MEMWE       : out std_logic;
     DVLD        : out std_logic;
     Q           : out std_logic_vector ( 7 downto 0 );
     RDCNT       : out std_logic_vector ( 5 downto 0 );
     WACK        : out std_logic;
     WRCNT       : out std_logic_vector ( 5 downto 0 )

   );
end component TB_CHAR_FIFO_8x32;

component CHAR_FIFO_8x32
   Port ( 
     CLK         : in std_logic;
     DATA        : in std_logic_vector ( 7 downto 0 );
     RE          : in std_logic;
     RESET_N     : in std_logic;
     WE          : in std_logic;
     
     AFULL       : out std_logic;
     DVLD        : out std_logic;
     EMPTY       : out std_logic;
     FULL        : out std_logic;

     Q           : out std_logic_vector ( 7 downto 0 );
     RDCNT       : out std_logic_vector ( 5 downto 0 );
     WACK        : out std_logic;
     WRCNT       : out std_logic_vector ( 5 downto 0 )

   );
end component CHAR_FIFO_8x32;


component ASYNC_FIFO_8x32    --_generator_1
   Port ( 
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
end component ASYNC_FIFO_8X32;  --fifo_generator_1;


component TB_TX_FIFO    --_generator_1
   Port ( 
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
end component TB_TX_FIFO;  --fifo_generator_1;

 
component UART_RX is

generic(
    g_CLKS_PER_BIT    :integer := 868
        );
  port(
    i_Reset         : in  std_logic;
    i_Clk           : in  std_logic;                           --: in  std_logic;
    
    o_RX_DV         : out std_logic;                           --:  in std_logic;
    o_RX_Byte       : out std_logic_vector(7 downto 0);        --: out std_logic_vector(7 downto 0)
    o_rx_parity_err : out std_logic;                           --: out std_logic;
    i_RX_Serial     : in  std_logic                            --: in  std_logic;

    
    );
 --Note for Bo: these are the values to be used to divide 100MHz clock 115.2Kbous (11.5Kbaud for simulation only) 
 --constant c_CLKS_PER_BIT        : integer:=868; --UART baud rate 115.2kbps @ clock=100MHz. need 620us to receive a byte
 --constant c_CLKS_PER_BIT_SIM    : integer:=87;  --UART baud rate 1.152Mbps @ clock=10MHz. need 62us to send a byte out
end component UART_RX;

component UART_TX is
  generic(
    g_CLKS_PER_BIT    :integer := 868
        );
  port(
    i_Reset         : in  std_logic;
    i_Clk           : in  std_logic;                           --: in  std_logic;
    i_TX_DV_TLM     : in  std_logic; 
    i_TX_DV_CMD     : in  std_logic; 
    i_tx_byte_tlm   : in  std_logic_vector(7 downto 0);
    i_tx_byte_cmd   : in  std_logic_vector(7 downto 0);
    o_TX_Active     : out std_logic;
    o_TX_Done       : out std_logic;
    o_TX_Serial     : out std_logic
    ); 
end component UART_TX;

-- -----------------------------------------------------------------------------   
begin
i_clk_reverse <= not i_clk;
i_reset_re <= not i_reset;
--UART receiver 
-- inst_uart_rx : entity work.UART_RX
 inst_uart_rx : UART_RX

  port map (
    i_Reset         => i_reset,
    i_Clk           => i_clk,             --: in  std_logic;
    o_RX_DV         => rx_dv,             --: out std_logic;
    o_RX_Byte       => rx_byte,           --: out std_logic_vector(7 downto 0)
    o_rx_parity_err => o_rx_parity_err,   --: out std_logic;
    i_RX_Serial     => i_RX_Serial        --: in  std_logic;
    
    );
    
 --rx fifo
inst_rx_char_fifo : CHAR_FIFO_8x32  --generator_0 
  port map (
    RESET_N         => s_rx_fifo_reset,   --i_reset,           --: in STD_LOGIC;
    CLK             => i_clk,             --: in STD_LOGIC;
    DATA            => rx_byte,           --: in STD_LOGIC_VECTOR ( 7 downto 0 );
    Q               => s_rx_byte_rd_data, --: out STD_LOGIC_VECTOR ( 7 downto 0 );
    WE              => rx_dv,             --: in STD_LOGIC;
    RE              => i_rx_byte_rd_req,  --: in STD_LOGIC;
    WACK            => open,
    FULL            => rx_fifo_full,      --: out STD_LOGIC;
    AFULL           => open,
    EMPTY           => rx_fifo_empty,     --: out STD_LOGIC;
    WRCNT           => rx_fifo_char_cnt,  --: out STD_LOGIC_VECTOR ( 4 downto 0 )
    RDCNT           => open,
    DVLD            => open

  );
  

  dbg_port(7 downto 0)  <= rx_byte;
  dbg_port(8)           <= rx_dv;
  dbg_port(9)           <= s_rx_fifo_flush;
  dbg_port(10)          <= s_rx_pkt_avail;
  dbg_port(11)          <= i_rx_byte_rd_req;
  dbg_port(19 downto 12)<= s_rx_byte_rd_data;
  dbg_port(20)          <= rx_fifo_empty;
  
  
 s_rx_fifo_reset <= i_reset_re or s_rx_fifo_flush;
 
--if the gap between consuctive bytes of the Rx packet is larger than specified value,  
--the packet will be considred partial and will be flushed from the buffer by resetting the FIFO.
rx_fifo_flush_ctrl: process(i_reset, i_clk)
begin
    if i_reset = '1'then
        s_rx_fifo_flush         <= '0';
        s_rx_byte_gap_100ms_cnt <= 0;
        sm_flush_ctrl_state <= ST_IDLE;
        
    elsif rising_edge(i_clk) then
    
        s_rx_fifo_flush         <= '0';
        
        case sm_flush_ctrl_state is
            when ST_IDLE => 
                if rx_fifo_empty /= '1' then
                    sm_flush_ctrl_state <= ST_MONITORIG;
                end if;
            when ST_MONITORIG => 
                if rx_dv = '1' then
                    s_rx_byte_gap_100ms_cnt <= 0;
                elsif i_strobe_100ms = '1' then
                    s_rx_byte_gap_100ms_cnt <=  s_rx_byte_gap_100ms_cnt + 1;
                    
                    if (s_rx_byte_gap_100ms_cnt >= 3) or (rx_fifo_empty = '1') then --300 ms delay between bytes
                        s_rx_fifo_flush         <= '1'; 
                        s_rx_byte_gap_100ms_cnt <= 0;
                        sm_flush_ctrl_state <= ST_IDLE;
                    end if;
                end if;
              
            when others => 
                sm_flush_ctrl_state <= ST_IDLE;
       end case;

        
    end if;
end process;
o_cmd_pkt_drop_tick <= s_rx_fifo_flush;
--------------------------------------------------------------------------------
-- Purpose: to generate two signals:
--     o_rx_pkt_avail = '1', whenever a full seven-byte command is received by RX-FIFO
--     o_rx_dv = '1', if there are any un-read bytes still inside the RX-FIFO
uart_rx_ctrl: process(i_reset, i_clk)
    begin
        --if i_reset = '1' or i_rx_byte_req = '1' then 
        if i_reset = '1' then         
            s_rx_pkt_avail <= '0';
            s_rx_byte_rd_dv <= '0';
        elsif rising_edge(i_clk) then
        
            s_rx_pkt_avail <= '0';
            if to_integer(unsigned(rx_fifo_char_cnt)) >= 10 then --total 10 bytes to be received as a command
                s_rx_pkt_avail <= '1';
            end if;
            
            s_rx_byte_rd_dv <= i_rx_byte_rd_req;
            
           -- if i_rx_byte_rd_req = '1' then --and rx_fifo_char_cnt = "00111" then
           -- --if i_rx_byte_req = '1' then
           --     s_rx_byte_rd_dv <= '1';
           -- elsif rx_fifo_empty = '1' then
           --     s_rx_byte_rd_dv <= '0';
           -- end if;            
        end if;
end process;


o_rx_pkt_avail          <= s_rx_pkt_avail;
o_rx_byte_rd_data       <= s_rx_byte_rd_data;
o_rx_byte_rd_dv         <= s_rx_byte_rd_dv;

o_rx_fifo_empty <= rx_fifo_empty;
o_tx_done <= tx_done;



--UART transmiter
inst_uart_tx : UART_TX
  port map(
    i_Reset         => i_reset,
    i_Clk           => i_clk,                   --: in  std_logic;
    i_TX_DV_TLM     => tx_dv_tlm,                   --: in  std_logic;
    i_TX_DV_CMD     => tx_dv_cmd,
    i_tx_byte_tlm   => tx_byte_tlm,             --: in  std_logic_vector(7 downto 0);
    i_tx_byte_cmd  => tx_byte_cmd,
    o_TX_Active     => tx_active,               --: out std_logic
    o_TX_Done       => tx_done,                 --: out std_logic
    o_TX_Serial     => o_tx_serial              --: out std_logic;
    ); 
 
 
 --tx fifo
inst_tlm_pkt_fifo :  ASYNC_FIFO_8x32 --fifo_generator_1 
  port map (     
    CLK             => i_clk,        
    DATA            => i_tx_byte_tlm,
    RE              => tx_fifo_rd_req_tlm,
    RESET_N         => i_reset_re,
    WE              => i_tx_dv_tlm,
    AFULL           => tx_fifo_almost_full_tlm,
    EMPTY           => tx_fifo_empty_tlm,
    FULL            => tx_fifo_full_tlm,
    Q               => tx_byte_tlm 

  );
  
 inst_cmd_pkt_fifo :  CHAR_FIFO_8x32   --fifo_generator_0 
  port map ( 
    RESET_N         => i_reset_re,                     --: in STD_LOGIC;
    CLK             => i_clk,                       --: in STD_LOGIC;
    DATA            => i_tx_byte_cmd,               --: in STD_LOGIC_VECTOR ( 7 downto 0 );
    WE              => i_TX_DV_CMD,                 --: in STD_LOGIC;
    RE              => tx_fifo_rd_req_cmd,          --: in STD_LOGIC;
    Q               => tx_byte_cmd,                 --: out STD_LOGIC_VECTOR ( 7 downto 0 );
    AFULL           => tx_fifo_almost_full_cmd,
    FULL            => tx_fifo_full_cmd,            --o_tx_fifo_full,          --: out STD_LOGIC;
    EMPTY           => tx_fifo_empty_cmd,           --: out STD_LOGIC;
    WRCNT           => tx_fifo_char_cnt_cmd,        --: out STD_LOGIC_VECTOR ( 4 downto 0 )
    RDCNT           => rd_cnt_app,
    DVLD            => open,
    WACK            => open
  ); 
  
 o_tx_fifo_almost_full_tlm <= tx_fifo_full_tlm;
 o_tx_fifo_full_cmd        <= tx_fifo_full_cmd;
--o_tx_fifo_almost_full   <= '1' when tx_fifo_char_cnt >= "11100" else '0';
 
------------------------------------------
-- Purpose: to generate two signals:
--    / tx_dv = '1', whenever one byte data ready to be latched by uart_tx for sending out
--    / tx_fifo_rd_req = '1', to read one-byte data out of the TX-FIFO
uart_tx_ctrl_tlm: process (i_reset, i_clk)
begin
  if i_reset = '1' then
    tx_fifo_rd_req_tlm <= '0';
    tx_dv_tlm   <= '0';
    sm_uart_txctrl_state_tlm <= ST_TXCTRL_IDLE;
   
  elsif rising_edge(i_clk) then
  
    case sm_uart_txctrl_state_tlm is
    
      when ST_TXCTRL_IDLE =>
        --tb_tx_byte <= x"00";
        tx_dv_tlm <= '0';
        tx_fifo_rd_req_tlm <= '0';
        if tx_active = '0' and tx_fifo_empty_tlm = '0' then
          tx_fifo_rd_req_tlm <= '1';
          sm_uart_txctrl_state_tlm  <= ST_TXFIFO_READ;
        end if;
        
      when ST_TXFIFO_READ => --Read just one byte out and feed into uart_tx
        tx_dv_tlm <= '1';
        tx_fifo_rd_req_tlm <= '0';
        sm_uart_txctrl_state_tlm <= ST_WAIT_TXDONE;
    
      when ST_WAIT_TXDONE => --Read just one byte out and feed into uart_tx
        tx_dv_tlm <= '0';
        tx_fifo_rd_req_tlm <= '0';
        if tx_done = '1' then
          sm_uart_txctrl_state_tlm <= ST_TXCTRL_IDLE;
        end if;

      when others =>
          sm_uart_txctrl_state_tlm <= ST_TXCTRL_IDLE;
            
    end case;
    
  end if;
end process;

uart_tx_ctrl_cmd: process (i_reset, i_clk)
begin
  if i_reset = '1' then
    tx_fifo_rd_req_cmd <= '0';
    tx_dv_cmd   <= '0';
    sm_uart_txctrl_state_cmd <= ST_TXCTRL_IDLE;
   
  elsif rising_edge(i_clk) then
  
    case sm_uart_txctrl_state_cmd is
    
      when ST_TXCTRL_IDLE =>
        --tb_tx_byte <= x"00";
        tx_dv_cmd <= '0';
        tx_fifo_rd_req_cmd <= '0';
        if tx_active = '0' and tx_fifo_empty_cmd = '0' then
          tx_fifo_rd_req_cmd <= '1';
          sm_uart_txctrl_state_cmd  <= ST_TXFIFO_READ;
        end if;
        
      when ST_TXFIFO_READ => --Read just one byte out and feed into uart_tx
        tx_dv_cmd <= '1';
        tx_fifo_rd_req_cmd <= '0';
        sm_uart_txctrl_state_cmd <= ST_WAIT_TXDONE;
    
      when ST_WAIT_TXDONE => --Read just one byte out and feed into uart_tx
        tx_dv_cmd <= '0';
        tx_fifo_rd_req_cmd <= '0';
        if tx_done = '1' then
          sm_uart_txctrl_state_cmd <= ST_TXCTRL_IDLE;
        end if;

      when others =>
          sm_uart_txctrl_state_cmd <= ST_TXCTRL_IDLE;
            
    end case;
    
  end if;
end process; 

 -- -----------------------------------------------------------------------------  
end rtl;