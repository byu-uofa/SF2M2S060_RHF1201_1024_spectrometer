-- ----------------------------------------------------------------------------
--              : Copyright (C) 2019 COM DEV International. All rights
--              : reserved. Use is subject to COM DEV International's
--              : standard license terms. Unauthorized duplication or
--              : distribution is strictly prohibited. Permission to use,
--              : copy, and distribute any of the information herein is
--              : subject to COM DEV International prior written consent.
-- ----------------------------------------------------------------------------
-- File Name    : master_ctrl.vhd
--              :
-- Project      : P_SWEPT
-- Author       : Muhammad Amjad
-- Created      : Jun 12, 2022
--
-- Description  : Master FSM: Prvides main interface to the Command and Telemetry. communicates with all blocks of the design
--
-- SVN keywords : $Rev: $
--                $Author: $
--                $Date:  $
-- -----------------------------------------------------------------------------
-- Revision history : 
--   Ver   | Author             | Mod. Date     |    Changes Made:
--   v0.1  | M. Amjad           | Jun 12, 2022  |    Initial Creation

-- -----------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_STD.all;

library work;
use work.p_swept_pkg.all;
use work.p_swept_cmds_pkg.all;

entity master_ctrl is
  generic (
    g_VERSION                 : std_logic_vector(7 downto 0):=x"01"; --Version number X.X (hex)
    g_DAY                     : integer:= 30;                        --build code register (day)
    g_MONTH                   : integer:= 08;                        --build code register (month)
    g_YEAR                    : integer:= 22                         --build code register (year)
    );
  port(
    --clk and reset
    i_reset                    : in  std_logic;
    i_clk                      : in  std_logic;
    i_strobe_1ms               : in  std_logic;
    i_strobe_100ms             : in  std_logic;
            
    --UART cmd Tx interface
    o_uart_tx_byte             : out std_logic_vector(7 downto 0);
    o_uart_tx_dv               : out std_logic;
    i_uart_tx_fifo_full        : in std_logic;
    i_uart_tx_done             : in std_logic;
    
    --UART Rx interface
    i_uart_rx_pkt_avail        : in std_logic;
    o_uart_rx_byte_req         : out std_logic;
    i_uart_rx_dv               : in std_logic;
    i_uart_rx_byte             : in std_logic_vector(7 downto 0);
    i_uart_rx_fifo_empty       : in std_logic;
    i_urx_parity_err           : in std_logic;
    
    o_PEAK_THD                 : out std_logic_vector(11 downto 0);
    o_PEAK_THD_pos             : out std_logic_vector(11 downto 0);
    
    o_DR1_EN                   : out std_logic;
    o_DR2_EN                   : out std_logic;

    --System time to other blocks
    o_system_time_msec_cnt     : out std_logic_vector(31 downto 0);
    
    ----Control/Status Register interface
	-- Stop control
	
	o_stop_req                 : out std_logic; 
	o_mtime_over			   : out std_logic; 
    
    o_adc_dump_req_1           : out std_logic;     -- positive pulse energy bin values dumping
    o_adc_dump_req_2           : out std_logic;     -- negative pulse energy bin values dumping
    o_peak_dump_req_1          : out std_logic;     -- 2k positive peaks energy bin values dumping
    o_peak_dump_req_2          : out std_logic;     -- 2k negative peaks energy bin values dumping
    
    o_soft_reset                : out std_logic;
    
    --i_tx_done_msc_flag          : in std_logic;
    o_rx_error                 : out std_logic;   -- may be multiple pulses
--    o_dbg_mux_ctrl             : out std_logic_vector(2 downto 0);
    o_dbg_port                 : out std_logic_vector(15 downto 0);
    LED_M                      :out std_logic
    
    );
end master_ctrl;

-- ----------------------------------------------------------------------------- 
architecture rtl of master_ctrl is
attribute syn_preserve : boolean;
attribute syn_preserve of rtl: architecture is true;

type T_MSTR_CTRL_STATE_TYPE is      ( ST_CTRL_IDLE,  ST_INT_PROC,
                                    ST_CMD_PROC,   ST_WRITE_REG,
                                    ST_WRITE_DONE, ST_WAIT,
                                    ST_READ_REG,   ST_CATCH_VALUE,
                                    ST_READ_DDR,   ST_READ_DDR_HS,
                                    ST_DELAY_1CYCLE
                                    );

type T_UART_RX_STATE_TYPE is        ( ST_CMD_IDLE,          --ST_RX_WAIT,
                                    ST_CMD_HEADER,          ST_CMD_FUN_CODE,
                                    ST_CMD_DROP_PKT,        ST_CMD_ADDR_PARM_B1,
                                    ST_CMD_ADDR_PARM_B0,    ST_CMD_DATA_PARM_B3,
                                    ST_CMD_DATA_PARM_B2,    ST_CMD_DATA_PARM_B1,
                                    ST_CMD_DATA_PARM_B0,    ST_CMD_TRAILER_B1,
                                    ST_CMD_TRAILER_B0,      ST_CMD_CHECK_CRC,
                                    ST_CHK_FUN_CODE,        ST_STATUS_UPDATE,
                                    ST_CMD_EXE_REQ
                                    );

type T_UART_TX_STATE_TYPE is        ( ST_RESP_IDLE,         ST_RESP_CHECK,
                                    ST_RESP_HEADER,         ST_RESP_FUN_CODE,
                                    ST_RESP_ADDR_B1,        ST_RESP_ADDR_B0,
                                    ST_RESP_PARAM_B3,       ST_RESP_PARAM_B2,
                                    ST_RESP_PARAM_B1,       ST_RESP_PARAM_B0,
                                    ST_RESP_TRAILER_B1,     ST_RESP_TRAILER_B0,
									ST_MEM_RD_DATA_TNSMIT,  ST_MEM_RD_SHIFT_OUT_B7,
									ST_MEM_RD_SHIFT_OUT_B6,ST_MEM_RD_SHIFT_OUT_B5, 
									ST_MEM_RD_SHIFT_OUT_B4,ST_MEM_RD_SHIFT_OUT_B3, 
									ST_MEM_RD_SHIFT_OUT_B2,ST_MEM_RD_SHIFT_OUT_B1, 
									ST_MEM_RD_SHIFT_OUT_B0
                                    );
 
 --type T_UVIC_OP_MODES_STATE_TYPE is (ST_OP_MODE_IDLE, ST_OP_MODE_IMAGING,
 --                                   ST_OP_MODE_DCONT, ST_OP_MODE_DEPLOYMENT,
 --                                   ST_OP_MODE_MAINT  --, ST_OP_MODE_DEBUG
 --                                   );
 --                                   
 
 signal sm_mstr_ctrl_state     : T_MSTR_CTRL_STATE_TYPE;
 signal sm_uart_rx_state       : T_UART_RX_STATE_TYPE;
 signal sm_uart_tx_state       : T_UART_TX_STATE_TYPE;
 --signal sm_uvic_op_modes_state : T_UVIC_OP_MODES_STATE_TYPE;

-- -----------------------------------------------------------------------------
 signal s_uvic_fpga_build_ver_reg  : std_logic_vector(7 downto 0);
 signal s_uvic_fpga_build_day_reg  : std_logic_vector(7 downto 0);
 signal s_uvic_fpga_build_month_reg: std_logic_vector(7 downto 0);
 signal s_uvic_fpga_build_year_reg : std_logic_vector(7 downto 0);

 --signal s_din                   : std_logic_vector(PCB_REG_WIDTH-1 downto 0);
 --signal s_dout                  : std_logic_vector(PCB_REG_WIDTH-1 downto 0);
 --signal s_dout_valid            : std_logic;
 signal s_write_ena             : std_logic;
 signal s_reg_read_valid        : std_logic;
 signal s_reg_addr              : std_logic_vector(PCB_ADDR_WIDTH-1 downto 0);
 --signal s_periph_id             : std_logic_vector(PCB_PERIPH_ID_WIDTH-1 downto 0);
 --signal s_int_flags             : std_logic_vector(PCB_PSEL_WIDTH-1 downto 0);
 --signal s_clear_int             : std_logic_vector(PCB_PSEL_WIDTH-1 downto 0);
 --signal s_busy                  : std_logic;
 --
 signal s_int_response             : std_logic;
 
 signal s_cmd_rdy_clr           : std_logic;
 signal s_cmd_reg_value         : std_logic_vector(31 downto 0);
 signal s_cmd_rdy               : std_logic;
 signal s_rx_error              : std_logic;
 --signal s_cmd_periph_id         : T_PCB_PEPH_ID_TYP(0 to 9);    --std_logic_vector(PCB_PERIPH_ID_WIDTH-1 downto 0);
 signal s_wr_reg_data           : std_logic_vector(31 downto 0);
 signal s_wr_reg_addr           : std_logic_vector(15 downto 0);
 signal s_max_wr_cmds_cnt       : integer range 0 to 10;
 signal s_wr_cmds_cnt           : integer range 0 to 10;
 signal s_cmd_reg_addr          : std_logic_vector(15 downto 0);
 signal s_rd_reg_reponse        : std_logic;
 --signal s_general_int_req       : std_logic;
 signal s_resp_reg_value        : std_logic_vector(31 downto 0);
 
 signal s_rd_reg_addr           : std_logic_vector(15 downto 0);
 signal s_chk_fun_code          : std_logic;
 signal s_rx_crc_init           : std_logic;
 signal s_cmd_hdr_error         : std_logic;
 signal s_pkt_byte_cnt          : integer range 0 to 15;
 signal s_cmd_fun_code          : std_logic_vector(7 downto 0);
 signal s_cmd_pkt_crc_gen       : std_logic_vector(15 downto 0);
 signal s_cmd_pkt_crc_rcvd      : std_logic_vector(15 downto 0);
 signal s_cmd_pkt_vld           : std_logic;
 signal s_cmd_pkt_error         : std_logic;
 signal s_cmd_fun_code_vld       : std_logic;
 signal s_cmd_fun_code_error    : std_logic;
 signal s_fsm_watchdog_ms_cnt   : integer range 0 to 15;
 signal s_tx_crc_gen            : std_logic_vector(15 downto 0);
 signal s_tx_crc_gen_old        : std_logic_vector(15 downto 0);
 signal s_tx_crc_init           : std_logic;
 signal s_8bit_data_in          : std_logic_vector(7 downto 0);
 signal s_8bit_data_in_vld      : std_logic;
 signal s_crc_calc_enable       : std_logic;
 signal s_uart_tx_byte          : std_logic_vector(7 downto 0);
 signal s_uart_tx_dv            : std_logic;
 signal s_rw_enable             : std_logic;
 
 --stat counter signals
 signal s_cmd_pkt_err_cnt_incr    : std_logic;
 signal s_cmd_pkt_reject_cnt_incr : std_logic;
 signal s_cmd_pkt_reject_cnt_clr  : std_logic;
 signal s_cmd_pkt_reject_cnt      : std_logic_vector(C_ERROR_PKT_CNTR_WIDTH-1 downto 0);
 signal s_good_cmd_pkt_cnt_incr   : std_logic;
 signal s_cmd_pkt_accept_cnt_incr : std_logic;
 signal s_cmd_pkt_accept_cnt_clr  : std_logic;
 signal s_cmd_pkt_accept_cnt      : std_logic_vector(C_GOOD_PKT_CNTR_WIDTH-1 downto 0);
 signal s_msec_elapse_time_cnt    : std_logic_vector(C_ELAPSE_TIME_CNTR_WIDTH-1 downto 0);
 signal s_uart_rx_parity_err_cnt  : std_logic_vector(C_UART_RX_PARITY_ERR_CNTR_WIDTH-1 downto 0);
 signal i_cntr_tick               : std_logic;
 signal s_uvic_state_code         : std_logic_vector(7 downto 0);
 signal s_last_cmd_accept_fc      : std_logic_vector(7 downto 0);
 signal s_last_cmd_reject_fc      : std_logic_vector(7 downto 0);
 signal s_cmd_op_state_vld        : std_logic;
 --signal s_cmd_op_state_vld: std_logic;
 
 --mode control signals
 --signal s_cmd_enter_mode_imaging: std_logic;
 signal s_cmd_enter_mode_dcontam: std_logic;
 signal s_cmd_enter_mode_deploy : std_logic;
 signal s_cmd_enter_mode_maint  : std_logic;
 signal s_cmd_enter_mode_dbg    : std_logic;
 signal s_cmd_enter_mode_idle   : std_logic;
 
 signal ctrl_reg_array          : CTRL_REGS_T:=MASTER_FSM_DEFAULT_REG_VALUES; --(others => (others => '0'));
 --signal ddr_if_reg_array        : CTRL_REGS_T(0 to NUM_DDR_IF_REG-1):=DDR_DEFAULT_REG_VALUES; --(others => (others => '0'));
 
 constant UNIT_ID               : std_logic_vector(3 downto 0):="0010";
 
 signal dbg_rcv_state               : std_logic_vector(7  downto 0);
 signal dbg_mstr_state              : std_logic_vector(7  downto 0);
 signal dbg_tx_state                : std_logic_vector(7  downto 0);
 signal s_threshold_reg				: std_logic_vector(NibbleSize-1 downto 0):=x"5";
 signal int_reg_addr				: integer:=0;
 signal s_mem_dump					: std_logic;
 signal s_mem_dump_d1				: std_logic;
 signal s_mem_dump_req				: std_logic;
 signal s_ddr_wrd					: std_logic_vector(63 downto 0);
-- signal s_uart_words_sent_cnt       : integer  ;

 signal s_stop                      : std_logic:= '1'; 
 
 signal dump_zero                   : std_logic_vector(7 downto 0):= x"00";  
 signal cnt_s    :std_logic_vector(27 downto 0):=(others=>'0');       
 
 signal s_adc_dump_1                : std_logic:='0';
 signal s_adc_dump_2                : std_logic:='0';
 
 signal s_peak_dump_1               : std_logic:='0';
 signal s_peak_dump_2               : std_logic:='0';
 
 signal s_soft_reset                : std_logic:='0';
 

 signal m_time_sec_freq		:std_logic_vector(27 downto 0);
 signal m_time_full_cnt_value :std_logic_vector(27 downto 0);
 signal mtime_sec_counter	:std_logic_vector(15 downto 0);
 signal mtime_start			:std_logic;
 signal mtime_cnt_done		:std_logic;
 signal mtime_cnt_done_s1	:std_logic;
 signal mtime_cnt_done_ris	:std_logic;
 signal mtime_preset        :std_logic_vector(15 downto 0);
 
  --------------------------------------------------------------------------------
begin

-- peak detection parameters output assignments
 o_PEAK_THD              <= ctrl_reg_array(P_SWEPT_PEAK_THD_REG )(11 downto 0)          ;
 o_PEAK_THD_pos          <= ctrl_reg_array(P_SWEPT_PEAK_THD_POS_REG )(11 downto 0)      ;
 o_DR1_EN                <= ctrl_reg_array(P_SWEPT_DR1_REG )(0)      ;
 o_DR2_EN                <= ctrl_reg_array(P_SWEPT_DR2_REG )(0)      ;

 o_uart_tx_byte           <= s_uart_tx_byte;
 o_uart_tx_dv             <= s_uart_tx_dv;

 o_adc_dump_req_1         <= s_adc_dump_1;
 o_adc_dump_req_2         <= s_adc_dump_2;
 o_peak_dump_req_1        <= s_peak_dump_1;
 o_peak_dump_req_2        <= s_peak_dump_2;

-- measurement control output assignment 
 o_soft_reset             <= s_soft_reset;
 o_stop_req               <= s_stop;
 o_mtime_over             <= mtime_cnt_done;
 
 --o_rd_reg_reponse <= s_rd_reg_reponse;
 o_rx_error               <= s_rx_error;
 
 int_reg_addr <=to_integer(unsigned(s_reg_addr));
 
 mtime_preset <=  ctrl_reg_array(RADICAL_MTIME_PRESET_VALUE)(15 downto 0);
 m_time_full_cnt_value <=  ctrl_reg_array(RADICAL_MTIME_FULL_CNT_VALUE)(27 downto 0);

-- *********************************************************************************************** time counter process **********************************************************************************************************************
mtime_start_Rising_Proc: process (i_reset, i_clk)
begin
    if (rising_edge(i_clk)) then
     if (i_reset='1') then
        mtime_start    <= '0';
		s_stop    	   <= '1';
     elsif(ctrl_reg_array(RADICAL_MTIME_START_CTRL_REG)(0) = '1' and mtime_cnt_done = '0') then
        mtime_start    <= '1';     
		s_stop    	   <= '0';		
     else
        mtime_start    <= '0';
		s_stop    	   <= '1';		
     end if;
   end if;
 end process mtime_start_Rising_Proc;

mtime_sec_freq_proc : process (i_reset, i_clk)
begin

     if (i_reset='1') then
		m_time_sec_freq   <= (others => '0');    
		mtime_sec_counter <= (others => '0'); 
		mtime_cnt_done 	  <= '0';		
     elsif rising_edge(i_clk) then

		if(mtime_start = '1' and mtime_cnt_done = '0') then
			if(mtime_sec_counter < mtime_preset) then
				if(m_time_sec_freq = m_time_full_cnt_value) then            -- x"0000063" 1000 ns = 1us 25 samples, (4us = 100 samples)/peak, 1000 us = 250 peaks
					m_time_sec_freq   <= (others => '0'); 
					mtime_sec_counter <= mtime_sec_counter + '1';
				else
					m_time_sec_freq   <= m_time_sec_freq + '1';
				end if;
			else
					mtime_sec_counter <= (others=> '0');
					mtime_cnt_done 	  <= '1';
			end if;
		end if;
     end if;
	 
 end process mtime_sec_freq_proc;	

 
--************************************************************************************************ adc raw data dump process *****************************************************************************************************************
adc_data_dump_proc_1: process(i_reset, i_clk)
begin
    if (rising_edge(i_clk)) then
     if (i_reset='1') then
        s_adc_dump_1              <= '0';
     elsif(ctrl_reg_array(P_SWEPT_DUMP_CH1_REG)(0) = '1') then
        s_adc_dump_1              <= '1';           
     else
        s_adc_dump_1              <= '0';
     end if;
   end if;
 end process adc_data_dump_proc_1;
 
 adc_data_dump_proc_2: process(i_reset, i_clk)
begin
    if (rising_edge(i_clk)) then
     if (i_reset='1') then
        s_adc_dump_2              <= '0';
     elsif(ctrl_reg_array(P_SWEPT_DUMP_CH2_REG)(0) = '1') then
        s_adc_dump_2              <= '1';           
     else
        s_adc_dump_2              <= '0';
     end if;
   end if;
 end process adc_data_dump_proc_2;
 --***************************************************************************************** peak dump command ********************************************************************************************************************************
peak_data_dump_proc_1: process(i_reset, i_clk)
begin
    if (rising_edge(i_clk)) then
     if (i_reset='1') then
        s_peak_dump_1              <= '0';
     elsif(ctrl_reg_array(P_SWEPT_DUMP_PEAK1_REG)(0) = '1') then
        s_peak_dump_1              <= '1';           
     else
        s_peak_dump_1              <= '0';
     end if;
   end if;
 end process peak_data_dump_proc_1;
 
peak_data_dump_proc_2: process(i_reset, i_clk)
begin
    if (rising_edge(i_clk)) then
     if (i_reset='1') then
        s_peak_dump_2              <= '0';
     elsif(ctrl_reg_array(P_SWEPT_DUMP_PEAK2_REG)(0) = '1') then
        s_peak_dump_2              <= '1';           
     else
        s_peak_dump_2              <= '0';
     end if;
   end if;
 end process peak_data_dump_proc_2;
 
 --************************************************************************************** Software reset *************************************************************************************************************************************************************************
 
reset_dec_proc: process(i_reset, i_clk)
begin
    if (rising_edge(i_clk)) then
     if (i_reset='1') then
        s_soft_reset              <= '0';
     elsif(ctrl_reg_array(P_SWEPT_RESET)(0) = '1') then
        s_soft_reset              <= '1';           
     else
        s_soft_reset              <= '0';
     end if;
   end if;
 end process reset_dec_proc;

--*************************************************************************************** master control fsm *******************************************************************************************************************************

master_ctrl_fsm: process (i_reset, i_clk)
begin
    if i_reset = '1' then
        --s_clear_int         <= (others => '0');
        s_int_response      <= '0';
        --s_din               <= (others => '0');
        s_reg_addr          <= (others => '0');
        --s_periph_id         <= (others => '0');
        --s_ddr_uart_read_req<= '0';
        s_cmd_rdy_clr       <= '0';
        s_write_ena         <= '0';
        --s_read_ena          <= '0';
        s_resp_reg_value    <= (others => '0');
        s_wr_cmds_cnt       <= 0;
        sm_mstr_ctrl_state  <= ST_CTRL_IDLE;
        dbg_mstr_state      <= x"00";
		s_reg_read_valid 	<= '0';

		
		ctrl_reg_array(P_SWEPT_FPGA_BUILD_VER_REG)      <= x"000000" & g_VERSION;
		ctrl_reg_array(P_SWEPT_FPGA_BUILD_DAY_REG)      <= x"000000" & std_logic_vector(to_unsigned(g_DAY,8));
		ctrl_reg_array(P_SWEPT_FPGA_BUILD_MONTH_REG)    <= x"000000" & std_logic_vector(to_unsigned(g_MONTH, 8)); 
		ctrl_reg_array(P_SWEPT_FPGA_BUILD_YEAR_REG)     <= x"000000" & std_logic_vector(to_unsigned(g_YEAR, 8));  
        
        LED_M <= '0';
        
        ctrl_reg_array(P_SWEPT_PEAK_THD_REG)          <=  x"000007FA"; 
        ctrl_reg_array(P_SWEPT_PEAK_THD_POS_REG)      <=  x"000007FA";
        
        ctrl_reg_array(P_SWEPT_DR1_REG)               <=  x"00000000"; 
        ctrl_reg_array(P_SWEPT_DR2_REG)               <=  x"00000000"; 

        ctrl_reg_array(RADICAL_MTIME_START_CTRL_REG)  <=  x"00000000";
        ctrl_reg_array(RADICAL_MTIME_PRESET_VALUE)    <=  x"00000001";
        ctrl_reg_array(RADICAL_MTIME_FULL_CNT_VALUE)  <=  x"0001869F"; 
        
        ctrl_reg_array(P_SWEPT_DUMP_CH1_REG)          <=  x"00000000";
        ctrl_reg_array(P_SWEPT_DUMP_CH2_REG)          <=  x"00000000";

        ctrl_reg_array(P_SWEPT_DUMP_PEAK1_REG)        <=  x"00000000";
        ctrl_reg_array(P_SWEPT_DUMP_PEAK2_REG)        <=  x"00000000";

        ctrl_reg_array(P_SWEPT_DUMP_ALL_REG)          <=  x"00000000";
        ctrl_reg_array(P_SWEPT_RESET)                 <=  x"00000000";
        
    elsif rising_edge(i_clk) then
  
        case sm_mstr_ctrl_state is
    
            when ST_CTRL_IDLE =>
                dbg_mstr_state      <= x"01";
                --s_clear_int         <= (others => '0');
                s_int_response      <= '0';
                --s_ddr_uart_read_req <= '0';
                s_cmd_rdy_clr       <= '0';
                s_write_ena         <= '0';
                s_reg_read_valid    <= '0';
                s_wr_cmds_cnt       <= 0;
                --if(i_tx_done_msc_flag = '1') then
                --
                --ctrl_reg_array(P_SWEPT_DUMP_CH1_REG)  <= (others => '0');
                --ctrl_reg_array(P_SWEPT_DUMP_CH2_REG)  <= (others => '0');            
                --ctrl_reg_array(P_SWEPT_DUMP_PEAK1_REG)  <= (others => '0');
                --ctrl_reg_array(P_SWEPT_DUMP_PEAK2_REG)  <= (others => '0');
                --
                --end if;
                
                if s_cmd_rdy = '1' then
                    sm_mstr_ctrl_state <= ST_CMD_PROC;
                end if;

            when ST_CMD_PROC =>
                dbg_mstr_state  <= x"03";
                
                if s_rw_enable   = '1' then 
                    s_cmd_rdy_clr       <= '1'; --TBD
                    s_reg_addr          <= s_wr_reg_addr; --(15 downto 0);               --cmd_reg_addr;
                    s_wr_cmds_cnt       <= s_wr_cmds_cnt + 1;
                    sm_mstr_ctrl_state  <= ST_WRITE_REG;
                else
                    s_reg_addr          <= s_rd_reg_addr; --(15 downto 0);
                    sm_mstr_ctrl_state  <= ST_READ_REG;
                end if;
            
            when ST_WRITE_REG =>
                dbg_mstr_state          <= x"04";
				case int_reg_addr is
                    
					when P_SWEPT_FPGA_THRESHOLD_CH1_REG =>                                             --4
						ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH1_REG)                  <= s_wr_reg_data;          -- 16 bits reg data   
					when P_SWEPT_FPGA_THRESHOLD_CH2_REG =>                                             --5
						ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH2_REG)              	<= s_wr_reg_data;
					when P_SWEPT_FPGA_THRESHOLD_CH3_REG =>                                             --6
						ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH3_REG)              	<= s_wr_reg_data;
					when P_SWEPT_FPGA_THRESHOLD_CH4_REG =>                                             --7
						ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH4_REG)              	<= s_wr_reg_data;	       
					    
					when P_SWEPT_DUMP_ALL_REG =>                                                  
						ctrl_reg_array(P_SWEPT_DUMP_ALL_REG)   		                    <= s_wr_reg_data;       
					when P_SWEPT_DUMP_CH1_REG =>                                                  
						ctrl_reg_array(P_SWEPT_DUMP_CH1_REG)   		                    <= s_wr_reg_data;
					when P_SWEPT_DUMP_CH2_REG =>                                                  
						ctrl_reg_array(P_SWEPT_DUMP_CH2_REG)   		                    <= s_wr_reg_data;
                    when P_SWEPT_DUMP_PEAK1_REG =>                                                  
						ctrl_reg_array(P_SWEPT_DUMP_PEAK1_REG)   		                <= s_wr_reg_data;
					when P_SWEPT_DUMP_PEAK2_REG =>                                                  
						ctrl_reg_array(P_SWEPT_DUMP_PEAK2_REG)   		                <= s_wr_reg_data;
                    when RADICAL_MTIME_START_CTRL_REG =>
						ctrl_reg_array(RADICAL_MTIME_START_CTRL_REG)   		            <= s_wr_reg_data;     
                    when RADICAL_MTIME_PRESET_VALUE =>
						ctrl_reg_array(RADICAL_MTIME_PRESET_VALUE)   		            <= s_wr_reg_data;   

                    when RADICAL_MTIME_FULL_CNT_VALUE =>
						ctrl_reg_array(RADICAL_MTIME_FULL_CNT_VALUE)   		            <= s_wr_reg_data; 
                        
					when P_SWEPT_PEAK_THD_REG     =>    ctrl_reg_array(P_SWEPT_PEAK_THD_REG)   	        <= s_wr_reg_data;   
					when P_SWEPT_PEAK_THD_POS_REG =>    ctrl_reg_array(P_SWEPT_PEAK_THD_POS_REG)   	    <= s_wr_reg_data;   
                    
				    when P_SWEPT_DR1_REG =>
                        LED_M <= '1';
				        ctrl_reg_array(P_SWEPT_DR1_REG)                     <= s_wr_reg_data;
				    when P_SWEPT_DR2_REG =>
				        ctrl_reg_array(P_SWEPT_DR2_REG)                     <= s_wr_reg_data;				    
                        
				    when P_SWEPT_RESET =>		
				        ctrl_reg_array(P_SWEPT_RESET)                       <= s_wr_reg_data;	
                        
					when others => null;
				end case;		
          
                sm_mstr_ctrl_state      <= ST_CTRL_IDLE;
        
            when ST_READ_REG =>
                dbg_mstr_state  <= x"07";
                s_reg_read_valid <= '1';
				
				case int_reg_addr is 	
					when P_SWEPT_FPGA_BUILD_VER_REG =>
						s_resp_reg_value	<= ctrl_reg_array(P_SWEPT_FPGA_BUILD_VER_REG);
					when P_SWEPT_FPGA_BUILD_DAY_REG =>     
						s_resp_reg_value	<= ctrl_reg_array(P_SWEPT_FPGA_BUILD_DAY_REG);
					when P_SWEPT_FPGA_BUILD_MONTH_REG =>   
						s_resp_reg_value	<= ctrl_reg_array(P_SWEPT_FPGA_BUILD_MONTH_REG);
					when P_SWEPT_FPGA_BUILD_YEAR_REG =>    
						s_resp_reg_value	<= ctrl_reg_array(P_SWEPT_FPGA_BUILD_YEAR_REG);	
					when P_SWEPT_FPGA_THRESHOLD_CH1_REG => 
						s_resp_reg_value	<= ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH1_REG);
					when P_SWEPT_FPGA_THRESHOLD_CH2_REG => 
						s_resp_reg_value<= ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH2_REG);
					when P_SWEPT_FPGA_THRESHOLD_CH3_REG => 
						s_resp_reg_value<= ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH3_REG);
					when P_SWEPT_FPGA_THRESHOLD_CH4_REG =>
						s_resp_reg_value<= ctrl_reg_array(P_SWEPT_FPGA_THRESHOLD_CH4_REG);		

					when P_SWEPT_CMD_REJECT_CNTR_REG =>   
						s_resp_reg_value<= ctrl_reg_array(P_SWEPT_CMD_REJECT_CNTR_REG);
					when P_SWEPT_URX_PARITY_ERR_CNTR_REG =>
						s_resp_reg_value<= ctrl_reg_array(P_SWEPT_URX_PARITY_ERR_CNTR_REG);		
                        
					when RADICAL_MTIME_PRESET_VALUE =>   
						s_resp_reg_value<= ctrl_reg_array(RADICAL_MTIME_PRESET_VALUE);
					when RADICAL_MTIME_FULL_CNT_VALUE =>   
						s_resp_reg_value<= ctrl_reg_array(RADICAL_MTIME_FULL_CNT_VALUE);
                        
					when RADICAL_MTIME_START_CTRL_REG =>   
						s_resp_reg_value<= ctrl_reg_array(RADICAL_MTIME_START_CTRL_REG);
                        
				    when P_SWEPT_PEAK_THD_REG =>
				        s_resp_reg_value <= ctrl_reg_array(P_SWEPT_PEAK_THD_REG)                ;
                        
				    when P_SWEPT_PEAK_THD_POS_REG =>
				        s_resp_reg_value <= ctrl_reg_array(P_SWEPT_PEAK_THD_POS_REG)            ;
				        
				    when P_SWEPT_DR1_REG =>
				        s_resp_reg_value <= ctrl_reg_array(P_SWEPT_DR1_REG)                     ;
				    when P_SWEPT_DR2_REG =>
				        s_resp_reg_value <= ctrl_reg_array(P_SWEPT_DR2_REG)                     ;
 
					when others => null;
				end case;
			
				sm_mstr_ctrl_state      <= ST_CTRL_IDLE;
            
            when others =>
                sm_mstr_ctrl_state  <= ST_CTRL_IDLE;
              
        end case;
    
    end if;
end process;

--------------------------------------------------------------------------------
-- Receive data from UART; and 
-- Parse data bytes based on command format:
--
--------------------------------------------------------------------------------
rcv_uart: process (i_reset, i_clk)
begin
    if i_reset = '1' then
        s_cmd_rdy           <= '0';
        o_uart_rx_byte_req  <= '0';
        s_rx_error          <= '0';
        s_cmd_reg_value     <= (others => '0');
        s_cmd_reg_addr      <= (others => '0');
        s_cmd_reg_addr      <= (others => '0');
        s_cmd_fun_code      <= (others => '0');
        s_cmd_pkt_vld       <= '0';
        s_cmd_pkt_error     <= '0';
        
        s_good_cmd_pkt_cnt_incr <= '0';
        s_cmd_pkt_err_cnt_incr  <= '0';
        
        s_cmd_pkt_crc_rcvd      <= (others => '1');
        s_cmd_hdr_error         <= '0';
        s_cmd_fun_code_error    <= '0';
        s_chk_fun_code          <= '0';
        s_rx_crc_init           <= '1';

        
        sm_uart_rx_state <= ST_CMD_IDLE;
        dbg_rcv_state               <= x"00";
      
    elsif rising_edge(i_clk) then
    
        o_uart_rx_byte_req <= '0';
        s_chk_fun_code     <= '0';
        s_good_cmd_pkt_cnt_incr <= '0';
        s_cmd_pkt_err_cnt_incr  <= '0';
        
        case sm_uart_rx_state is
            
            when ST_CMD_IDLE =>
                s_cmd_fun_code      <= (others => '0');
                dbg_rcv_state               <= x"01";
                --cmd_rdy <= '0';
                o_uart_rx_byte_req  <= '0';
                s_rx_error          <= '0';
                s_rx_crc_init       <= '1';

                if s_cmd_rdy_clr = '1' then
                    s_cmd_rdy     <= '0';
                end if;
                if i_uart_rx_pkt_avail = '1' and s_cmd_rdy = '0' then
                    o_uart_rx_byte_req   <= '1';
                    s_rx_crc_init      <= '0';
                    sm_uart_rx_state   <= ST_CMD_HEADER; 
                end if;
                
            when ST_CMD_HEADER =>
                dbg_rcv_state               <= x"02";
                o_uart_rx_byte_req <= '1';
                --if i_uart_rx_dv = '1' then
                    if i_uart_rx_byte = x"7E" then
                        sm_uart_rx_state <= ST_CMD_FUN_CODE;
                    else
                        s_cmd_hdr_error <= '1';
                        sm_uart_rx_state <= ST_CMD_DROP_PKT;
                    end if;
                --end if;
            when ST_CMD_DROP_PKT => --flush the packet from the fifo by reading reaming bytes of teh pakets
                dbg_rcv_state               <= x"03";
                o_uart_rx_byte_req <= '1';
                
                if i_uart_rx_fifo_empty = '1' then  --flush the fifo to clear all data
                    sm_uart_rx_state    <= ST_CMD_IDLE;
                    o_uart_rx_byte_req <= '0';
                end if;

            when ST_CMD_FUN_CODE =>
                dbg_rcv_state               <= x"04";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                    s_cmd_fun_code     <= i_uart_rx_byte;
                    s_chk_fun_code     <= '1';
                    sm_uart_rx_state   <= ST_CMD_ADDR_PARM_B1;
--                end if;
                
            when ST_CMD_ADDR_PARM_B1 =>
                dbg_rcv_state               <= x"05";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                    s_cmd_reg_addr(15 downto 8) <= i_uart_rx_byte;
                    sm_uart_rx_state <= ST_CMD_ADDR_PARM_B0;
--                end if;
            
            when ST_CMD_ADDR_PARM_B0 =>
                dbg_rcv_state               <= x"06";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                    s_cmd_reg_addr(7 downto 0) <= i_uart_rx_byte;
                    sm_uart_rx_state <= ST_CMD_DATA_PARM_B3;
--                end if;
                
            when ST_CMD_DATA_PARM_B3 =>
                dbg_rcv_state               <= x"07";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                s_cmd_reg_value(31 downto 24) <= i_uart_rx_byte;
                sm_uart_rx_state <= ST_CMD_DATA_PARM_B2;
--                end if;
            
            when ST_CMD_DATA_PARM_B2 =>
                dbg_rcv_state               <= x"08";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                    s_cmd_reg_value(23 downto 16) <= i_uart_rx_byte;
                    sm_uart_rx_state <= ST_CMD_DATA_PARM_B1;
--                end if;
                
            when ST_CMD_DATA_PARM_B1 =>
                dbg_rcv_state               <= x"09";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                    s_cmd_reg_value(15 downto 8) <= i_uart_rx_byte;
                    sm_uart_rx_state <= ST_CMD_DATA_PARM_B0;
--                end if;
                
            when ST_CMD_DATA_PARM_B0 =>
                dbg_rcv_state               <= x"0A";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                    s_cmd_reg_value(7 downto 0) <= i_uart_rx_byte;
                    sm_uart_rx_state <= ST_CMD_TRAILER_B1;
--                end if;
                
            when ST_CMD_TRAILER_B1 =>
                dbg_rcv_state               <= x"0B";
                o_uart_rx_byte_req <= '1';
--                if i_uart_rx_dv = '1' then
                    s_cmd_pkt_crc_rcvd(15 downto 8) <= i_uart_rx_byte;
                    sm_uart_rx_state <= ST_CMD_TRAILER_B0;
--                end if;
                
            when ST_CMD_TRAILER_B0 =>
                dbg_rcv_state               <= x"0C";
--                if i_uart_rx_dv = '1' then
                    s_cmd_pkt_crc_rcvd(7 downto 0) <= i_uart_rx_byte;
                    sm_uart_rx_state <= ST_CMD_CHECK_CRC;
--                end if;
            
            when ST_CMD_CHECK_CRC =>
                dbg_rcv_state               <= x"0D";
                sm_uart_rx_state <= ST_CHK_FUN_CODE;
                if s_cmd_pkt_crc_rcvd = x"0000" then
                    s_cmd_pkt_vld  <= '1';
                    
                elsif s_cmd_pkt_crc_rcvd = s_cmd_pkt_crc_gen then
                    s_cmd_pkt_vld  <= '1';
                else
                    s_cmd_pkt_error <= '1';
                    sm_uart_rx_state <= ST_STATUS_UPDATE;
                end if;      

            when ST_CHK_FUN_CODE => 
                dbg_rcv_state               <= x"0E";
                if s_cmd_fun_code_vld = '1' then
                    --o_uart_rx_byte_req <= '1';
                    sm_uart_rx_state   <= ST_CMD_EXE_REQ;
                 else
                    s_cmd_fun_code_error <= '1';
                end if;
            
            when ST_CMD_EXE_REQ =>
                dbg_rcv_state               <= x"0F";
                    s_cmd_rdy <= '1';
                    sm_uart_rx_state <= ST_STATUS_UPDATE;     
            when ST_STATUS_UPDATE =>
                dbg_rcv_state               <= x"10";
                s_cmd_rdy <= '0';
                sm_uart_rx_state <= ST_CMD_IDLE;
                if s_cmd_pkt_error = '1' or s_cmd_fun_code_error ='1' or s_cmd_op_state_vld = '0' then
                    s_cmd_pkt_err_cnt_incr  <= '1';
                else
                    s_good_cmd_pkt_cnt_incr <= '1';
                end if;
                 
            when others =>
                s_cmd_rdy <= '0';
                o_uart_rx_byte_req   <= '0';
                s_rx_error        <= '0';
                --s_cmd_periph_id   <= (others => '0');
                s_cmd_reg_addr     <= (others => '0');
                --s_cmd_reg_addr    <= (others => '0');
                s_cmd_reg_value    <= (others => '0');
                sm_uart_rx_state   <= ST_CMD_IDLE;

        end case;
        
        --State machine watchdog timer, reset the FSM if stuck 
        if sm_uart_rx_state /= ST_CMD_IDLE then
        
            if i_uart_rx_dv = '1' then
                s_fsm_watchdog_ms_cnt <= 0;
            
            elsif i_strobe_1ms = '1' then
                s_fsm_watchdog_ms_cnt <= s_fsm_watchdog_ms_cnt + 1;
                if s_fsm_watchdog_ms_cnt >= C_UART_FSM_WDOG_CNT_MAX then
                    sm_uart_rx_state    <= ST_CMD_IDLE;
                end if;
            end if;
         end if;
    
    end if;
end process;


-----------------------------------------------------------------------
-- Instantiate CRC generator/verifier: Generates using crc-16 CCITT
----------------------------------------------------------------------
inst_rx_crc_gen: entity work.crc16_gen 
  port map( 
    i_clk                        => i_clk,
    i_reset                      => i_reset,
    
    i_crc_init                   => s_rx_crc_init,
    
    i_8bit_data_in               => i_uart_rx_byte,     
    i_8bit_data_in_vld           => i_uart_rx_dv, 
    
    i_ref_crc_en                  => '0',
    i_ref_crc_in                  => (others => '1'),        
    
    o_crc_data_out                => s_cmd_pkt_crc_gen,    
    o_crc_data_out_vld            => open --s_cmd_pkt_crc_gen_vld 
    );
 
--------------------------------------------------------------------------------
--Stat counters 
--------------------------------------------------------------------------------
--Good command packets counter.
inst_cm_pkt_accept_cntr: entity work.cmn_cntr
generic map(
            COUNTR_WIDTH    => C_GOOD_PKT_CNTR_WIDTH
            )
  port map(
    --clk and reset
    i_reset                 => i_reset, 
    i_clk                   => i_clk,
    
    --Counter Inputs
    i_cntr_en               => '1',
    i_cntr_tick             => s_cmd_pkt_accept_cnt_incr, 
    i_cntr_reset            => s_cmd_pkt_accept_cnt_clr,
         
    --Counter Outputs
    o_cntr_out              => s_cmd_pkt_accept_cnt,
    o_cntr_overflow         => open
    );


last_cmd_accept_latch: process(i_reset, i_clk)
begin
    if i_reset = '1' then
        s_last_cmd_accept_fc  <= x"00";
    elsif rising_edge(i_clk) then
        if s_cmd_pkt_accept_cnt_incr = '1' then
            s_last_cmd_accept_fc  <= s_cmd_fun_code;
        end if;
    end if;
end process;    
   
    
--cmd packet reject counter.
inst_cmd_pkt_reject_cntr: entity work.cmn_cntr
generic map(
            COUNTR_WIDTH    => C_ERROR_PKT_CNTR_WIDTH
            )
  port map(
    --clk and reset
    i_reset                 => i_reset, 
    i_clk                   => i_clk,       
    
    --Counter Inputs
    i_cntr_en               => '1',
    i_cntr_tick             => s_cmd_pkt_reject_cnt_incr, 
    i_cntr_reset            => s_cmd_pkt_reject_cnt_clr,
         
    --Counter Outputs
    o_cntr_out              => s_cmd_pkt_reject_cnt,
    o_cntr_overflow         => open 
    );
    
    s_cmd_pkt_reject_cnt_incr   <=  '0';
	
                                                                                                                        
last_cmd_reject_latch: process(i_reset, i_clk)
begin
    if i_reset = '1' then
        s_last_cmd_reject_fc  <= x"FF";
    elsif rising_edge(i_clk) then
        if s_cmd_pkt_reject_cnt_incr = '1' then
            s_last_cmd_reject_fc  <= s_cmd_fun_code;
        end if;
    end if;
end process;

--Time elspes counter. counts milli-seconds starts on power up or on reset.
inst_elapse_time_cntr: entity work.cmn_cntr
generic map(
            COUNTR_WIDTH    => C_ELAPSE_TIME_CNTR_WIDTH
            )
  port map(
    --clk and reset
    i_reset                 => i_reset, 
    i_clk                   => i_clk,       
    
    --Counter Inputs
    i_cntr_en               => '1',
    i_cntr_tick             => i_strobe_1ms, 
    i_cntr_reset            => '0',  --this counter shall never be reset.
         
    --Counter Outputs
    o_cntr_out              => s_msec_elapse_time_cnt,
    o_cntr_overflow         => open 
    );
    
o_system_time_msec_cnt      <= s_msec_elapse_time_cnt;

--UART RX parity errors counter.
inst_urx_parity_err_cntr: entity work.cmn_cntr
generic map(
            COUNTR_WIDTH    => C_UART_RX_PARITY_ERR_CNTR_WIDTH
            )
  port map(
    --clk and reset
    i_reset                 => i_reset, 
    i_clk                   => i_clk,       
    
    --Counter Inputs
    i_cntr_en               => '1',
    i_cntr_tick             => i_urx_parity_err, 
    i_cntr_reset            => '0',  --this counter shall never be reset.
         
    --Counter Outputs
    o_cntr_out              => s_uart_rx_parity_err_cnt,
    o_cntr_overflow         => open 
    );

---------------------------------------------------------------------------------------
--Command interpretter/verifier 
---------------------------------------------------------------------------------------
 
cmd_fc_verify_proc: process(i_reset, i_clk)
begin
    if i_reset = '1' then
        s_cmd_fun_code_vld       <= '0';
        s_rd_reg_addr           <= (others => '0');
        s_wr_reg_addr           <= (others => '0');
        s_wr_reg_data           <= (others => '0');
        s_rw_enable             <= '0';
        s_cmd_enter_mode_idle    <= '0';
        s_cmd_op_state_vld      <= '0';
--        s_ddr_uart_read_req_ALL <= '0';
--        s_ddr_uart_read_req_CH1 <= '0';
--        s_ddr_uart_read_req_CH2 <= '0';
--        s_ddr_uart_read_req_CH3 <= '0';
--        s_ddr_uart_read_req_CH4 <= '0';
--        s_stop                  <= '0';

    elsif rising_edge(i_clk) then
    
        s_cmd_enter_mode_idle    <= '0';
        --s_cmd_enter_mode_imaging <= '0';
        --s_cmd_enter_mode_dcontam <= '0';
        --s_cmd_enter_mode_deploy  <= '0';
        --s_cmd_enter_mode_maint   <= '0';
        --s_cmd_enter_mode_dbg     <= '0';
        
        --s_mstr_rcvd_cmd_accept_incr <= '0';
        s_cmd_op_state_vld <= '0';
        

        case s_cmd_fun_code  is 
            when CMD_NO_OP => 
                s_cmd_fun_code_vld   <= '1';
                s_rw_enable         <= '0'; -- read enable when low else write
                
            when CMD_RD_REG => 
                s_cmd_fun_code_vld   <= '1';
                s_rw_enable         <= '0';
                s_max_wr_cmds_cnt   <=  0;
                --s_cmd_periph_id(0)  <= s_cmd_reg_addr(11 downto 8);
                s_rd_reg_addr       <= s_cmd_reg_addr;
                
            when CMD_WR_REG => 
                s_cmd_fun_code_vld    <= '1';
                s_rw_enable           <= '1';
                s_max_wr_cmds_cnt     <=  1;
                --s_cmd_periph_id(0)  <= s_cmd_reg_addr(11 downto 8);
                s_wr_reg_addr         <= s_cmd_reg_addr;
                s_wr_reg_data         <= s_cmd_reg_value;
--            when CMD_DDR4_DUMP_ALL => 
--                s_cmd_fun_code_vld      <= '1';
--                s_rw_enable             <= '1';
--                s_wr_reg_addr           <= s_cmd_reg_addr(5 downto 0);
--                s_wr_reg_data           <= s_cmd_reg_value(15 downto 0);
--                s_ddr_uart_read_req_ALL <= '1';
--                s_stop                  <= '1';    
                        
----                ctrl_reg_array(P_SWEPT_FPGA_DUMP_REQ_REG)(0) <= '1';
--            when CMD_DDR4_DUMP_CH1 =>
--                s_cmd_fun_code_vld      <= '1';
--                s_ddr_uart_read_req_CH1 <= '1';
--                s_stop                  <= '1';
--                ddr_read_addr_reg0      <=  ddr_if_reg_array(DDR_IF_CH1_READ_ADDR_REG0)(15 downto 0) ;
--                ddr_read_addr_reg1      <=  ddr_if_reg_array(DDR_IF_CH1_READ_ADDR_REG1)(15 downto 0) ;
--                ddr_read_length_reg0    <=  ddr_if_reg_array(DDR_IF_CH1_R_LENGTH_REG0)(15 downto 0) ;
--                ddr_read_length_reg1    <=  ddr_if_reg_array(DDR_IF_CH1_R_LENGTH_REG1)(15 downto 0) ;  
----                ctrl_reg_array(P_SWEPT_FPGA_DUMP_REQ_REG)(0) <= '1';
--            when CMD_DDR4_DUMP_CH2 =>
--                s_cmd_fun_code_vld      <= '1';
--                s_ddr_uart_read_req_CH2 <= '1';
--                s_stop                  <= '1';
--                ddr_read_addr_reg0      <=  ddr_if_reg_array(DDR_IF_CH2_READ_ADDR_REG0)(15 downto 0) ;
--                ddr_read_addr_reg1      <=  ddr_if_reg_array(DDR_IF_CH2_READ_ADDR_REG1)(15 downto 0) ;
--                ddr_read_length_reg0    <=  ddr_if_reg_array(DDR_IF_CH2_R_LENGTH_REG0)(15 downto 0) ;
--                ddr_read_length_reg1    <=  ddr_if_reg_array(DDR_IF_CH2_R_LENGTH_REG1)(15 downto 0) ;
   
----                ctrl_reg_array(P_SWEPT_FPGA_DUMP_REQ_REG)(0) <= '1';      
--            when CMD_DDR4_DUMP_CH3 =>
--                s_cmd_fun_code_vld   <= '1';
--                s_ddr_uart_read_req_CH3 <= '1';
--                s_stop                  <= '1';
--                ddr_read_addr_reg0      <=  ddr_if_reg_array(DDR_IF_CH3_READ_ADDR_REG0)(15 downto 0) ;
--                ddr_read_addr_reg1      <=  ddr_if_reg_array(DDR_IF_CH3_READ_ADDR_REG1)(15 downto 0) ;
--                ddr_read_length_reg0    <=  ddr_if_reg_array(DDR_IF_CH3_R_LENGTH_REG0)(15 downto 0) ;
--                ddr_read_length_reg1    <=  ddr_if_reg_array(DDR_IF_CH3_R_LENGTH_REG1)(15 downto 0) ;    

--            when CMD_DDR4_DUMP_CH4 =>

--                s_cmd_fun_code_vld   <= '1';
--                s_ddr_uart_read_req_CH4 <= '1';
--                s_stop                  <= '1';
--                ddr_read_addr_reg0      <=  ddr_if_reg_array(DDR_IF_CH4_READ_ADDR_REG0)(15 downto 0);
--                ddr_read_addr_reg1      <=  ddr_if_reg_array(DDR_IF_CH4_READ_ADDR_REG1)(15 downto 0);
--                ddr_read_length_reg0    <=  ddr_if_reg_array(DDR_IF_CH4_R_LENGTH_REG0)(15 downto 0);
--                ddr_read_length_reg1    <=  ddr_if_reg_array(DDR_IF_CH4_R_LENGTH_REG1)(15 downto 0);  

            when others => 
--            if (ddr4_rd_data_last_word_s2 = '1') then
--                s_stop                  <= '0';
--                s_cmd_fun_code_vld      <= '0'; 
--                s_ddr_uart_read_req_ALL <= '0';               
--                s_ddr_uart_read_req_CH1 <= '0';
--                s_ddr_uart_read_req_CH2 <= '0';
--                s_ddr_uart_read_req_CH3 <= '0';
--                s_ddr_uart_read_req_CH4 <= '0';
--            end if;
        end case;
    end if;
end process;

--last_word_dbr: process(i_reset, i_clk)
--begin
--if i_reset ='1' then
    --ddr4_rd_data_last_word_s     <= '0';
    --ddr4_rd_data_last_word_s1     <= '0';
    --ddr4_rd_data_last_word_s2  <= '0';
--
    --elsif rising_edge(i_clk) then
        --ddr4_rd_data_last_word_s   <= i_ddr4_rd_data_last_word;
        --ddr4_rd_data_last_word_s1  <= ddr4_rd_data_last_word_s;
	    --ddr4_rd_data_last_word_s2 <= ddr4_rd_data_last_word_s1; 
----	    if((ddr4_rd_data_last_word_s2 and not ddr4_rd_data_last_word_s1)='1') then
----	       ddr4_rd_data_last_word_ris <= '1';
----	    end if;
--end if;
--end process;
--s_stop		<= ctrl_reg_array(P_SWEPT_CMD_STOP_CTRL_REG)(0);
--stop_req_gen: process(i_reset, i_clk)
--begin
--if i_reset ='1' then
--    o_stop_req <= '0';
--    elsif rising_edge(i_clk) then
--	    if (s_stop = '1' and ddr4_rd_data_last_word_ris = '0') then
--		o_stop_req <= '1';
--		else
--		o_stop_req <= '0';
--		end if;
--end if;
--end process;

--------------------------------------------------------------------------------
-- Response Packet generator.
-- resposds to commands requirign resonses such as reading resiger
--------------------------------------------------------------------------------
tsmt_uart: process (i_reset, i_clk)
begin
    if i_reset = '1' then
        s_rd_reg_reponse      <= '0';
        s_uart_tx_byte        <= x"00";
        s_uart_tx_dv          <= '0';
        s_tx_crc_init         <= '0';
        sm_uart_tx_state      <= ST_RESP_IDLE;
        dbg_tx_state          <= x"00";
        s_crc_calc_enable     <= '0';

        
    elsif rising_edge(i_clk) then
    
        s_uart_tx_dv    	<= '0';
--		s_mem_dump		<= ctrl_reg_array(P_SWEPT_FPGA_DUMP_REQ_REG)(0);
--      s_mem_dump_d1	<= s_mem_dump;
--		s_mem_dump_req 	<= (not s_mem_dump_d1) and  s_mem_dump;
		
        case sm_uart_tx_state is
        
            when ST_RESP_IDLE =>
                dbg_tx_state    <= x"01";
                s_rd_reg_reponse        <= '0';
                s_uart_tx_dv            <= '0';
                s_tx_crc_init           <= '1';
                
                if s_reg_read_valid = '1' then --and s_int_response = '0' then
                    s_rd_reg_reponse    <= '1';
                    s_tx_crc_init       <= '0';
                    s_crc_calc_enable   <= '1';
                    sm_uart_tx_state    <= ST_RESP_HEADER; --ST_RESP_CHECK;
--				elsif s_ddr_uart_read_req_ALL = '1' or s_ddr_uart_read_req_CH1 = '1' or s_ddr_uart_read_req_CH2 = '1'or s_ddr_uart_read_req_CH3 = '1' or s_ddr_uart_read_req_CH4 = '1'  then
--					sm_uart_tx_state	<= ST_MEM_RD_DATA_TNSMIT; 
                end if;
            
            when ST_RESP_CHECK =>
                dbg_tx_state    <= x"02";
                if s_cmd_rdy_clr = '1' then --cmd_rdy_clr follows dout_valid right after...
                    sm_uart_tx_state <= ST_RESP_HEADER;
                else
                    sm_uart_tx_state <= ST_RESP_IDLE;
                end if;
                
            when ST_RESP_HEADER =>
                dbg_tx_state    <= x"03";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte <= x"6E";
                    s_uart_tx_dv <= '1';
                    sm_uart_tx_state <= ST_RESP_FUN_CODE;
                end if;
        
            when ST_RESP_FUN_CODE =>
                dbg_tx_state    <= x"04";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte      <= s_cmd_fun_code(7 downto 0);
                    s_uart_tx_dv        <= '1';
                    sm_uart_tx_state    <= ST_RESP_ADDR_B1;
                end if;
        
            when ST_RESP_ADDR_B1 =>
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte <= s_cmd_reg_addr(15 downto 8);
                    s_uart_tx_dv        <= '1';
                    s_rd_reg_reponse    <= '0';
                    sm_uart_tx_state    <= ST_RESP_ADDR_B0;
                end if;
                
            when ST_RESP_ADDR_B0 =>
                dbg_tx_state    <= x"05";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte <= s_cmd_reg_addr(7 downto 0);
                    s_uart_tx_dv        <= '1';
                    s_rd_reg_reponse    <= '0';
                    sm_uart_tx_state    <= ST_RESP_PARAM_B3;
                end if;
                
            when ST_RESP_PARAM_B3 =>
                dbg_tx_state    <= x"06";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte      <= s_resp_reg_value(31 downto 24);  --s_resp_reg_value(15 downto 8);
                    s_uart_tx_dv        <= '1';
                    sm_uart_tx_state    <= ST_RESP_PARAM_B2;
                end if;
        
            when ST_RESP_PARAM_B2 =>
                dbg_tx_state    <= x"06";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte      <= s_resp_reg_value(23 downto 16); --s_resp_reg_value(7 downto 0);
                    s_uart_tx_dv        <= '1';
                    sm_uart_tx_state    <= ST_RESP_PARAM_B1;
                end if;
                
            when ST_RESP_PARAM_B1 =>
                dbg_tx_state    <= x"07";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte      <= s_resp_reg_value(15 downto 8);
                    s_uart_tx_dv        <= '1';
                    sm_uart_tx_state    <= ST_RESP_PARAM_B0;
                end if;
                
            when ST_RESP_PARAM_B0 =>
                dbg_tx_state    <= x"08";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte      <= s_resp_reg_value(7 downto 0);
                    s_uart_tx_dv        <= '1';
                    s_crc_calc_enable   <= '0';
                    sm_uart_tx_state <= ST_RESP_TRAILER_B1;
                end if;
                
            when ST_RESP_TRAILER_B1 =>
                dbg_tx_state    <= x"09";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte      <= s_tx_crc_gen(15 downto 8);
                    s_tx_crc_gen_old    <= s_tx_crc_gen;
                    s_uart_tx_dv        <= '1';
                    sm_uart_tx_state    <= ST_RESP_TRAILER_B0;
                end if;
                
            when ST_RESP_TRAILER_B0 =>
                dbg_tx_state    <= x"0A";
                if i_uart_tx_fifo_full = '0' then
                    s_uart_tx_byte  <= s_tx_crc_gen_old(7 downto 0);
                    s_uart_tx_dv    <= '1';
                    sm_uart_tx_state <= ST_RESP_IDLE;
                end if;
                
            when others =>
                sm_uart_tx_state <= ST_RESP_IDLE;
                
        end case;
        
    end if;
end process;




inst_tx_crc_gen: entity work.crc16_gen 
  port map( 
    i_clk                        => i_clk,
    i_reset                      => i_reset,
    
    i_crc_init                   => s_tx_crc_init,
    
    i_8bit_data_in               => s_8bit_data_in,     
    i_8bit_data_in_vld           => s_8bit_data_in_vld, 
    
    i_ref_crc_en                  => '0',
    i_ref_crc_in                  => (others => '1'),        
    
    o_crc_data_out                => s_tx_crc_gen,    
    o_crc_data_out_vld            => open --s_tx_crc_data_out_vld 
    );
    
 s_8bit_data_in         <= s_uart_tx_byte;
 s_8bit_data_in_vld     <= s_uart_tx_dv and s_crc_calc_enable;
--------------------------------------------------------------------------------
--degbug signals

o_dbg_port(15 downto 14)<= (others => '0');
o_dbg_port(13 downto 9) <= dbg_rcv_state(4 downto 0);
o_dbg_port(8)           <= i_uart_rx_dv;
o_dbg_port(7 downto 4)  <= dbg_tx_state(3 downto 0);
o_dbg_port(3 downto 0)  <= dbg_mstr_state(3 downto 0); --i_uart_rx_byte;
 
--------------------------------------------------------------------------------
end rtl;
