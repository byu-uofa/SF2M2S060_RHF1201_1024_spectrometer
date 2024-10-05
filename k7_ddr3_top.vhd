----------------------------------------------------------------------------------
-- Company: University of Alberta
-- Engineer: Bo Yu
-- 
-- Create Date: 2023/01/30 16:52:05
-- Design Name: 
-- Module Name: k7_ddr3_top - k7_ddr3_top_RTL
-- Project Name: 
-- Target Devices:
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
--+----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_STD.all;

library work;
use work.p_swept_pkg.all;
use work.radical_cmds_pkg.all;

--****************************************************************************
-- Entity declaration section start
--============================================================================
entity k7_ddr3_top is
  --+----------
  -- Generic declarations
  --+----------
  generic(
          DataVecSize_g   :integer := 56;
          WdVecSize_g     :integer := 16;
          ByteSize_g      :integer := 8;
          NibbleSize_g    :integer := 4
       );
  --+----------
  -- Port name declarations
  --+----------
  port   (

          CLK100_P         :in  std_logic; 
          sys_rst          :in  std_logic; 
          -- Serial Controller  Signals
          TX               :out std_logic;
          RX               :in  std_logic;
          -- ADC signals
          ADC_D1           :in  std_logic_vector(11 downto 0); /* synthesis syn_keep =1*/
          ADC_DR1          :in  std_logic;
                  
          ADC_D2           :in  std_logic_vector(11 downto 0);   
          ADC_DR2          :in  std_logic;
      
          ADC_CLK_1        :out std_logic;
          ADC_CLK_2        :out std_logic; 

          -- pulsating LED
          ON_LED_HEARTBEAT :out std_logic;
          LED_M            :out std_logic

            );

end entity k7_ddr3_top;
--============================================================================
-- Entity declaration section end
--****************************************************************************

--****************************************************************************
-- Architecture definition section start - RTL
--============================================================================
architecture k7_ddr3_top_RTL of k7_ddr3_top is
attribute syn_noprune : boolean;
attribute syn_noprune of k7_ddr3_top_RTL : architecture is true;
attribute syn_preserve : boolean;
attribute syn_preserve of k7_ddr3_top_RTL: architecture is true;

-- signal declaration

 signal RST               :std_logic:='0';
 signal AdcClk_s1         :std_logic;
 signal AdcClk_s2         :std_logic;
 signal o_ddr4_clk        :std_logic;
 
 signal PEAK_FL_C1_s      :  std_logic;
 signal PEAK_FL_C2_s      :  std_logic;

 signal PEAK_C1_s         : std_logic_vector(WdVecSize_g-5 downto 0);
 signal PEAK_C2_s         : std_logic_vector(WdVecSize_g-5 downto 0);

 signal TIMESTAMP_C1_s    : std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0);
 signal TIMESTAMP_C2_s    : std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0);
 
 -- heart beat
 signal cnt_s    					:std_logic_vector(27 downto 0):=(others=>'0');
 signal Tx_s                        :std_logic:='0';
 signal Rx_s                        :std_logic:='0';
 signal i_tx_byte                   :std_logic_vector(7 downto 0);
 signal o_tx_done                   :std_logic:='0';
 signal i_strobe_100ms              :std_logic;     
 
 signal o_tx_byte_tlm               :std_logic_vector(7 downto 0);
 signal o_tx_dv_tlm                 :std_logic;    
 signal o_tx_byte_cmd               :std_logic_vector(7 downto 0);
 signal o_tx_dv_cmd                 :std_logic;  
 signal o_tx_fifo_full_cmd          :std_logic; 
 signal o_tx_fifo_almost_full_tlm   :std_logic;   
                                                                                                   
 signal i_tx_dv                     :std_logic;                                            
 signal o_tx_fifo_full              :std_logic;                                           
 signal o_rx_pkt_avail              :std_logic;                                           
 signal i_rx_byte_rd_req            :std_logic;                                            
 signal o_rx_byte_rd_dv             :std_logic;                                           
 signal o_rx_byte_rd_data           :std_logic_vector(7 downto 0);                        
 signal o_rx_fifo_empty             :std_logic;                                           
 signal o_rx_parity_err             :std_logic;                                                                                                            
 signal i_rx_serial                 :std_logic;                                           
 signal o_tx_serial                 :std_logic;                                                                                                            
 signal o_cmd_pkt_drop_tick         :std_logic;  --one clock period pulse for stat counter                                                                         
 signal dbg_port                    :std_logic_vector(20 downto 0);  
 signal o_ddr_byte_valid            :std_logic;
 signal o_ddr_byte_end              :std_logic;
 signal o_ddr_byte                  :std_logic_vector(7 downto 0); -- "length" of DDR Read-out data will come out first    
 signal i_ddr_uart_read_req         :std_logic;
 
 signal i_stop_req                  :std_logic;
 signal s_mtime_over                :std_logic;

 signal i_ddr_read_addr_reg0        :std_logic_vector(15 downto 0);
 signal i_ddr_read_addr_reg1        :std_logic_vector(15 downto 0);
 signal i_ddr_read_length_reg0      :std_logic_vector(15 downto 0);
 signal i_ddr_read_length_reg1      :std_logic_vector(15 downto 0);
 
 signal i_ddr_uart_read_req_ALL     :std_logic;
 signal i_ddr_uart_read_req_CH1     :std_logic;
 signal i_ddr_uart_read_req_CH2     :std_logic;
 signal i_ddr_uart_read_req_CH3     :std_logic;
 signal i_ddr_uart_read_req_CH4     :std_logic;
 
 signal i_ddr_wrd_vld               :std_logic;
 signal i_ddr_wrd                   :std_logic_vector(63 downto 0);
 signal i_tx_word_done              :std_logic;  
 --System time to other blocks
 signal   o_system_time_msec_cnt    :std_logic_vector(31 downto 0);


 signal   o_rx_error                :std_logic;   -- may be multiple pulses
 signal   o_dbg_mux_ctrl            :std_logic_vector(2 downto 0);  
 signal   o_dbg_port                :std_logic_vector(15 downto 0);
 signal   strobes                   :strobe_t;
 signal   s_Energy_Bin_1            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_2            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_3            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_4            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_5            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_6            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_7            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_8            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_9            :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_10           :std_logic_vector(31 downto 0); 

 signal   s_Energy_Bin_1_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_2_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_3_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_4_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_5_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_6_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_7_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_8_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_9_pos        :std_logic_vector(31 downto 0); 
 signal   s_Energy_Bin_10_pos       :std_logic_vector(31 downto 0); 
 
 signal s_E1_C1_L                   : std_logic_vector(11 downto 0); 
 signal s_E1_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E1_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E1_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E2_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E2_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E2_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E2_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E3_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E3_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E3_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E3_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E4_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E4_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E4_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E4_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E5_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E5_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E5_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E5_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E6_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E6_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E6_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E6_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E7_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E7_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E7_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E7_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E8_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E8_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E8_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E8_C2_H                   : std_logic_vector(11 downto 0);
 signal s_E9_C1_L                   : std_logic_vector(11 downto 0);
 signal s_E9_C1_H                   : std_logic_vector(11 downto 0);
 signal s_E9_C2_L                   : std_logic_vector(11 downto 0);
 signal s_E9_C2_H                   : std_logic_vector(11 downto 0);

 signal s_E1_C1_L_pos               : std_logic_vector(11 downto 0); 
 signal s_E1_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E1_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E1_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E2_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E2_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E2_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E2_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E3_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E3_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E3_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E3_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E4_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E4_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E4_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E4_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E5_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E5_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E5_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E5_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E6_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E6_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E6_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E6_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E7_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E7_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E7_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E7_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E8_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E8_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E8_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E8_C2_H_pos               : std_logic_vector(11 downto 0);
 signal s_E9_C1_L_pos               : std_logic_vector(11 downto 0);
 signal s_E9_C1_H_pos               : std_logic_vector(11 downto 0);
 signal s_E9_C2_L_pos               : std_logic_vector(11 downto 0);
 signal s_E9_C2_H_pos               : std_logic_vector(11 downto 0);
 
 signal s_PEAK_THD                  : std_logic_vector(11 downto 0);
 signal s_PEAK_THD_pos              : std_logic_vector(11 downto 0);
 
 signal s_DR1_EN                    : std_logic;
 signal s_DR2_EN                    : std_logic;

 signal app_sr_active               : std_logic; 
 signal app_ref_ack                 : std_logic; 
 signal app_zq_ack                  : std_logic; 
 
 signal  ADC_D1_s          :std_logic_vector(11 downto 0); /* synthesis preserve=1*/
 signal  ADC_DR1_s         :std_logic; /* synthesis preserve=1*/
               
 signal  ADC_D2_s          :std_logic_vector(11 downto 0); /* synthesis preserve=1*/    
 signal  ADC_DR2_s         :std_logic; /* synthesis preserve=1*/
  
 signal rd_en_adc_fifo_1    :std_logic;
 signal rd_en_adc_fifo_2    :std_logic; 

 signal adc_fifo_empty_1    :std_logic;
 signal adc_fifo_empty_2    :std_logic;

 signal adc_fifo_data_out_1 :std_logic_vector(11 downto 0);
 signal adc_fifo_data_out_2 :std_logic_vector(11 downto 0);
 
 signal rd_en_peak_fifo_1    :std_logic;
 signal rd_en_peak_fifo_2    :std_logic; 

 signal peak_fifo_empty_1    :std_logic;
 signal peak_fifo_empty_2    :std_logic;

 signal peak_fifo_data_out_1 :std_logic_vector(11 downto 0);
 signal peak_fifo_data_out_2 :std_logic_vector(11 downto 0);
 
 signal i_adc_dump_req_1    :std_logic;
 signal i_adc_dump_req_2    :std_logic;
 
 signal i_peak_dump_req_1    :std_logic;
 signal i_peak_dump_req_2    :std_logic;
 
 signal i_soft_reset         :std_logic;

component cmn_timer
port (
         clk          : in  std_logic;
         rst          : in  std_logic;
         strobes      : out strobe_t
);
end component;

  
component reset_delay 
generic(
        DELAY               : integer:=40;   -- Reset delay in clock cycles   
        RESET_IN_POLARITY   : std_logic:='1';  --active high reset for Xilinx Dev board 
        RESET_OUT_POLARITY  : std_logic:='1'   --active high internal reset
    );
port (        
        clk                 : in std_logic;
        RST_in              : in std_logic;  -- External Power-On Reset        
        RST_out             : out std_logic;  -- Output internal Reset
        i_msc_soft_reset    : in std_logic
);
end component;

component DataCtrl is
  --+----------
  -- Generic declarations
  --+----------
  generic(
          DataVecSize_g   :integer := 56;
          WdVecSize_g     :integer := 16;
          ByteSize_g      :integer := 8;
          NibbleSize_g    :integer := 4
      );

  --+----------
  -- Port name declarations
  --+----------
  port   (
       CLK100     :in  std_logic;
       RST        :in  std_logic;
       
       ADC_CLK_1  :out std_logic;
       ADC_CLK_2  :out std_logic; 
       
       ADC_D1_d     :in  std_logic_vector(11 downto 0); /* synthesis preserve=1*/
       ADC_DR1_d    :in  std_logic; /* synthesis preserve=1*/
               
       ADC_D2_d     :in  std_logic_vector(11 downto 0); /* synthesis preserve=1*/   
       ADC_DR2_d    :in  std_logic; /* synthesis preserve=1*/
       
       PEAK_FL_C1   :out  std_logic;
       
       i_PEAK_THD          :in std_logic_vector(11 downto 0);
       i_PEAK_THD_pos      :in std_logic_vector(11 downto 0);
       
       i_DR1_EN            : in std_logic;
       i_DR2_EN            : in std_logic;
       
       PEAK_C1             :out std_logic_vector(WdVecSize_g-5 downto 0);
       PEAK_C2             :out std_logic_vector(WdVecSize_g-5 downto 0);
       
       TIMESTAMP_C1          :out std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0);
       TIMESTAMP_C2          :out std_logic_vector(DataVecSize_g-WdVecSize_g-1 downto 0);
       
	   i_stop_req            :in std_logic;
       mtime_over            :in std_logic;
       
       rd_en_adc_fifo_1      :in   std_logic;
       rd_en_adc_fifo_2      :in   std_logic;
       
       adc_fifo_empty_1      :out  std_logic;
       adc_fifo_empty_2      :out  std_logic;
       
       adc_fifo_data_out_1   :out std_logic_vector(11 downto 0);
       adc_fifo_data_out_2   :out std_logic_vector(11 downto 0);
       
       rd_en_peak_fifo_1     :in   std_logic;
       rd_en_peak_fifo_2     :in   std_logic;
       
       peak_fifo_empty_1     :out  std_logic;
       peak_fifo_empty_2     :out  std_logic;
       
       peak_fifo_data_out_1  :out std_logic_vector(11 downto 0);
       peak_fifo_data_out_2  :out std_logic_vector(11 downto 0)

         );

end component DataCtrl;

component Master_ctrl is

   generic (
    g_VERSION                 : std_logic_vector(7 downto 0):=x"01"; --Version number X.X (hex)
    g_DAY                     : integer:= 30;                        --build code register (day)
    g_MONTH                   : integer:= 08;                        --build code register (month)
    g_YEAR                    : integer:= 22                         --build code register (year)
    );
    
  port(
    --clk and reset
    i_reset                 : in  std_logic;
    i_clk                   : in  std_logic;
    i_strobe_1ms            : in  std_logic;
    i_strobe_100ms          : in  std_logic;
            
    --UART Tx interface
    o_uart_tx_byte          : out std_logic_vector(7 downto 0);
    o_uart_tx_dv            : out std_logic;
    i_uart_tx_fifo_full     : in std_logic;
    i_uart_tx_done          : in std_logic;
    
    --UART Rx interface
    i_uart_rx_pkt_avail     : in std_logic;
    o_uart_rx_byte_req      : out std_logic;
    i_uart_rx_dv            : in std_logic;
    i_uart_rx_byte          : in std_logic_vector(7 downto 0);
    i_uart_rx_fifo_empty    : in std_logic;
    i_urx_parity_err        : in std_logic;

    o_PEAK_THD                 : out std_logic_vector(11 downto 0);
    o_PEAK_THD_pos             : out std_logic_vector(11 downto 0);
    
    o_DR1_EN                   : out std_logic;
    o_DR2_EN                   : out std_logic;

    --System time to other blocks
    o_system_time_msec_cnt     : out std_logic_vector(31 downto 0);
	
	-- Stop control
	o_stop_req                 : out std_logic;
    o_mtime_over               : out std_logic;
    
    o_adc_dump_req_1           : out std_logic;
    o_adc_dump_req_2           : out std_logic;
    
    o_peak_dump_req_1           : out std_logic;
    o_peak_dump_req_2           : out std_logic;
    
    o_soft_reset                : out std_logic;
	
	o_ddr_read_addr_reg0       : out std_logic_vector(15 downto 0);
    o_ddr_read_addr_reg1       : out std_logic_vector(15 downto 0);
    o_ddr_read_length_reg0     : out std_logic_vector(15 downto 0);
    o_ddr_read_length_reg1     : out std_logic_vector(15 downto 0);

    o_rx_error                 : out std_logic;   -- may be multiple pulses
--    o_dbg_mux_ctrl           : out std_logic_vector(2 downto 0);
    o_dbg_port                 : out std_logic_vector(15 downto 0);
    LED_M                      : out std_logic

    );
end component Master_ctrl;



component uart_top is
    generic (
        g_CLKS_PER_BIT          : integer := 836;  --use c_CLKS_PER_BIT = 868 for 115.2Kbaud at 100 MHz, use c_CLKS_PER_BIT = 87 for simulaton (see note on line 125)
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
--        i_tx_byte                   : in std_logic_vector(7 downto 0);
--        i_tx_dv                     : in std_logic;
        o_tx_fifo_almost_full_tlm   : out std_logic;
        o_tx_fifo_full_cmd          : out std_logic; 
        o_tx_done                   : out std_logic;
             
        --UART Rx interface
        o_rx_pkt_avail              : out std_logic;
        i_rx_byte_rd_req            : in std_logic;
        o_rx_byte_rd_dv             : out std_logic;
        o_rx_byte_rd_data           : out std_logic_vector(7 downto 0);
        o_rx_fifo_empty             : out std_logic;
        o_rx_parity_err             : out std_logic;
        
        i_tx_byte_tlm               : in std_logic_vector(7 downto 0);
        i_tx_dv_tlm                 : in std_logic;    
        i_tx_byte_cmd               : in std_logic_vector(7 downto 0);
        i_tx_dv_cmd                 : in std_logic;   

        --serail interface 
        i_rx_serial                 : in  std_logic;
        o_tx_serial                 : out std_logic;
        
        --statistics
        o_cmd_pkt_drop_tick         : out std_logic;  --one clock period pulse for stat counter
        
        dbg_port                    : out std_logic_vector(20 downto 0)
        );
end component uart_top;


component LPDDR_FIFO_IF
Port(
	i_clk                           :in  std_logic;
	i_reset                         :in  std_logic;
    
    s_tx_fifo_almost_full_tlm       :in  std_logic;                     -- output from UART_TOP UART_TX_FIFO
    o_tx_dv_tlm_s                   :out std_logic;                     -- output to the TX FIFO
	adc_data_tx_byte		        :out std_logic_vector(7 downto 0);  -- 8-bit adc data slice for serial port
    
    msc_read_adc_fifo_1		        :in  std_logic; 
    rd_en_adc_fifo_1			    :out std_logic;
	adc_data_rd_1      		        :in  std_logic_vector(11 downto 0); -- data from the adc_FIFO
    adc_fifo_empty_1                :in  std_logic;                     --output from adc fifo 
    
    msc_read_adc_fifo_2		        :in  std_logic; 
    rd_en_adc_fifo_2			    :out std_logic;
	adc_data_rd_2      		        :in  std_logic_vector(11 downto 0); -- data from the adc_FIFO
    adc_fifo_empty_2                :in  std_logic;                     --output from adc fifo 
    
    msc_read_peak_fifo_1		    :in  std_logic; 
    rd_en_peak_fifo_1			    :out std_logic;
	peak_data_rd_1       		    :in  std_logic_vector(11 downto 0); -- data from the adc_FIFO
    peak_fifo_empty_1               :in  std_logic;                     --output from adc fifo 

    msc_read_peak_fifo_2		    :in  std_logic; 
    rd_en_peak_fifo_2			    :out std_logic;
	peak_data_rd_2     		        :in  std_logic_vector(11 downto 0); -- data from the adc_FIFO
    peak_fifo_empty_2               :in  std_logic                      --output from adc fifo 
    
	);

end component LPDDR_FIFO_IF;


--+----------
-- Start of architecture code
--+----------
begin
 
 ADC_CLK_1 <= AdcClk_s1;
 ADC_CLK_2 <= AdcClk_s2;
 
 TX<=  Tx_s;
 Rx_s<=  RX;
 
 ADC_D1_s      <=   ADC_D1;   
 ADC_DR1_s     <=   ADC_DR1;
 ADC_D2_s      <=   ADC_D2 ;
 ADC_DR2_s     <=   ADC_DR2;
 
  --+--------------
  --   HeartBeatProc
  --      provides a ~60bpm pulse
  --+--------------
HeartBeatProc: process(CLK100_P)
begin
    if (rising_edge(CLK100_P)) then
     if (RST='1') then
        ON_LED_HEARTBEAT    <= '0';
        cnt_s      <=(others=>'0');
     else
       cnt_s<=cnt_s+1;
       if (cnt_s = x"0000000") then
         ON_LED_HEARTBEAT    <= '0';
       elsif(cnt_s = x"7FFFFFF")then 
         ON_LED_HEARTBEAT    <= '1';
       end if;
      end if;
    end if;
end process HeartBeatProc; 
  
cmn_timer_inst: cmn_timer
port map 
(
  clk      =>  CLK100_P,
  rst      =>  RST,
  strobes  =>  strobes
);

reset_delay_inst: reset_delay 
 generic map (
        DELAY               => 80,    -- Reset delay in clock cycles   
        RESET_IN_POLARITY   => '0',  --active high reset for Xilinx Dev board 
        RESET_OUT_POLARITY  => '1'   --active high internal reset
    )
port map(        
        clk              => CLK100_P,
        RST_in           => sys_rst, 		  -- External Power-On Reset        
        RST_out          => RST,               -- Output internal Reset
        i_msc_soft_reset => i_soft_reset
);


DataCtrl_inst : DataCtrl
  port map (
       CLK100        =>  CLK100_P    ,
       RST           =>  RST         ,
       
       ADC_D1_d        =>  ADC_D1_s      , 
       ADC_DR1_d       =>  ADC_DR1_s     ,

       ADC_D2_d        =>  ADC_D2_s      ,
       ADC_DR2_d       =>  ADC_DR2_s     ,
       
       PEAK_FL_C1    =>  PEAK_FL_C1_s  ,

       PEAK_C1       =>  PEAK_C1_s     ,
       PEAK_C2       =>  PEAK_C2_s     ,

       TIMESTAMP_C1  =>  TIMESTAMP_C1_s,
       TIMESTAMP_C2  =>  TIMESTAMP_C2_s,
       
       i_PEAK_THD     =>  s_PEAK_THD,
       i_PEAK_THD_pos =>  s_PEAK_THD_pos,
       
       i_DR1_EN      =>  s_DR1_EN, 
       i_DR2_EN      =>  s_DR2_EN,

       ADC_CLK_1            =>     AdcClk_s1,   
       ADC_CLK_2            =>     AdcClk_s2,   
	   i_stop_req           =>     i_stop_req,
       mtime_over           =>     s_mtime_over,
       
       rd_en_adc_fifo_1     =>     rd_en_adc_fifo_1,   
       rd_en_adc_fifo_2     =>     rd_en_adc_fifo_2,    
                                    
       adc_fifo_empty_1     =>     adc_fifo_empty_1,   
       adc_fifo_empty_2     =>     adc_fifo_empty_2,    
                                   
       adc_fifo_data_out_1  =>     adc_fifo_data_out_1,
       adc_fifo_data_out_2  =>     adc_fifo_data_out_2,
       
       rd_en_peak_fifo_1     => rd_en_peak_fifo_1    , 
       rd_en_peak_fifo_2     => rd_en_peak_fifo_2    ,
            
       peak_fifo_empty_1     => peak_fifo_empty_1    ,
       peak_fifo_empty_2     => peak_fifo_empty_2    ,
       
       peak_fifo_data_out_1  => peak_fifo_data_out_1 ,
       peak_fifo_data_out_2  => peak_fifo_data_out_2

);
  

Master_ctrl_inst : Master_ctrl

 port map(
    --clk and reset
    i_reset                                  =>  RST ,
    i_clk                                    =>  CLK100_P ,
    i_strobe_1ms                             =>  strobes.strobe_1ms,
    i_strobe_100ms                           =>  strobes.strobe_100ms     ,
                                                    
    --UART Tx interface                              
    o_uart_tx_byte                           =>  o_tx_byte_cmd            ,
    o_uart_tx_dv                             =>  o_tx_dv_cmd              ,
    i_uart_tx_fifo_full                      =>  o_tx_fifo_full_cmd       ,
    i_uart_tx_done                           =>  o_tx_done                ,

    --UART Rx interface                              
    i_uart_rx_pkt_avail                      =>  o_rx_pkt_avail           , 
    o_uart_rx_byte_req                       =>  i_rx_byte_rd_req         ,
    i_uart_rx_dv                             =>  o_rx_byte_rd_dv          ,
    i_uart_rx_byte                           =>  o_rx_byte_rd_data        ,
    i_uart_rx_fifo_empty                     =>  o_rx_fifo_empty          ,
    i_urx_parity_err                         =>  o_rx_parity_err          ,
    
    o_PEAK_THD                               =>  s_PEAK_THD,
    o_PEAK_THD_pos                           =>  s_PEAK_THD_pos,
         
    o_DR1_EN                                 =>  s_DR1_EN, 
    o_DR2_EN                                 =>  s_DR2_EN,
    
    --System time to other blocks                  
    o_system_time_msec_cnt                  =>   o_system_time_msec_cnt,
	--Stop Control
	o_stop_req                              =>   i_stop_req,
    o_mtime_over                            =>   s_mtime_over,
    
    o_adc_dump_req_1                        =>   i_adc_dump_req_1,
    o_adc_dump_req_2                        =>   i_adc_dump_req_2,
    
    o_peak_dump_req_1                       =>  i_peak_dump_req_1,
    o_peak_dump_req_2                       =>  i_peak_dump_req_2,
    
    o_soft_reset                            =>  i_soft_reset,

	o_ddr_read_addr_reg0                    =>   i_ddr_read_addr_reg0  ,
    o_ddr_read_addr_reg1                    =>   i_ddr_read_addr_reg1  ,
    o_ddr_read_length_reg0                  =>   i_ddr_read_length_reg0,
    o_ddr_read_length_reg1                  =>   i_ddr_read_length_reg1,
                                
    o_rx_error                              =>   o_rx_error,
    o_dbg_port                              =>   o_dbg_port,
    LED_M                                   =>   LED_M

  
    );
  
  
 uart_top_inst : uart_top
 port map(
 
    i_reset                    =>     RST,   
    i_clk                      =>     CLK100_P,
    i_strobe_100ms             =>     i_strobe_100ms          ,
    i_ddr4_clk                 =>     o_ddr4_clk              ,

    o_tx_fifo_almost_full_tlm  =>     o_tx_fifo_almost_full_tlm ,
    o_tx_fifo_full_cmd         =>     o_tx_fifo_full_cmd      ,
    o_tx_done                  =>     o_tx_done               ,
    o_rx_pkt_avail             =>     o_rx_pkt_avail          ,
    i_rx_byte_rd_req           =>     i_rx_byte_rd_req        ,
    o_rx_byte_rd_dv            =>     o_rx_byte_rd_dv         ,
    o_rx_byte_rd_data          =>     o_rx_byte_rd_data       ,
    o_rx_fifo_empty            =>     o_rx_fifo_empty         ,
    o_rx_parity_err            =>     o_rx_parity_err         ,
    
    i_tx_byte_tlm              =>     o_tx_byte_tlm           ,
    i_tx_dv_tlm                =>     o_tx_dv_tlm             ,
    i_tx_byte_cmd              =>     o_tx_byte_cmd           ,
    i_tx_dv_cmd                =>     o_tx_dv_cmd             ,

    i_rx_serial                =>     Rx_s             ,
    o_tx_serial                =>     Tx_s             ,
    o_cmd_pkt_drop_tick        =>     o_cmd_pkt_drop_tick     ,
    dbg_port                   =>     dbg_port

 );
 
 
    LPDDR_FIFO_IF_inst : LPDDR_FIFO_IF
    Port map(
	i_clk                       =>  CLK100_P,
	i_reset                     =>  RST,
    --serial interface
    
    s_tx_fifo_almost_full_tlm   =>  o_tx_fifo_almost_full_tlm,
    o_tx_dv_tlm_s               =>  o_tx_dv_tlm,
    adc_data_tx_byte		    =>  o_tx_byte_tlm,
    
    --fifo interface
    
	msc_read_adc_fifo_1		    =>  i_adc_dump_req_1,
    adc_data_rd_1      		    =>  adc_fifo_data_out_1,
    adc_fifo_empty_1            =>  adc_fifo_empty_1,
	rd_en_adc_fifo_1			=>  rd_en_adc_fifo_1,

	msc_read_adc_fifo_2		    =>  i_adc_dump_req_2,
    adc_data_rd_2      		    =>  adc_fifo_data_out_2,
    adc_fifo_empty_2            =>  adc_fifo_empty_2,
	rd_en_adc_fifo_2			=>  rd_en_adc_fifo_2,
    
    msc_read_peak_fifo_1		=>  i_peak_dump_req_1,
    peak_data_rd_1      		=>  peak_fifo_data_out_1,
    peak_fifo_empty_1           =>  peak_fifo_empty_1,
	rd_en_peak_fifo_1			=>  rd_en_peak_fifo_1,

	msc_read_peak_fifo_2		=>  i_peak_dump_req_2,
    peak_data_rd_2      		=>  peak_fifo_data_out_2,
    peak_fifo_empty_2           =>  peak_fifo_empty_2,
	rd_en_peak_fifo_2			=>  rd_en_peak_fifo_2
    
	);

end k7_ddr3_top_RTL;
